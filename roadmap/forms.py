from django import forms
from .models import Milestone, Task

class MilestoneForm(forms.ModelForm):
    class Meta:
        model = Milestone
        fields = ['name']

class TaskForm(forms.ModelForm):
    class Meta:
        model = Task
        fields = ['milestone', 'name']
