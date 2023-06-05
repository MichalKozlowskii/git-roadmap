from django import forms
from .models import Milestone, Task

class MilestoneForm(forms.ModelForm):
    class Meta:
        model = Milestone
        fields = ['name']

class TaskForm(forms.ModelForm):
    def __init__(self, *args, **kwargs):
        repository = kwargs.pop('repository', None)
        super(TaskForm, self).__init__(*args, **kwargs)
        if repository:
            self.fields['milestone'].queryset = Milestone.objects.filter(repository=repository)

    class Meta:
        model = Task
        fields = ['milestone', 'name']
