from django.contrib import admin

from .models import (
    AIConsultation, Alert, CareSchedule, Expense, FeedingRecord,
    HealthReport, Hog, HogMedicine, InventoryItem, Medicine, ReferenceArticle, WeightRecord,
)


@admin.register(Hog)
class HogAdmin(admin.ModelAdmin):
    list_display = ('code', 'owner', 'breed', 'stage', 'status', 'current_weight_kg', 'birth_date')
    list_filter = ('stage', 'status', 'breed')
    search_fields = ('code', 'name', 'owner__username')


@admin.register(WeightRecord)
class WeightAdmin(admin.ModelAdmin):
    list_display = ('hog', 'date', 'weight_kg')
    list_filter = ('date',)


@admin.register(FeedingRecord)
class FeedingAdmin(admin.ModelAdmin):
    list_display = ('hog', 'feed_category', 'amount_kg_per_day', 'feeding_date')


@admin.register(CareSchedule)
class CareAdmin(admin.ModelAdmin):
    list_display = ('title', 'owner', 'hog', 'care_type', 'due_date', 'completed')
    list_filter = ('care_type', 'completed')


@admin.register(HealthReport)
class HealthAdmin(admin.ModelAdmin):
    list_display = ('hog', 'urgency', 'appetite', 'status', 'vet_referral', 'created_at')
    list_filter = ('urgency', 'status', 'vet_referral')


@admin.register(Medicine)
class MedicineAdmin(admin.ModelAdmin):
    list_display = ('name', 'active_ingredient', 'withdrawal_days', 'prescription_required')
    search_fields = ('name', 'active_ingredient', 'intended_use')


@admin.register(InventoryItem)
class InventoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'owner', 'category', 'quantity', 'unit', 'expiry_date')
    list_filter = ('category',)


@admin.register(Expense)
class ExpenseAdmin(admin.ModelAdmin):
    list_display = ('owner', 'hog', 'category', 'amount', 'expense_date')
    list_filter = ('category',)


@admin.register(Alert)
class AlertAdmin(admin.ModelAdmin):
    list_display = ('title', 'owner', 'hog', 'alert_type', 'severity', 'is_read', 'is_resolved', 'created_at')
    list_filter = ('alert_type', 'severity', 'is_read', 'is_resolved')


@admin.register(ReferenceArticle)
class ReferenceAdmin(admin.ModelAdmin):
    list_display = ('title', 'category', 'updated_at')
    list_filter = ('category',)
    search_fields = ('title', 'content')


@admin.register(AIConsultation)
class AIChatAdmin(admin.ModelAdmin):
    list_display = ('owner', 'hog', 'created_at')


@admin.register(HogMedicine)
class HogMedicineAdmin(admin.ModelAdmin):
    list_display = ('hog', 'medicine', 'administered_date', 'route', 'dosage', 'withdrawal_until')
    list_filter = ('route', 'administered_date')
