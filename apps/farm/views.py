"""Views for AI-Powered Hog Raiser Management System (Django-native).

Public-customer mode: all customer farm pages are OPEN (no login).
Only admin overview + medicine library management require superuser login.
Shared-farm model: public visitors see the same shared records; writes by
anonymous visitors are attributed to a shared 'public-farm' owner account.
"""

from datetime import timedelta
from decimal import Decimal, InvalidOperation

from django.contrib import messages
from django.contrib.auth import get_user_model
from django.contrib.auth.decorators import login_required, user_passes_test
from django.core.paginator import Paginator
from django.db.models import Count, Q, Sum
from django.http import JsonResponse
from django.shortcuts import get_object_or_404, render
from django.utils import timezone
from django.views.decorators.http import require_POST

from . import ai_service
from .automation import run_automation_for_owner
from .feeding import suggest_feeding
from .models import (
    AIConsultation, Alert, CareSchedule, Expense, FeedingRecord,
    HealthReport, Hog, InventoryItem, Medicine, ReferenceArticle, WeightRecord,
)

User = get_user_model()
PUBLIC_USERNAME = 'public-farm'


def _is_admin(user):
    return getattr(user, 'is_authenticated', False) and user.is_superuser


def _public_owner():
    """Shared owner account for anonymous (public) visitors. Created lazily."""
    owner, _ = User.objects.get_or_create(
        username=PUBLIC_USERNAME,
        defaults={'first_name': 'Public', 'last_name': 'Farm', 'is_active': True},
    )
    return owner


def _effective_owner(request):
    """Attribution for new records: logged-in user, else shared public account."""
    if getattr(request.user, 'is_authenticated', False):
        return request.user
    return _public_owner()


def _is_public_request(request):
    return not getattr(request.user, 'is_authenticated', False)


# ------------------------------------------------------------ scoping (shared farm)
def scoped_hogs(user):
    """Public mode: everyone (customer logged-in or anonymous) sees shared hogs."""
    return Hog.objects.all()


def get_hog(user, pk):
    return get_object_or_404(Hog.objects.all(), pk=pk)


def _base_qs(model, request, owner_field='owner'):
    """Shared records for public; admins also see everything (same here)."""
    return model.objects.all()


def _to_decimal(raw, default=None):
    try:
        return Decimal(str(raw))
    except (InvalidOperation, TypeError, ValueError):
        return default


# ------------------------------------------------------------ dashboards
def dashboard(request):
    """Public landing for visitors (NO login); operations dashboard for logged-in users."""
    if _is_admin(request.user):
        return admin_overview(request)
    if _is_public_request(request):
        hogs = Hog.objects.exclude(status__in=['sold', 'deceased'])
        market = [h for h in hogs
                  if h.current_weight_kg and float(h.current_weight_kg) >= float(h.target_weight_kg or 100)]
        month_start = timezone.localdate().replace(day=1)
        month_exp = Expense.objects.filter(expense_date__gte=month_start).aggregate(
            s=Sum('amount'))['s'] or Decimal('0.00')
        return render(request, 'farm/landing.html', {
            'hog_count': hogs.count(),
            'market_hogs': market,
            'unread': Alert.objects.filter(is_resolved=False, is_read=False).count(),
            'month_expenses': month_exp,
        })
    hogs = Hog.objects.exclude(status__in=['sold', 'deceased'])
    alerts = Alert.objects.filter(is_resolved=False).order_by('-created_at')[:8]
    unread = Alert.objects.filter(is_resolved=False, is_read=False).count()
    due_care = CareSchedule.objects.filter(
        completed=False, due_date__lte=timezone.localdate() + timedelta(days=7)
    ).order_by('due_date')[:8]
    recent_health = HealthReport.objects.order_by('-created_at')[:5]
    low_stock = [i for i in InventoryItem.objects.all()[:50] if i.is_low][:5]
    month_start = timezone.localdate().replace(day=1)
    month_exp = Expense.objects.filter(expense_date__gte=month_start).aggregate(
        s=Sum('amount'))['s'] or Decimal('0.00')
    slow = [h for h in hogs if h.growth_status() in ('slow', 'losing')][:5]
    market = [h for h in hogs
              if h.current_weight_kg and float(h.current_weight_kg) >= float(h.target_weight_kg or 100)][:5]
    context = {
        'hog_count': hogs.count(),
        'alerts': alerts, 'unread': unread, 'due_care': due_care,
        'recent_health': recent_health, 'low_stock': low_stock,
        'month_expenses': month_exp, 'slow_hogs': slow, 'market_hogs': market,
    }
    return render(request, 'farm/dashboard.html', context)


