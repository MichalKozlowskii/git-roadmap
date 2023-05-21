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

def create_new_roadmap(request, repository_id):
    repository = get_object_or_404(Repository, git_id=repository_id)

    #if request.method == 'POST':
        # Handle form submission and save the roadmap
        # Retrieve form data, create roadmap instance, etc.
        # Save the roadmap to the database

        #return redirect('roadmap_detail', roadmap_id=new_roadmap.id)

    context = {
        'repository': repository,
    }
    return render(request, 'create_roadmap.html', context)