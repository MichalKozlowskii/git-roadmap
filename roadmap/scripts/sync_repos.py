from roadmap.models import Repository

def sync(repos):
    for repo_data in repos:
        name = repo_data['name']
        owner = repo_data['owner']['login']
        url = repo_data['html_url']
        git_id = repo_data['id']

        repository, created = Repository.objects.get_or_create(
            name=name,
            owner=owner,
            defaults={'url': url},
            git_id = git_id
        )
        if not created:
            repository.url = url
            repository.save()