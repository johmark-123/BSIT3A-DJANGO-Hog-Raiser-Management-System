"""Hog Raiser Management System data model.

Covers: hog life-cycle, weights/growth, feeding & care schedules,
health reports, verified medicine library, inventory, expenses,
automated alerts/tasks, reference knowledge base, AI chat log.
"""

from datetime import date
from decimal import Decimal

from django.conf import settings
from django.db import models
from django.utils import timezone


# ---------------------------------------------------------------- choices
class HogStage(models.TextChoices):
    PIGLET = 'piglet', 'Piglet (0-8 wks)'
    WEANER = 'weaner', 'Weaner (8-12 wks)'
    GROWER = 'grower', 'Grower (12-20 wks)'
    FINISHER = 'finisher', 'Finisher (20-26 wks)'
    GILT = 'gilt', 'Gilt'
    SOW = 'sow', 'Sow'
    BOAR = 'boar', 'Boar'
    MARKET_READY = 'market_ready', 'Market Ready'


class HogStatus(models.TextChoices):
    ACTIVE = 'active', 'Active'
    QUARANTINED = 'quarantined', 'Quarantined'
    SOLD = 'sold', 'Sold'
    DECEASED = 'deceased', 'Deceased'


class HogSex(models.TextChoices):
    MALE = 'male', 'Male'
    FEMALE = 'female', 'Female'


class Urgency(models.TextChoices):
    ROUTINE = 'routine', 'Routine'
    NEEDS_ATTENTION = 'needs_attention', 'Needs Attention'
    URGENT = 'urgent', 'Urgent'


class AlertSeverity(models.TextChoices):
    INFO = 'info', 'Info'
    WARNING = 'warning', 'Warning'
    CRITICAL = 'critical', 'Critical'


class AlertType(models.TextChoices):
    GROWTH_SLOW = 'growth_slow', 'Slow Growth'
    LOW_STOCK = 'low_stock', 'Low Stock'
    EXPIRING_SOON = 'expiring_soon', 'Expiring Soon'
    MISSED_FEEDING = 'missed_feeding', 'Missed Feeding Record'
    HEALTH_CONCERN = 'health_concern', 'Health Concern'
    CARE_DUE = 'care_due', 'Care Due / Overdue'
    OUTBREAK_WARNING = 'outbreak_warning', 'Possible Outbreak'
    MARKET_READY = 'market_ready', 'Market Ready'
    INFO = 'info', 'General Info'


