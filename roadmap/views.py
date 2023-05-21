from django.shortcuts import render
from django.shortcuts import redirect
import django.contrib.auth as auth
from allauth.socialaccount.models import SocialAccount
import requests


# Create your views here.

def homepage(request):
    return render(request, 'roadmap/home.html')

def create_new_roadmap(request):
    username = SocialAccount.objects.get(user=request.user)
    url = f"https://api.github.com/users/{username}/repos"
    response = requests.get(url)

    if response.status_code == 200:
        repos = response.json()
    else:
        repos = []

    context = {"repos": repos}

    return render(request, 'roadmap/create_new_roadmap.html', context)