@login_required(login_url='login')
@user_passes_test(_is_admin, login_url='dashboard')
def admin_overview(request):
    total_users = User.objects.count()
    total_hogs = Hog.objects.count()
    open_health = HealthReport.objects.filter(status__in=['open', 'monitoring']).count()
    urgent = HealthReport.objects.filter(urgency='urgent', status__in=['open', 'monitoring']).count()
    open_alerts = Alert.objects.filter(is_resolved=False).count()
    recent_alerts = Alert.objects.order_by('-created_at')[:10]
    by_urgency = list(HealthReport.objects.order_by().values('urgency').annotate(n=Count('id')))
    by_stage = list(Hog.objects.order_by().values('stage').annotate(n=Count('id')))
    recent_meds = Medicine.objects.order_by('-updated_at')[:5]
    context = {
        'total_users': total_users, 'total_hogs': total_hogs,
        'open_health': open_health, 'urgent': urgent, 'open_alerts': open_alerts,
        'recent_alerts': recent_alerts, 'by_urgency': by_urgency, 'by_stage': by_stage,
        'recent_meds': recent_meds,
    }
    return render(request, 'farm/admin_dashboard.html', context)


# ------------------------------------------------------------ hogs (public)
def hog_list_page(request):
    q = request.GET.get('q', '').strip()
    qs = Hog.objects.all().order_by('code')
    if q:
        qs = qs.filter(Q(code__icontains=q) | Q(name__icontains=q) | Q(breed__icontains=q))
    paginator = Paginator(qs, 10)
    hogs = paginator.get_page(request.GET.get('page', 1))
    return render(request, 'farm/hog_list.html', {'hogs': hogs, 'query': q})


def hog_list_ajax(request):
    q = request.GET.get('q', '').strip()
    qs = Hog.objects.all().order_by('code')
    if q:
        qs = qs.filter(Q(code__icontains=q) | Q(name__icontains=q) | Q(breed__icontains=q))
    paginator = Paginator(qs, 10)
    page = paginator.get_page(request.GET.get('page', 1))
    data = [{'id': h.id, 'code': h.code, 'name': h.display_name, 'breed': h.breed,
             'stage': h.get_stage_display(), 'status': h.get_status_display(),
             'weight': str(h.current_weight_kg or ''), 'age_weeks': h.age_weeks()}
            for h in page.object_list]
    return JsonResponse({'data': data, 'page': page.number, 'pages': paginator.num_pages,
                         'total': paginator.count, 'has_next': page.has_next(),
                         'has_prev': page.has_previous()})


def hog_get_ajax(request, pk):
    h = get_object_or_404(Hog, pk=pk)
    return JsonResponse({'id': h.id, 'code': h.code, 'name': h.name, 'breed': h.breed,
                         'sex': h.sex, 'birth_date': str(h.birth_date), 'stage': h.stage,
                         'status': h.status, 'current_weight_kg': str(h.current_weight_kg or ''),
                         'target_weight_kg': str(h.target_weight_kg),
                         'purchase_cost': str(h.purchase_cost), 'notes': h.notes})


