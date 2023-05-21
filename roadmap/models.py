from django.db import models
from django.contrib.auth.models import User

class Repository(models.Model):
    name = models.CharField(max_length=255)
    owner = models.CharField(max_length=255)
    url = models.URLField()
    git_id = models.BigIntegerField()

    def __str__(self):
        return self.name

class Roadmap(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    repository = models.ForeignKey(Repository, on_delete=models.CASCADE)
    # Add other fields as needed

    def __str__(self):
        return f"Roadmap for {self.repository.name}"

class Milestone(models.Model):
    roadmap = models.ForeignKey(Roadmap, on_delete=models.CASCADE)
    name = models.CharField(max_length=255)
    description = models.TextField()
    due_date = models.DateField()
    # Add other fields as needed

    def __str__(self):
        return self.name

class Task(models.Model):
    roadmap = models.ForeignKey(Roadmap, on_delete=models.CASCADE)
    milestone = models.ForeignKey(Milestone, on_delete=models.CASCADE, null=True, blank=True)
    name = models.CharField(max_length=255)
    isdone = models.BooleanField()
    # Add other fields as needed

    def __str__(self):
        return self.name