from django import forms

from .models import BatchFeedDeduction, MedicalTreatmentLog


class BatchFeedDeductionForm(forms.ModelForm):
    class Meta:
        model = BatchFeedDeduction
        fields = ['batch', 'feed_inventory', 'quantity_kg']
        widgets = {
            'batch': forms.Select(attrs={'class': 'form-control'}),
            'feed_inventory': forms.Select(attrs={'class': 'form-control'}),
            'quantity_kg': forms.NumberInput(attrs={'class': 'form-control', 'step': '0.1', 'placeholder': 'Hal. 25.5'}),
        }

    def clean(self):
        cleaned_data = super().clean()
        feed_inventory = cleaned_data.get('feed_inventory')
        quantity_kg = cleaned_data.get('quantity_kg')

        if feed_inventory and quantity_kg:
            if feed_inventory.quantity_kg < quantity_kg:
                raise forms.ValidationError(
                    f'Babala: Hindi sapat ang stock! Ang natitira sa {feed_inventory.feed_type} ay {feed_inventory.quantity_kg} kg lamang.'
                )
        return cleaned_data


class MedicalTreatmentLogForm(forms.ModelForm):
    class Meta:
        model = MedicalTreatmentLog
        fields = ['pig_or_batch', 'medicine', 'quantity_used', 'date_administered', 'notes']
        widgets = {
            'pig_or_batch': forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'Hal. PIG-012 o Grower Batch 1'}),
            'medicine': forms.Select(attrs={'class': 'form-control'}),
            'quantity_used': forms.NumberInput(attrs={'class': 'form-control', 'step': '0.1'}),
            'date_administered': forms.DateInput(attrs={'class': 'form-control', 'type': 'date'}),
            'notes': forms.Textarea(attrs={'class': 'form-control', 'rows': 3}),
        }

    def clean(self):
        cleaned_data = super().clean()
        medicine = cleaned_data.get('medicine')
        quantity_used = cleaned_data.get('quantity_used')

        if medicine and quantity_used:
            if medicine.stock_quantity < quantity_used:
                raise forms.ValidationError(
                    f'Babala: Kulang ang stock ng gamot na {medicine.name}. Kasalukuyang stock: {medicine.stock_quantity} {medicine.unit}.'
                )
        return cleaned_data
