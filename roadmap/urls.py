from django.urls import path
from . import views

urlpatterns = [
    path('', views.homepage),
    path('create_new_roadmap/', views.create_new_roadmap_subsite),
    path('create_new_roadmap/<int:repository_id>/', views.create_new_roadmap),
    path('roadmaps/', views.my_roadmaps_subsite),
    path('roadmaps/<int:repository_id>/', views.roadmap),
    path('mark-task-done/<int:task_id>/', views.mark_task_done),
    path('mark-task-undone/<int:task_id>/', views.mark_task_undone),
]