@require_POST
def hog_save_ajax(request):
    owner = _effective_owner(request)
    hog_id = request.POST.get('id')
    if hog_id:
        hog = get_object_or_404(Hog, pk=hog_id)
    else:
        hog = Hog(owner=owner)
    code = request.POST.get('code', '').strip()
    if not code:
        return JsonResponse({'error': 'Ear tag / code is required.'}, status=400)
    dup = Hog.objects.filter(code=code)
    if hog.pk:
        dup = dup.exclude(pk=hog.pk)
    if dup.exists():
        return JsonResponse({'error': 'That code already exists.'}, status=400)
    if not hog.pk:
        hog.owner = owner
    hog.code = code
    hog.name = request.POST.get('name', '').strip()
    hog.breed = request.POST.get('breed', 'Crossbred').strip() or 'Crossbred'
    hog.sex = request.POST.get('sex', 'female')
    try:
        hog.birth_date = request.POST.get('birth_date') or hog.birth_date or timezone.localdate()
    except ValueError:
        return JsonResponse({'error': 'Invalid birth date.'}, status=400)
    hog.stage = request.POST.get('stage', hog.stage if hog.pk else 'piglet')
    hog.status = request.POST.get('status', hog.status if hog.pk else 'active')
    w = _to_decimal(request.POST.get('current_weight_kg'), None)
    if request.POST.get('current_weight_kg') and w is None:
        return JsonResponse({'error': 'Invalid weight.'}, status=400)
    if w is not None:
        hog.current_weight_kg = w
    t = _to_decimal(request.POST.get('target_weight_kg'), hog.target_weight_kg if hog.pk else Decimal('100.00'))
    hog.target_weight_kg = t or Decimal('100.00')
    hog.purchase_cost = _to_decimal(request.POST.get('purchase_cost'), hog.purchase_cost if hog.pk else Decimal('0.00')) or Decimal('0.00')
    hog.notes = request.POST.get('notes', '')
    hog.save()
    messages.success(request, f'Hog "{hog.code}" saved.')
    return JsonResponse({'status': 'success', 'id': hog.id})


@require_POST
def hog_delete_ajax(request, pk):
    hog = get_object_or_404(Hog, pk=pk)
    code = hog.code
    hog.delete()
    return JsonResponse({'status': 'deleted', 'message': f'Hog "{code}" deleted.'})


def hog_detail_page(request, pk):
    hog = get_object_or_404(Hog, pk=pk)
    weights = hog.weights.order_by('-date', '-id')
    feedings = hog.feedings.order_by('-feeding_date', '-id')[:20]
    cares = hog.care_schedules.order_by('due_date')[:20]
    health = hog.health_reports.order_by('-created_at')[:10]
    expenses = hog.expenses.order_by('-expense_date')[:20]
    plan = suggest_feeding(hog)
    adg = hog.average_daily_gain()
    market_date = hog.predicted_market_date()
    chart_weights = list(hog.weights.order_by('date').values('date', 'weight_kg'))
    return render(request, 'farm/hog_detail.html', {
        'hog': hog, 'weights': weights, 'feedings': feedings, 'cares': cares,
        'health': health, 'expenses': expenses, 'plan': plan, 'adg': adg,
        'market_date': market_date, 'growth': hog.growth_status(),
        'chart_weights': chart_weights,
    })


# ------------------------------------------------------------ weights / feeding / care (public)
@require_POST
def weight_save_ajax(request, pk):
    hog = get_object_or_404(Hog, pk=pk)
    w = _to_decimal(request.POST.get('weight_kg'))
    if w is None or w <= 0 or w > 500:
        return JsonResponse({'error': 'Weight must be 0–500 kg.'}, status=400)
    rec = WeightRecord(hog=hog, weight_kg=w,
                       date=request.POST.get('date') or timezone.localdate(),
                       notes=request.POST.get('notes', '')[:255])
    rec.save()
    run_automation_for_owner(hog.owner)
    messages.success(request, 'Weight recorded.')
    return JsonResponse({'status': 'success', 'adg': hog.average_daily_gain()})


@require_POST
def weight_delete_ajax(request, pk, rid):
    hog = get_object_or_404(Hog, pk=pk)
    rec = get_object_or_404(WeightRecord, pk=rid, hog=hog)
    rec.delete()
    return JsonResponse({'status': 'deleted'})