# ---------------------------------------------------------------- models
class Hog(models.Model):
    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL, related_name='hogs',
        on_delete=models.CASCADE,
    )
    code = models.CharField(max_length=50, help_text='Ear tag / QR code value')
    name = models.CharField(max_length=100, blank=True)
    breed = models.CharField(max_length=100, default='Crossbred')
    sex = models.CharField(max_length=10, choices=HogSex.choices, default=HogSex.FEMALE)
    birth_date = models.DateField(default=timezone.now)
    stage = models.CharField(max_length=20, choices=HogStage.choices, default=HogStage.PIGLET)
    status = models.CharField(max_length=20, choices=HogStatus.choices, default=HogStatus.ACTIVE)
    current_weight_kg = models.DecimalField(max_digits=7, decimal_places=2, null=True, blank=True)
    target_weight_kg = models.DecimalField(max_digits=7, decimal_places=2, default=Decimal('100.00'))
    purchase_cost = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    sale_price = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'farm_hog'
        ordering = ['code']
        unique_together = ('owner', 'code')

    def __str__(self):
        return f'{self.code} ({self.get_stage_display()})'

    # -- derived helpers -------------------------------------------------
    @property
    def display_name(self):
        return self.name or self.code

    def age_days(self, on_date=None):
        on_date = on_date or timezone.localdate()
        try:
            return max(0, (on_date - self.birth_date).days)
        except TypeError:
            return 0

    def age_weeks(self):
        return round(self.age_days() / 7, 1)

    def auto_stage(self):
        """Suggest stage from age when stage not manually locked to breeder."""
        if self.stage in (HogStage.SOW, HogStage.BOAR, HogStage.GILT):
            return self.stage
        weeks = self.age_weeks()
        if self.current_weight_kg and float(self.current_weight_kg) >= float(self.target_weight_kg or 100):
            return HogStage.MARKET_READY
        if weeks < 8:
            return HogStage.PIGLET
        if weeks < 12:
            return HogStage.WEANER
        if weeks < 20:
            return HogStage.GROWER
        return HogStage.FINISHER

    def weight_history(self):
        return self.weights.order_by('date', 'id')

    def average_daily_gain(self):
        """(last - first) / days. None when fewer than 2 records."""
        qs = list(self.weight_history().values_list('date', 'weight_kg'))
        if len(qs) < 2:
            return None
        (d0, w0), (d1, w1) = qs[0], qs[-1]
        days = (d1 - d0).days
        if days <= 0:
            return None
        return round((float(w1) - float(w0)) / days, 3)

    def predicted_market_date(self):
        """Estimate date target weight is reached using ADG. None if unknown."""
        if self.current_weight_kg and float(self.current_weight_kg) >= float(self.target_weight_kg or 100):
            return timezone.localdate()
        adg = self.average_daily_gain()
        if not adg or adg <= 0 or not self.current_weight_kg:
            return None
        remaining = float(self.target_weight_kg or 100) - float(self.current_weight_kg)
        if remaining <= 0:
            return timezone.localdate()
        from datetime import timedelta
        return timezone.localdate() + timedelta(days=int(remaining / adg))

    def growth_status(self):
        """Compare ADG against farm target (~0.65 kg/day grower-finisher)."""
        adg = self.average_daily_gain()
        if adg is None:
            return 'unknown'
        if adg < 0:
            return 'losing'
        if adg < 0.4:
            return 'slow'
        if adg < 0.65:
            return 'fair'
        return 'good'

    def total_expenses(self):
        from django.db.models import Sum
        total = self.expenses.aggregate(s=Sum('amount'))['s'] or Decimal('0.00')
        return total + (self.purchase_cost or Decimal('0.00'))

    def estimated_profit(self, price_per_kg=None):
        """Profit = sale_or_estimated_value - total costs."""
        weight = float(self.current_weight_kg or 0)
        if self.sale_price:
            revenue = float(self.sale_price)
        elif price_per_kg:
            revenue = weight * float(price_per_kg)
        else:
            revenue = 0.0
        return round(revenue - float(self.total_expenses()), 2)


class WeightRecord(models.Model):
    hog = models.ForeignKey(Hog, related_name='weights', on_delete=models.CASCADE)
    date = models.DateField(default=timezone.localdate)
    weight_kg = models.DecimalField(max_digits=7, decimal_places=2)
    notes = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'farm_weight'
        ordering = ['-date', '-id']

    def __str__(self):
        return f'{self.hog.code} {self.weight_kg}kg @ {self.date}'

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        # keep hog.current_weight in sync with latest record
        latest = self.hog.weights.order_by('-date', '-id').first()
        if latest:
            Hog.objects.filter(pk=self.hog_id).update(current_weight_kg=latest.weight_kg)


class FeedingRecord(models.Model):
    FEED_CHOICES = [
        ('pre_starter', 'Pre-starter'),
        ('starter', 'Starter'),
        ('grower', 'Grower'),
        ('finisher', 'Finisher'),
        ('gestating', 'Gestating'),
        ('lactating', 'Lactating'),
        ('boar', 'Boar'),
        ('supplement', 'Supplement / Vitamins'),
    ]
    hog = models.ForeignKey(Hog, related_name='feedings', on_delete=models.CASCADE)
    feed_category = models.CharField(max_length=20, choices=FEED_CHOICES, default='grower')
    feed_name = models.CharField(max_length=120, blank=True)
    amount_kg_per_day = models.DecimalField(max_digits=6, decimal_places=2, default=Decimal('1.50'))
    feeding_date = models.DateField(default=timezone.localdate)
    notes = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'farm_feeding'
        ordering = ['-feeding_date', '-id']


