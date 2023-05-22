from django.db import models
from django.contrib.auth.models import User

class Repository(models.Model):
    name = models.CharField(max_length=255)
    owner = models.CharField(max_length=255)
    url = models.URLField()
    git_id = models.BigIntegerField()

    def __str__(self):
        return self.name

class Milestone(models.Model):
    repository = models.ForeignKey(Repository, on_delete=models.CASCADE)
    name = models.CharField(max_length=255)

    def __str__(self):
        return self.name

class Task(models.Model):
    repository = models.ForeignKey(Repository, on_delete=models.CASCADE)
    milestone = models.ForeignKey(Milestone, on_delete=models.CASCADE, null=True, blank=True)
    name = models.CharField(max_length=255)
    isdone = models.BooleanField(default = False)

    def __str__(self):
        return self.name