@require_POST
def feeding_save_ajax(request, pk):
    hog = get_object_or_404(Hog, pk=pk)
    amt = _to_decimal(request.POST.get('amount_kg_per_day'), None)
    if amt is None or amt <= 0 or amt > 20:
        return JsonResponse({'error': 'Amount must be 0–20 kg/day.'}, status=400)
    FeedingRecord.objects.create(
        hog=hog, feed_category=request.POST.get('feed_category', 'grower'),
        feed_name=request.POST.get('feed_name', '')[:120], amount_kg_per_day=amt,
        feeding_date=request.POST.get('feeding_date') or timezone.localdate(),
        notes=request.POST.get('notes', '')[:255])
    messages.success(request, 'Feeding record saved.')
    return JsonResponse({'status': 'success'})


@require_POST
def feeding_delete_ajax(request, pk, rid):
    hog = get_object_or_404(Hog, pk=pk)
    rec = get_object_or_404(FeedingRecord, pk=rid, hog=hog)
    rec.delete()
    return JsonResponse({'status': 'deleted'})


def care_page(request):
    qs = CareSchedule.objects.all()
    status = request.GET.get('status', 'open')
    if status == 'open':
        qs = qs.filter(completed=False)
    elif status == 'done':
        qs = qs.filter(completed=True)
    qs = qs.order_by('due_date')
    paginator = Paginator(qs, 15)
    tasks = paginator.get_page(request.GET.get('page', 1))
    hogs = Hog.objects.all()
    return render(request, 'farm/care.html', {'tasks': tasks, 'hogs': hogs, 'status': status})


@require_POST
def care_save_ajax(request):
    owner = _effective_owner(request)
    hog = None
    if request.POST.get('hog_id'):
        hog = get_object_or_404(Hog, pk=request.POST.get('hog_id'))
    title = request.POST.get('title', '').strip()
    if not title:
        return JsonResponse({'error': 'Title is required.'}, status=400)
    due = request.POST.get('due_date')
    if not due:
        return JsonResponse({'error': 'Due date is required.'}, status=400)
    task_id = request.POST.get('id')
    if task_id:
        task = get_object_or_404(CareSchedule, pk=task_id)
        task.title, task.due_date, task.hog = title, due, hog
        task.care_type = request.POST.get('care_type', task.care_type)
        task.notes = request.POST.get('notes', '')
        task.save()
    else:
        task = CareSchedule.objects.create(
            owner=owner, hog=hog, title=title, due_date=due,
            care_type=request.POST.get('care_type', 'checkup'),
            notes=request.POST.get('notes', ''))
    messages.success(request, 'Care task saved.')
    return JsonResponse({'status': 'success', 'id': task.id})


@require_POST
def care_toggle_ajax(request, pk):
    task = get_object_or_404(CareSchedule, pk=pk)
    task.completed = not task.completed
    task.completed_at = timezone.now() if task.completed else None
    task.save()
    return JsonResponse({'status': 'success', 'completed': task.completed})


@require_POST
def care_delete_ajax(request, pk):
    get_object_or_404(CareSchedule, pk=pk).delete()
    return JsonResponse({'status': 'deleted'})


# ------------------------------------------------------------ health + AI assistant (public)
def health_page(request):
    qs = HealthReport.objects.all()
    q = request.GET.get('q', '').strip()
    if q:
        qs = qs.filter(Q(symptoms__icontains=q) | Q(hog__code__icontains=q))
    qs = qs.order_by('-created_at')
    paginator = Paginator(qs, 10)
    reports = paginator.get_page(request.GET.get('page', 1))
    hogs = Hog.objects.filter(status__in=['active', 'quarantined'])
    if _is_public_request(request):
        chats = AIConsultation.objects.filter(owner=_public_owner()).order_by('-created_at')[:10]
    else:
        chats = AIConsultation.objects.filter(owner=request.user).order_by('-created_at')[:10]
    return render(request, 'farm/health.html', {'reports': reports, 'hogs': hogs, 'query': q, 'chats': chats})


