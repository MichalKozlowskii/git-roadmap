"""
URL configuration for git_roadmap project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/4.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
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
