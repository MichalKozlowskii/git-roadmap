from django.shortcuts import render, get_object_or_404
from django.shortcuts import redirect
from allauth.socialaccount.models import SocialAccount
from .models import Repository, Milestone
import requests
from .scripts import sync_repos
from .forms import MilestoneForm


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
    milestones = Milestone.objects.filter(repository=repository)

    form = MilestoneForm()
    context = {
        'form' : form,
        'milestones' : milestones,
        'repository': repository,
    }

    if request.method == 'POST':
        form = MilestoneForm(request.POST)
        if form.is_valid():
            milestone = form.save(commit=False)
            milestone.repository = repository
            milestone.save()

    return render(request, 'roadmap/create_roadmap.html', context)