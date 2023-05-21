from django.shortcuts import render, get_object_or_404
from django.shortcuts import redirect
from allauth.socialaccount.models import SocialAccount
from .models import Repository, Roadmap
import requests
from roadmap.scripts import sync_repos


# Create your views here.

def homepage(request):
    return render(request, 'roadmap/home.html')

def create_new_roadmap_subsite(request):
    username = SocialAccount.objects.get(user=request.user)
    url = f"https://api.github.com/users/{username}/repos"
    response = requests.get(url)

    if response.status_code == 200:
        repos = response.json()
        sync_repos.sync(repos)
    else:
        repos = []

    context = {"repos": repos}

    return render(request, 'roadmap/create_new_roadmap.html', context)