@require_POST
def health_save_ajax(request):
    owner = _effective_owner(request)
    hog = get_object_or_404(Hog, pk=request.POST.get('hog_id', ''))
    symptoms = request.POST.get('symptoms', '').strip()
    if not symptoms:
        return JsonResponse({'error': 'Please describe the symptoms.'}, status=400)
    try:
        duration = max(1, int(request.POST.get('duration_days', 1)))
        affected = max(1, int(request.POST.get('affected_count', 1)))
    except ValueError:
        return JsonResponse({'error': 'Invalid duration/affected count.'}, status=400)
    appetite = request.POST.get('appetite', 'normal')
    behavior = request.POST.get('behavior', '')
    hog_info = f'{hog.code} ({hog.breed}, {hog.age_weeks()} wks, {hog.current_weight_kg}kg)'
    result = ai_service.analyze_health(symptoms, appetite, duration, affected, hog_info)
    rep = HealthReport.objects.create(
        hog=hog, reported_by=owner, symptoms=symptoms, appetite=appetite,
        behavior=behavior, duration_days=duration, affected_count=affected,
        urgency=result['urgency'], ai_summary=result['summary'][:2000],
        possible_causes=result['possible_causes'][:3000],
        recommended_steps=result['recommended_steps'][:3000],
        vet_referral=result['vet_referral'])
    run_automation_for_owner(hog.owner)
    messages.success(request, f'Health report saved ({rep.get_urgency_display()}).')
    return JsonResponse({'status': 'success', 'id': rep.id, 'urgency': rep.urgency,
                         'vet_referral': rep.vet_referral, 'provider': result.get('provider')})


@require_POST
def health_status_ajax(request, pk):
    rep = get_object_or_404(HealthReport, pk=pk)
    rep.status = request.POST.get('status', rep.status)
    rep.save()
    return JsonResponse({'status': 'success'})


@require_POST
def assistant_ask_ajax(request):
    owner = _effective_owner(request)
    question = request.POST.get('question', '').strip()
    if not question:
        return JsonResponse({'error': 'Type a question first.'}, status=400)
    hog = None
    if request.POST.get('hog_id'):
        try:
            hog = get_object_or_404(Hog, pk=request.POST.get('hog_id'))
        except Exception:  # noqa: BLE001
            hog = None
    ctx = ''
    if hog:
        ctx = (f'Hog {hog.code}: {hog.breed}, {hog.age_weeks()} wks, {hog.current_weight_kg}kg, '
               f'stage {hog.stage}, ADG {hog.average_daily_gain()}, plan {suggest_feeding(hog)}.')
    result = ai_service.answer_question(question, ctx)
    AIConsultation.objects.create(owner=owner, hog=hog, question=question,
                                  answer=result['answer'][:4000])
    return JsonResponse({'status': 'success', 'answer': result['answer'], 'provider': result['provider']})


# ------------------------------------------------------------ medicines: read public, manage admin-only
def medicine_page(request):
    q = request.GET.get('q', '').strip()
    qs = Medicine.objects.all().order_by('name')
    if q:
        qs = qs.filter(Q(name__icontains=q) | Q(active_ingredient__icontains=q) | Q(intended_use__icontains=q))
    paginator = Paginator(qs, 12)
    meds = paginator.get_page(request.GET.get('page', 1))
    return render(request, 'farm/medicines.html', {'meds': meds, 'query': q})


@login_required(login_url='login')
@require_POST
def medicine_save_ajax(request):
    if not request.user.is_superuser:
        return JsonResponse({'error': 'Only admins manage the medicine library.'}, status=403)
    name = request.POST.get('name', '').strip()
    if not name:
        return JsonResponse({'error': 'Medicine name is required.'}, status=400)
    med_id = request.POST.get('id')
    med = get_object_or_404(Medicine, pk=med_id) if med_id else Medicine()
    if Medicine.objects.filter(name__iexact=name).exclude(pk=med.pk if med.pk else None).exists():
        return JsonResponse({'error': 'That medicine already exists.'}, status=400)
    med.name = name
    med.active_ingredient = request.POST.get('active_ingredient', '')
    med.intended_use = request.POST.get('intended_use', '')
    med.dosage_info = request.POST.get('dosage_info', '')
    med.precautions = request.POST.get('precautions', '')
    try:
        med.withdrawal_days = max(0, int(request.POST.get('withdrawal_days', 0)))
    except ValueError:
        return JsonResponse({'error': 'Invalid withdrawal days.'}, status=400)
    med.prescription_required = request.POST.get('prescription_required') == 'true'
    med.interactions = request.POST.get('interactions', '')
    med.reference_source = request.POST.get('reference_source', '')
    med.save()
    messages.success(request, f'Medicine "{med.name}" saved.')
    return JsonResponse({'status': 'success', 'id': med.id})


