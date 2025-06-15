from django.urls import path
from . import views

urlpatterns = [
    
    path('', views.login_view, name='login'),  # Corrected

    path('administrator/dashboard/', views.admin_dashboard_view, name='admin_dashboard_view'),
    path('user/dashboard/', views.user_dashboard_view, name='user_dashboard_view'),
    path('register/',  views.register_view, name='register'),
    path('logout/', views.logout_view, name='logout'),

    path('file-archive-upload/', views.upload_file_view, name='upload_file_view'),
    path('file-archive/', views.file_archive_view, name='file_archive_view'),
    path('file/edit/<int:file_id>/', views.edit_file_view, name='edit_file_view'),
    path('file-archive/delete/<int:file_id>/', views.delete_file_view, name='delete_file'),

    path('users/', views.user_list_view, name='user_list_view'),
    path('add-user/', views.add_user_view, name='add_user_view'),
    path('users/edit/', views.edit_user_view, name='edit_user_view'),
    path('users/delete/', views.delete_user_view, name='delete_user_view'),
]
