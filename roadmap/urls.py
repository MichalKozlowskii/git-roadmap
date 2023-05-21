from django.urls import path
from . import views

urlpatterns = [
    path('', views.homepage),
    path('create_new_roadmap/', views.create_new_roadmap)
]