@login_required(login_url='login')
@require_POST
def medicine_delete_ajax(request, pk):
    if not request.user.is_superuser:
        return JsonResponse({'error': 'Only admins manage the medicine library.'}, status=403)
    get_object_or_404(Medicine, pk=pk).delete()
    return JsonResponse({'status': 'deleted'})


# ------------------------------------------------------------ inventory + expenses (public, shared)
def inventory_page(request):
    inv = InventoryItem.objects.all().order_by('name')
    exp = Expense.objects.all().order_by('-expense_date', '-id')
    paginator = Paginator(exp, 12)
    expenses = paginator.get_page(request.GET.get('page', 1))
    totals = exp.aggregate(s=Sum('amount'))['s'] or Decimal('0.00')
    by_cat = list(exp.order_by().values('category').annotate(s=Sum('amount')))
    hogs = Hog.objects.all()
    return render(request, 'farm/inventory.html',
                  {'items': inv, 'expenses': expenses, 'total': totals, 'by_cat': by_cat, 'hogs': hogs})


@require_POST
def inventory_save_ajax(request):
    owner = _effective_owner(request)
    item_id = request.POST.get('id')
    item = get_object_or_404(InventoryItem, pk=item_id) if item_id else InventoryItem(owner=owner)
    name = request.POST.get('name', '').strip()
    if not name:
        return JsonResponse({'error': 'Item name is required.'}, status=400)
    if not item.pk:
        item.owner = owner
    item.name = name
    item.category = request.POST.get('category', 'feed')
    item.quantity = _to_decimal(request.POST.get('quantity'), Decimal('0.00')) or Decimal('0.00')
    item.unit = request.POST.get('unit', 'kg') or 'kg'
    item.low_stock_threshold = _to_decimal(request.POST.get('low_stock_threshold'), Decimal('5.00')) or Decimal('5.00')
    item.expiry_date = request.POST.get('expiry_date') or None
    item.unit_cost = _to_decimal(request.POST.get('unit_cost'), Decimal('0.00')) or Decimal('0.00')
    item.save()
    messages.success(request, f'Inventory "{item.name}" saved.')
    return JsonResponse({'status': 'success', 'id': item.id})


@require_POST
def inventory_delete_ajax(request, pk):
    get_object_or_404(InventoryItem, pk=pk).delete()
    return JsonResponse({'status': 'deleted'})


@require_POST
def expense_save_ajax(request):
    owner = _effective_owner(request)
    hog = None
    if request.POST.get('hog_id'):
        hog = get_object_or_404(Hog, pk=request.POST.get('hog_id'))
    amt = _to_decimal(request.POST.get('amount'))
    if amt is None or amt <= 0:
        return JsonResponse({'error': 'Enter a valid amount.'}, status=400)
    exp_id = request.POST.get('id')
    if exp_id:
        exp = get_object_or_404(Expense, pk=exp_id)
        exp.amount, exp.category, exp.hog = amt, request.POST.get('category', exp.category), hog
        exp.expense_date = request.POST.get('expense_date') or exp.expense_date
        exp.description = request.POST.get('description', '')
        exp.save()
    else:
        exp = Expense.objects.create(owner=owner, hog=hog, amount=amt,
                                     category=request.POST.get('category', 'feed'),
                                     expense_date=request.POST.get('expense_date') or timezone.localdate(),
                                     description=request.POST.get('description', ''))
    messages.success(request, 'Expense recorded.')
    return JsonResponse({'status': 'success', 'id': exp.id})


