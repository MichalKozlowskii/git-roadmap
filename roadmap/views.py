from django.shortcuts import render
import django.contrib.auth as auth

# Create your views here.

def homepage(request):
    return render(request, 'roadmap/home.html')

def create_new_roadmap(request):
    return render(request, 'roadmap/create_new_roadmap.html')