from django.shortcuts import render, get_object_or_404
from django.shortcuts import redirect
from allauth.socialaccount.models import SocialAccount
from .models import Repository, Milestone, Task
import requests
from .scripts import sync_repos
from .forms import MilestoneForm, TaskForm


# Create your views here.

def homepage(request):
    return render(request, 'roadmap/home.html')

def create_new_roadmap_subsite(request):
    if not request.user.is_authenticated: 
        return render(request, 'roadmap/create_new_roadmap.html')

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
    tasks = Task.objects.filter(repository=repository)

    milestone_form = MilestoneForm()
    task_form = TaskForm(repository=repository)  # Pass the repository instance to the TaskForm

    context = {
        'milestone_form': milestone_form,
        'milestones': milestones,
        'task_form': task_form,
        'tasks': tasks,
        'repository': repository,
    }

    if request.method == 'POST':
        milestone_form = MilestoneForm(request.POST)
        task_form = TaskForm(request.POST)
        if 'milestoneform' in request.POST:
            if milestone_form.is_valid():
                milestone = milestone_form.save(commit=False)
                milestone.repository = repository
                milestone.save()

        if 'taskform' in request.POST:
            if task_form.is_valid():
                task = task_form.save(commit=False)
                task.repository = repository
                task.save()

    return render(request, 'roadmap/create_roadmap.html', context)

def my_roadmaps_subsite(request):
    if not request.user.is_authenticated:
        return render(request, 'roadmap/my_roadmaps.html')

    username = SocialAccount.objects.get(user=request.user)
    url = f"https://api.github.com/users/{username}/repos"
    response = requests.get(url)

    if response.status_code == 200:
        repos = response.json()
        sync_repos.sync(repos)
    else:
        repos = []

    context = {"repos": repos}

    return render(request, 'roadmap/my_roadmaps.html', context)

def roadmap(request, repository_id):
    repository = get_object_or_404(Repository, git_id=repository_id)
    milestones = Milestone.objects.filter(repository=repository)

    context = {
        'milestones' : milestones,
        'repository' : repository,
    }

    return render(request, 'roadmap/roadmap.html', context)

def mark_task_done(request, task_id):
    task = get_object_or_404(Task, pk=task_id)
    task.isdone = True
    task.save()
    repository_git_id = task.repository.git_id
    return redirect(f'http://localhost:8000/roadmaps/{repository_git_id}/')

def mark_task_undone(request, task_id):
    task = get_object_or_404(Task, pk=task_id)
    task.isdone = False
    task.save()
    repository_git_id = task.repository.git_id
    return redirect(f'http://localhost:8000/roadmaps/{repository_git_id}/')

def delete_task(request, task_id):
    task = get_object_or_404(Task, id=task_id)
    repository_git_id = task.repository.git_id
    task.delete()
    return redirect(f'http://localhost:8000/create_new_roadmap/{repository_git_id}/')

def delete_milestone(request, milestone_id):
    milestone = get_object_or_404(Milestone, id=milestone_id)
    repository_git_id = milestone.repository.git_id
    milestone.delete()
    return redirect(f'http://localhost:8000/create_new_roadmap/{repository_git_id}/')