@require_POST
def expense_delete_ajax(request, pk):
    get_object_or_404(Expense, pk=pk).delete()
    return JsonResponse({'status': 'deleted'})


# ------------------------------------------------------------ search
def search_page(request):
    q = request.GET.get('q', '').strip()
    hogs, meds, items, reports = [], [], [], []
    if q:
        hogs = Hog.objects.filter(Q(code__icontains=q) | Q(name__icontains=q) | Q(breed__icontains=q))
        meds = Medicine.objects.filter(Q(name__icontains=q) | Q(active_ingredient__icontains=q) | Q(intended_use__icontains=q))
        items = InventoryItem.objects.filter(Q(name__icontains=q) | Q(category__icontains=q))
        reports = HealthReport.objects.filter(Q(symptoms__icontains=q) | Q(hog__code__icontains=q))
    return render(request, 'farm/search.html', {
        'q': q, 'hogs': hogs, 'meds': meds, 'items': items, 'reports': reports,
        'total': len(hogs) + len(meds) + len(items) + len(reports),
    })


# ------------------------------------------------------------ alerts + automation + report (public)
def alerts_page(request):
    qs = Alert.objects.all().order_by('-created_at')
    show = request.GET.get('show', 'open')
    if show == 'open':
        qs = qs.filter(is_resolved=False)
    paginator = Paginator(qs, 12)
    alerts = paginator.get_page(request.GET.get('page', 1))
    return render(request, 'farm/alerts.html', {'alerts': alerts, 'show': show})


@require_POST
def alert_action_ajax(request, pk):
    alert = get_object_or_404(Alert, pk=pk)
    action = request.POST.get('action')
    if action == 'read':
        alert.is_read = True
    elif action == 'resolve':
        alert.is_read, alert.is_resolved = True, True
    alert.save()
    return JsonResponse({'status': 'success'})


@require_POST
def run_automation_ajax(request):
    # Public: run automation across all owners with data; admin may target one owner.
    if _is_admin(request.user) and request.POST.get('owner_id'):
        target = get_object_or_404(User, pk=request.POST.get('owner_id'))
        new_alerts = run_automation_for_owner(target)
        return JsonResponse({'status': 'success', 'new_alerts': len(new_alerts)})
    if _is_public_request(request) or not _is_admin(request.user):
        total = 0
        owner_ids = Hog.objects.order_by().values_list('owner_id', flat=True).distinct()
        owners = User.objects.filter(pk__in=list(owner_ids))
        if not owners.exists():
            total = len(run_automation_for_owner(_public_owner()))
        else:
            for owner in owners:
                total += len(run_automation_for_owner(owner))
        return JsonResponse({'status': 'success', 'new_alerts': total})
    new_alerts = run_automation_for_owner(request.user)
    return JsonResponse({'status': 'success', 'new_alerts': len(new_alerts)})


def farm_report_page(request):
    hogs = list(Hog.objects.exclude(status__in=['sold', 'deceased']))
    stats = {
        'total_hogs': len(hogs),
        'avg_weight': round(sum(float(h.current_weight_kg or 0) for h in hogs) / len(hogs), 1) if hogs else 0,
        'slow_growth': sum(1 for h in hogs if h.growth_status() in ('slow', 'losing')),
        'market_ready': sum(1 for h in hogs if h.current_weight_kg and float(h.current_weight_kg) >= float(h.target_weight_kg or 100)),
        'open_health': HealthReport.objects.filter(status__in=['open', 'monitoring']).count(),
        'unresolved_alerts': Alert.objects.filter(is_resolved=False).count(),
        'month_expenses': str((Expense.objects.aggregate(s=Sum('amount'))['s'] or 0)),
    }
    summary = None
    if request.method == 'POST':
        owner = request.user if getattr(request.user, 'is_authenticated', False) else _public_owner()
        result = ai_service.summarize_farm(owner, stats)
        summary = result['summary']
        messages.success(request, 'AI farm report generated.')
    refs = ReferenceArticle.objects.all()[:10]
    return render(request, 'farm/report.html', {'stats': stats, 'summary': summary, 'refs': refs})
