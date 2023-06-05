from django.contrib import admin
from django.urls import path, include
from roadmap import views

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', views.homepage, name='homepage'),
    path('accounts/', include('allauth.urls')),
    path('create_new_roadmap/', views.create_new_roadmap_subsite, name='create_new_roadmap_subsite'),
    path('create_new_roadmap/<int:repository_id>/', views.create_new_roadmap, name='create_new_roadmap'),
    path('roadmaps/', views.my_roadmaps_subsite, name='my_roadmaps_subsite'),
    path('roadmaps/<int:repository_id>/', views.roadmap, name='roadmaps'),
    path('mark-task-done/<int:task_id>/', views.mark_task_done, name='mark-task-done'),
    path('mark-task-undone/<int:task_id>/', views.mark_task_undone, name='mark-task-undone'),
    path('delete-task/<int:task_id>/', views.delete_task, name='delete-task'),
    path('delete-milestone/<int:milestone_id>/', views.delete_milestone, name='delete-milestone'),
]
