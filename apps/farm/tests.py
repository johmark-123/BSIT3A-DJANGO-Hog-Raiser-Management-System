from datetime import timedelta

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.urls import reverse
from django.utils import timezone

from apps.farm import ai_service
from apps.farm.automation import run_automation_for_owner
from apps.farm.feeding import suggest_feeding
from apps.farm.models import Alert, Expense, HealthReport, Hog, InventoryItem, WeightRecord

User = get_user_model()


class HogGrowthTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username='raiser', password='secret1234')

    def test_adg_and_market_prediction(self):
        hog = Hog.objects.create(owner=self.user, code='HOG-001', birth_date=timezone.localdate() - timedelta(days=140),
                                 current_weight_kg=20, target_weight_kg=100)
        WeightRecord.objects.create(hog=hog, date=timezone.localdate() - timedelta(days=10), weight_kg=20)
        WeightRecord.objects.create(hog=hog, date=timezone.localdate(), weight_kg=27)
        hog.refresh_from_db()
        self.assertAlmostEqual(hog.average_daily_gain(), 0.7, places=2)
        self.assertIsNotNone(hog.predicted_market_date())
        self.assertEqual(hog.growth_status(), 'good')

    def test_slow_growth_alert(self):
        hog = Hog.objects.create(owner=self.user, code='HOG-002', birth_date=timezone.localdate() - timedelta(days=140),
                                 current_weight_kg=30, target_weight_kg=100)
        WeightRecord.objects.create(hog=hog, date=timezone.localdate() - timedelta(days=10), weight_kg=29)
        WeightRecord.objects.create(hog=hog, date=timezone.localdate(), weight_kg=30)
        created = run_automation_for_owner(self.user)
        self.assertTrue(any(a.alert_type == 'growth_slow' for a in created))

    def test_feeding_planner(self):
        hog = Hog(owner=self.user, code='HOG-003', birth_date=timezone.localdate() - timedelta(days=100),
                  current_weight_kg=60, stage='grower')
        plan = suggest_feeding(hog)
        self.assertIn(plan['feed_category'], ('grower', 'finisher'))
        self.assertIn('vitamin_plan', plan)


class HealthAITests(TestCase):
    def test_rule_based_triage_never_prescribes(self):
        result = ai_service.analyze_health('hog has diarrhea and eating less', 'reduced', 2, 1, 'HOG-001')
        self.assertIn(result['urgency'], ('routine', 'needs_attention', 'urgent'))
        self.assertIn('veterin', result['recommended_steps'].lower())
        self.assertTrue(result['vet_referral'])

    def test_health_report_flow(self):
        user = User.objects.create_user(username='farmer2', password='secret1234')
        self.client.force_login(user)
        hog = Hog.objects.create(owner=user, code='HOG-010', birth_date=timezone.localdate() - timedelta(days=90))
        resp = self.client.post(reverse('farm:health_save_ajax'), {
            'hog_id': hog.id, 'symptoms': 'coughing and reduced appetite',
            'appetite': 'reduced', 'duration_days': 2, 'affected_count': 1})
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(HealthReport.objects.filter(hog=hog).count(), 1)


class InventoryAutomationTests(TestCase):
    def test_low_stock_and_expiry_alerts(self):
        user = User.objects.create_user(username='farmer3', password='secret1234')
        InventoryItem.objects.create(owner=user, name='Grower Feed', category='feed',
                                     quantity=2, unit='kg', low_stock_threshold=5)
        InventoryItem.objects.create(owner=user, name='Vaccine X', category='medicine',
                                     quantity=10, unit='bottles',
                                     expiry_date=timezone.localdate() + timedelta(days=10))
        created = run_automation_for_owner(user)
        types = {a.alert_type for a in created}
        self.assertIn('low_stock', types)
        self.assertIn('expiring_soon', types)


class DashboardTests(TestCase):
    def test_dashboard_public_no_login(self):
        # Customer pages are public: no login required.
        for name in ('farm:dashboard', 'farm:hog_list', 'farm:health',
                     'farm:care', 'farm:medicines', 'farm:inventory',
                     'farm:alerts', 'farm:report'):
            self.assertEqual(self.client.get(reverse(name)).status_code, 200)

    def test_public_hog_create_attributes_to_shared_owner(self):
        resp = self.client.post(reverse('farm:hog_save_ajax'), {'code': 'PUB-001', 'breed': 'Native'})
        self.assertEqual(resp.status_code, 200)
        hog = Hog.objects.get(code='PUB-001')
        self.assertEqual(hog.owner.username, 'public-farm')

    def test_dashboard_renders(self):
        user = User.objects.create_user(username='farmer4', password='secret1234')
        self.client.force_login(user)
        resp = self.client.get(reverse('farm:dashboard'))
        self.assertEqual(resp.status_code, 200)

    def test_expense_profit_math(self):
        user = User.objects.create_user(username='farmer5', password='secret1234')
        hog = Hog.objects.create(owner=user, code='HOG-020', purchase_cost=2500,
                                 current_weight_kg=95, birth_date=timezone.localdate() - timedelta(days=170))
        Expense.objects.create(owner=user, hog=hog, category='feed', amount=3000,
                               expense_date=timezone.localdate())
        self.assertEqual(float(hog.total_expenses()), 5500.0)
        self.assertAlmostEqual(hog.estimated_profit(price_per_kg=180), 95 * 180 - 5500)
