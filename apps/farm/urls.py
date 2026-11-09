from django.urls import path
from . import views

app_name = 'farm'

urlpatterns = [
    path('', views.dashboard, name='dashboard'),
    path('admin-overview/', views.admin_overview, name='admin_overview'),

    # hogs
    path('hogs/', views.hog_list_page, name='hog_list'),
    path('hogs/ajax/list/', views.hog_list_ajax, name='hog_list_ajax'),
    path('hogs/ajax/save/', views.hog_save_ajax, name='hog_save_ajax'),
    path('hogs/ajax/get/<int:pk>/', views.hog_get_ajax, name='hog_get_ajax'),
    path('hogs/ajax/delete/<int:pk>/', views.hog_delete_ajax, name='hog_delete_ajax'),
    path('hogs/<int:pk>/', views.hog_detail_page, name='hog_detail'),

    # batches
    path('batches/<int:pk>/', views.batch_detail_view, name='batch_detail'),

    # AI health triage
    path('ai-triage/', views.ai_health_triage_view, name='ai_triage'),

    # feeding + medical treatment
    path('feeding/add/', views.add_feeding_record_view, name='feed_deduction_add'),
    path('feeding/list/', views.feed_deduction_list_view, name='feed_deduction_list'),
    path('treatment/add/', views.add_medical_treatment_view, name='treatment_log_add'),
    path('treatment/list/', views.treatment_log_list_view, name='treatment_log_list'),

    # combined records
    path('records/', views.farm_records_list_view, name='records_list'),

    # weights / feeding
    path('hogs/<int:pk>/weights/ajax/save/', views.weight_save_ajax, name='weight_save_ajax'),
    path('hogs/<int:pk>/weights/ajax/delete/<int:rid>/', views.weight_delete_ajax, name='weight_delete_ajax'),
    path('hogs/<int:pk>/feeding/ajax/save/', views.feeding_save_ajax, name='feeding_save_ajax'),
    path('hogs/<int:pk>/feeding/ajax/delete/<int:rid>/', views.feeding_delete_ajax, name='feeding_delete_ajax'),

    # care
    path('care/', views.care_page, name='care'),
    path('care/ajax/save/', views.care_save_ajax, name='care_save_ajax'),
    path('care/ajax/toggle/<int:pk>/', views.care_toggle_ajax, name='care_toggle_ajax'),
    path('care/ajax/delete/<int:pk>/', views.care_delete_ajax, name='care_delete_ajax'),

    # health + AI assistant
    path('health/', views.health_page, name='health'),
    path('health/ajax/save/', views.health_save_ajax, name='health_save_ajax'),
    path('health/ajax/status/<int:pk>/', views.health_status_ajax, name='health_status_ajax'),
    path('health/ajax/ask/', views.assistant_ask_ajax, name='assistant_ask_ajax'),

    # medicines
    path('medicines/', views.medicine_page, name='medicines'),
    path('medicines/ajax/save/', views.medicine_save_ajax, name='medicine_save_ajax'),
    path('medicines/ajax/delete/<int:pk>/', views.medicine_delete_ajax, name='medicine_delete_ajax'),
    path('medicines/ajax/search/', views.medicine_search_ajax, name='medicine_search_ajax'),

    # hog <-> medicine links (API)
    path('hogs/<int:pk>/medicines/', views.hog_medicines_list_ajax, name='hog_medicines_list'),
    path('hogs/<int:pk>/medicines/ajax/list/', views.hog_medicines_list_ajax, name='hog_medicines_list_ajax'),
    path('hogs/<int:pk>/medicines/ajax/link/', views.hog_medicine_link_ajax, name='hog_medicine_link_ajax'),
    path('hogs/<int:pk>/medicines/ajax/unlink/<int:rid>/', views.hog_medicine_unlink_ajax, name='hog_medicine_unlink_ajax'),
    path('hogs/<int:pk>/medications/automation/', views.medication_automation_ajax, name='medication_automation_hog'),
    path('medications/automation/run/', views.medication_automation_ajax, name='medication_automation_run'),

    # inventory + expenses
    path('inventory/', views.inventory_page, name='inventory'),
    path('inventory/ajax/save/', views.inventory_save_ajax, name='inventory_save_ajax'),
    path('inventory/ajax/delete/<int:pk>/', views.inventory_delete_ajax, name='inventory_delete_ajax'),
    path('expenses/ajax/save/', views.expense_save_ajax, name='expense_save_ajax'),
    path('expenses/ajax/delete/<int:pk>/', views.expense_delete_ajax, name='expense_delete_ajax'),

    # alerts / automation / report
    path('alerts/', views.alerts_page, name='alerts'),
    path('alerts/ajax/action/<int:pk>/', views.alert_action_ajax, name='alert_action_ajax'),
    path('alerts/ajax/run/', views.run_automation_ajax, name='run_automation_ajax'),
    path('report/', views.farm_report_page, name='report'),

    # search
    path('search/', views.search_page, name='search'),

    # floating chat widget
    path('chat/ajax/', views.farm_chat_ajax, name='chat_ajax'),
]
