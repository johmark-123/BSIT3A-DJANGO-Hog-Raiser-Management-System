from django.test import SimpleTestCase
from django.urls import Resolver404, resolve


class MainDashboardTests(SimpleTestCase):
    def test_root_displays_login_page(self):
        self.assertEqual(resolve('/').func, resolve('/login/').func)
        self.assertEqual(resolve('/').url_name, 'root')

    def test_login_route_remains_available(self):
        self.assertEqual(resolve('/login/').url_name, 'login')

    def test_removed_legacy_sections_are_not_routed(self):
        for path in ('/home/', '/users/', '/info/'):
            with self.subTest(path=path), self.assertRaises(Resolver404):
                resolve(path)
