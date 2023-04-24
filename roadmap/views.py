from django.shortcuts import render
import django.contrib.auth as auth

# Create your views here.

def homepage(request):
    return render(request, 'roadmap/home.html')