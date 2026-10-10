"""AI Automation Engine — the capstone centerpiece.

Step 1 collect: age/weight/feeding/appetite/symptoms/meds/schedules.
Step 2 detect:  rules (+AI triage already stored on HealthReport).
Step 3 guide:   message + recommended action (+ vet referral).
Step 4 persist: Alert rows so dashboards & reports can show them.

Idempotent: skips creating near-duplicate open alerts (same owner/hog/type
within 3 days) so repeated runs don't spam.
"""

from datetime import timedelta

from django.db.models import Count
from django.utils import timezone

from .models import Alert, AlertSeverity, AlertType


def _recent_duplicate(owner, hog, alert_type, days=3):
    since = timezone.now() - timedelta(days=days)
    qs = Alert.objects.filter(owner=owner, alert_type=alert_type,
                              is_resolved=False, created_at__gte=since)
    qs = qs.filter(hog=hog) if hog else qs.filter(hog__isnull=True)
    return qs.exists()


def _create(owner, hog, alert_type, title, message, action='', severity=AlertSeverity.WARNING):
    if _recent_duplicate(owner, hog, alert_type):
        return None
    return Alert.objects.create(
        owner=owner, hog=hog, alert_type=alert_type, title=title,
        message=message, recommended_action=action, severity=severity,
    )


def run_automation_for_owner(owner):
    """Evaluate all farm data for one owner. Returns list of new Alerts."""
    from .models import CareSchedule, Expense, FeedingRecord, HealthReport, Hog, HogStatus, InventoryItem

    created = []
    today = timezone.localdate()

    hogs = Hog.objects.filter(owner=owner).exclude(status__in=['sold', 'deceased'])
    # -- 1. growth / market readiness -----------------------------------
    for hog in hogs:
        status = hog.growth_status()
        if status == 'slow':
            a = _create(owner, hog, AlertType.GROWTH_SLOW,
                        f'Slow growth: {hog.display_name}',
                        f'ADG is {hog.average_daily_gain()} kg/day (below 0.40 target). '
                        f'Weight {hog.current_weight_kg}kg vs target {hog.target_weight_kg}kg.',
                        'Review feeding plan & health history; check parasites/feed quality; weigh weekly.',
                        AlertSeverity.WARNING)
            if a:
                created.append(a)
        elif status == 'losing':
            a = _create(owner, hog, AlertType.GROWTH_SLOW,
                        f'Weight loss: {hog.display_name}',
                        'Latest weight is lower than earlier records.',
                        'Check feed intake, water, illness; quarantine if other symptoms; call vet.',
                        AlertSeverity.CRITICAL)
            if a:
                created.append(a)
        try:
            if hog.current_weight_kg and float(hog.current_weight_kg) >= float(hog.target_weight_kg or 100):
                a = _create(owner, hog, AlertType.MARKET_READY,
                            f'Market ready: {hog.display_name}',
                            f'Reached {hog.current_weight_kg}kg (target {hog.target_weight_kg}kg).',
                            'Schedule selling; stop supplements per withdrawal guidance.',
                            AlertSeverity.INFO)
                if a:
                    created.append(a)
        except (TypeError, ValueError):
            pass

        # -- 2. missed feeding records ----------------------------------
        last_feed = FeedingRecord.objects.filter(hog=hog).order_by('-feeding_date').first()
        if not last_feed or (today - last_feed.feeding_date).days >= 2:
            a = _create(owner, hog, AlertType.MISSED_FEEDING,
                        f'Missing feeding record: {hog.display_name}',
                        'No feeding record in the last 2 days.' if last_feed else 'No feeding record yet.',
                        'Record daily feed type + kg; automation uses this for growth analysis.',
                        AlertSeverity.INFO)
            if a:
                created.append(a)

    # -- 3. care due / overdue -------------------------------------------
    due_soon = CareSchedule.objects.filter(owner=owner, completed=False,
                                           due_date__lte=today + timedelta(days=3))
    for task in due_soon[:50]:
        overdue = task.due_date < today
        a = _create(owner, task.hog, AlertType.CARE_DUE,
                    f"{'Overdue' if overdue else 'Due soon'}: {task.title}",
                    f"{task.get_care_type_display()} scheduled {task.due_date}"
                    + (f' for {task.hog.display_name}.' if task.hog else ' (whole farm).'),
                    'Complete the task and mark it done; reschedule if needed.',
                    AlertSeverity.WARNING if overdue else AlertSeverity.INFO)
        if a:
            created.append(a)

    # -- 4. inventory: low stock & expiry --------------------------------
    for item in InventoryItem.objects.filter(owner=owner):
        if item.is_low:
            a = _create(owner, None, AlertType.LOW_STOCK,
                        f'Low stock: {item.name}',
                        f'{item.quantity}{item.unit} left (threshold {item.low_stock_threshold}{item.unit}).',
                        'Reorder soon to avoid missed feeding/medication.',
                        AlertSeverity.WARNING)
            if a:
                created.append(a)
        days = item.days_to_expiry()
        if days is not None and 0 <= days <= 30:
            a = _create(owner, None, AlertType.EXPIRING_SOON,
                        f'Expiring soon: {item.name}',
                        f'Expires in {days} day(s) ({item.expiry_date}).',
                        'Use first / replace; never use expired medicine.',
                        AlertSeverity.WARNING)
            if a:
                created.append(a)

    # -- 5. health concerns from recent reports ---------------------------
    recent = HealthReport.objects.filter(
        hog__owner=owner, status__in=['open', 'monitoring'],
        created_at__gte=timezone.now() - timedelta(days=7))
    for rep in recent[:50]:
        if rep.urgency == 'urgent':
            a = _create(owner, rep.hog, AlertType.HEALTH_CONCERN,
                        f'Urgent health case: {rep.hog.display_name}',
                        f'{rep.symptoms[:200]} (appetite: {rep.get_appetite_display()}).',
                        rep.recommended_steps[:500] or 'Quarantine and call the veterinarian immediately.',
                        AlertSeverity.CRITICAL)
            if a:
                created.append(a)

    # -- 6. outbreak heuristic: >=3 open cases / 7 days -------------------
    cluster = (recent.order_by().values('hog__owner')
               .annotate(n=Count('id')).filter(n__gte=3).order_by('-n').first())
    if cluster:
        a = _create(owner, None, AlertType.OUTBREAK_WARNING,
                    'Possible disease cluster detected',
                    f'{cluster["n"]} open health reports in the last 7 days.',
                    'Enforce biosecurity: quarantine, disinfect, limit visitors, call municipal vet.',
                    AlertSeverity.CRITICAL)
        if a:
            created.append(a)

    return created


def run_automation_for_hog(hog):
    return run_automation_for_owner(hog.owner)