class CareSchedule(models.Model):
    CARE_CHOICES = [
        ('feeding', 'Feeding'),
        ('vitamin', 'Vitamin supplementation'),
        ('vaccine', 'Vaccination'),
        ('deworming', 'Deworming'),
        ('checkup', 'Health checkup'),
        ('breeding', 'Breeding'),
        ('farrowing', 'Farrowing'),
        ('other', 'Other'),
    ]
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, related_name='care_tasks', on_delete=models.CASCADE)
    hog = models.ForeignKey(Hog, related_name='care_schedules', on_delete=models.CASCADE, null=True, blank=True)
    care_type = models.CharField(max_length=20, choices=CARE_CHOICES, default='checkup')
    title = models.CharField(max_length=150)
    due_date = models.DateField()
    completed = models.BooleanField(default=False)
    completed_at = models.DateTimeField(null=True, blank=True)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'farm_care'
        ordering = ['due_date']

    def __str__(self):
        return f'{self.title} due {self.due_date}'


class HealthReport(models.Model):
    APPETITE = [('normal', 'Normal'), ('reduced', 'Reduced'), ('loss', 'Loss of appetite'), ('increased', 'Increased')]
    STATUS = [('open', 'Open'), ('monitoring', 'Monitoring'), ('referred', 'Referred to vet'), ('resolved', 'Resolved')]

    hog = models.ForeignKey(Hog, related_name='health_reports', on_delete=models.CASCADE)
    reported_by = models.ForeignKey(settings.AUTH_USER_MODEL, related_name='health_reports', on_delete=models.CASCADE)
    symptoms = models.TextField(help_text='Reported symptoms, one per line if many')
    appetite = models.CharField(max_length=20, choices=APPETITE, default='normal')
    behavior = models.TextField(blank=True)
    duration_days = models.PositiveIntegerField(default=1)
    affected_count = models.PositiveIntegerField(default=1)
    urgency = models.CharField(max_length=20, choices=Urgency.choices, default=Urgency.ROUTINE)
    ai_summary = models.TextField(blank=True)
    possible_causes = models.TextField(blank=True)
    recommended_steps = models.TextField(blank=True)
    vet_referral = models.BooleanField(default=False)
    status = models.CharField(max_length=20, choices=STATUS, default='open')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'farm_health'
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.hog.code}: {self.get_urgency_display()} ({self.created_at:%Y-%m-%d})'


class Medicine(models.Model):
    name = models.CharField(max_length=150, unique=True)
    active_ingredient = models.CharField(max_length=200, blank=True)
    intended_use = models.TextField()
    dosage_info = models.TextField(blank=True, help_text='General label info only; vet confirms dosage.')
    precautions = models.TextField(blank=True)
    withdrawal_days = models.PositiveIntegerField(default=0, help_text='Withdrawal period before slaughter.')
    prescription_required = models.BooleanField(default=False)
    interactions = models.TextField(blank=True)
    reference_source = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'farm_medicine'
        ordering = ['name']

    def __str__(self):
        return self.name


class InventoryItem(models.Model):
    CATEGORY = [('feed', 'Feed'), ('vitamin', 'Vitamins'), ('medicine', 'Medicine'),
                ('equipment', 'Equipment'), ('other', 'Other')]
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, related_name='inventory', on_delete=models.CASCADE)
    name = models.CharField(max_length=150)
    category = models.CharField(max_length=20, choices=CATEGORY, default='feed')
    quantity = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    unit = models.CharField(max_length=30, default='kg')
    low_stock_threshold = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('5.00'))
    expiry_date = models.DateField(null=True, blank=True)
    unit_cost = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'farm_inventory'
        ordering = ['name']

    def __str__(self):
        return f'{self.name} ({self.quantity}{self.unit})'

    @property
    def is_low(self):
        return self.quantity <= self.low_stock_threshold

    def days_to_expiry(self):
        if not self.expiry_date:
            return None
        return (self.expiry_date - timezone.localdate()).days


class Expense(models.Model):
    CATEGORY = [('feed', 'Feed'), ('vitamin', 'Vitamins'), ('medicine', 'Medicine'),
                ('labor', 'Labor'), ('equipment', 'Equipment'), ('utilities', 'Utilities'),
                ('veterinary', 'Veterinary'), ('other', 'Other')]
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, related_name='expenses', on_delete=models.CASCADE)
    hog = models.ForeignKey(Hog, related_name='expenses', on_delete=models.CASCADE, null=True, blank=True)
    category = models.CharField(max_length=20, choices=CATEGORY, default='feed')
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    expense_date = models.DateField(default=timezone.localdate)
    description = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'farm_expense'
        ordering = ['-expense_date', '-id']


class Alert(models.Model):
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, related_name='farm_alerts', on_delete=models.CASCADE)
    hog = models.ForeignKey(Hog, related_name='alerts', on_delete=models.CASCADE, null=True, blank=True)
    alert_type = models.CharField(max_length=30, choices=AlertType.choices, default=AlertType.INFO)
    title = models.CharField(max_length=200)
    message = models.TextField()
    recommended_action = models.TextField(blank=True)
    severity = models.CharField(max_length=20, choices=AlertSeverity.choices, default=AlertSeverity.INFO)
    is_read = models.BooleanField(default=False)
    is_resolved = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'farm_alert'
        ordering = ['-created_at']

    def __str__(self):
        return f'[{self.get_severity_display()}] {self.title}'


class ReferenceArticle(models.Model):
    CATEGORY = [('feeding', 'Feeding & Nutrition'), ('health', 'Health & Biosecurity'),
                ('breeding', 'Breeding & Farrowing'), ('management', 'Farm Management'),
                ('general', 'General')]
    title = models.CharField(max_length=200)
    category = models.CharField(max_length=20, choices=CATEGORY, default='general')
    content = models.TextField()
    source = models.CharField(max_length=255, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'farm_reference'
        ordering = ['category', 'title']

    def __str__(self):
        return self.title


class AIConsultation(models.Model):
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, related_name='ai_chats', on_delete=models.CASCADE)
    hog = models.ForeignKey(Hog, related_name='ai_chats', on_delete=models.SET_NULL, null=True, blank=True)
    question = models.TextField()
    answer = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'farm_ai_chat'
        ordering = ['-created_at']


class HogMedicine(models.Model):
    ROUTE_CHOICES = [
        ('oral', 'Oral'),
        ('injection', 'Injection'),
        ('topical', 'Topical'),
        ('other', 'Other'),
    ]
    hog = models.ForeignKey(Hog, related_name='hog_medicines', on_delete=models.CASCADE)
    medicine = models.ForeignKey(Medicine, related_name='hog_links', on_delete=models.CASCADE)
    health_report = models.ForeignKey(
        HealthReport, related_name='medicine_links', on_delete=models.SET_NULL,
        null=True, blank=True,
    )
    administered_date = models.DateField(default=timezone.localdate)
    dosage = models.CharField(max_length=120, blank=True)
    route = models.CharField(max_length=20, choices=ROUTE_CHOICES, default='oral')
    notes = models.TextField(blank=True)
    administered_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, related_name='hog_medicine_links',
        on_delete=models.SET_NULL, null=True, blank=True,
    )
    withdrawal_until = models.DateField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'farm_hog_medicine'
        ordering = ['-administered_date', '-id']

    def __str__(self):
        return f'{self.hog.code} - {self.medicine.name}'

    def save(self, *args, **kwargs):
        if not self.withdrawal_until and self.medicine and self.medicine.withdrawal_days:
            from datetime import timedelta
            self.withdrawal_until = self.administered_date + timedelta(days=self.medicine.withdrawal_days)
        super().save(*args, **kwargs)
