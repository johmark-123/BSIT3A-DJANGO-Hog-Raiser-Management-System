from django.db import migrations


MEDICINES = [
    {'name': 'Oxytetracycline LA', 'active_ingredient': 'Oxytetracycline 200mg/mL',
     'intended_use': 'Bacterial infections (respiratory, enteric) as labeled for swine.',
     'dosage_info': 'Follow label; veterinarian determines dose and route.',
     'precautions': 'Do not use in known hypersensitivity. Observe withdrawal.',
     'withdrawal_days': 28, 'prescription_required': True,
     'interactions': 'May interact with bactericidal antibiotics; consult vet.',
     'reference_source': 'Product label / veterinarian reference (verify locally)'},
    {'name': 'Amoxicillin Trihydrate', 'active_ingredient': 'Amoxicillin',
     'intended_use': 'Susceptible bacterial infections in swine per label.',
     'dosage_info': 'Label-directed; vet confirms.',
     'precautions': 'Allergy risk. Complete course as directed by vet.',
     'withdrawal_days': 14, 'prescription_required': True, 'interactions': '',
     'reference_source': 'Product label (verify locally)'},
    {'name': 'Ivermectin 1%', 'active_ingredient': 'Ivermectin',
     'intended_use': ' roundworms, lungworms, lice, mange mites per label.',
     'dosage_info': 'Label-directed injectable; vet confirms schedule.',
     'precautions': 'Do not use in severely stressed animals without vet advice.',
     'withdrawal_days': 18, 'prescription_required': False,
     'interactions': 'Avoid concurrent similar parasiticides without vet advice.',
     'reference_source': 'Product label (verify locally)'},
    {'name': 'Vitamin ADE Injectable', 'active_ingredient': 'Vitamins A, D3, E',
     'intended_use': 'Vitamin supplementation for deficiency prevention.',
     'dosage_info': 'Per label by weight; vet confirms.',
     'precautions': 'Do not overdose fat-soluble vitamins.',
     'withdrawal_days': 0, 'prescription_required': False, 'interactions': '',
     'reference_source': 'Product label (verify locally)'},
    {'name': 'Electrolytes + Dextrose', 'active_ingredient': 'Electrolytes, dextrose',
     'intended_use': 'Supportive hydration for scouring / heat-stressed pigs.',
     'dosage_info': 'Oral per label; clean water alongside.',
     'precautions': 'Not a substitute for vet care in severe dehydration.',
     'withdrawal_days': 0, 'prescription_required': False, 'interactions': '',
     'reference_source': 'Product label (verify locally)'},
    {'name': 'Hog Cholera Vaccine', 'active_ingredient': 'Hog cholera live vaccine',
     'intended_use': 'Immunization per national vaccination program schedule.',
     'dosage_info': 'Veterinarian / municipal agriculture office administers.',
     'precautions': 'Cold chain required; follow program schedule.',
     'withdrawal_days': 0, 'prescription_required': False, 'interactions': '',
     'reference_source': 'DA / municipal vet program (verify locally)'},
]

ARTICLES = [
    ('Starter to Finisher: Feed Guide', 'feeding',
     'Pre-starter (0-8 wks) → starter (8-12 wks, ~1kg/d) → grower (12-20 wks, 1.8-2.3kg/d) → finisher (20-26 wks, ~2.8kg/d to ~100kg). Change feeds over 5-7 days. Clean water always.',
     'Farm practice guide (adapt to local feed brands)'),
    ('Biosecurity Basics', 'health',
     'Quarantine new/returning hogs 14-30 days. Disinfect boots, tools, pens. Limit visitors. Report high fever + sudden deaths to municipal vet immediately (ASF watch).',
     'DA biosecurity guidance (verify locally)'),
    ('Scours Response Checklist', 'health',
     '1) Isolate. 2) Keep warm, dry, hydrated (electrolytes). 3) Record onset, count, stool. 4) Disinfect pen. 5) Call vet if bloody, dehydrated, or >2 days / multiple hogs.',
     'Vet triage checklist'),
    ('Weigh Weekly, Sell Right', 'management',
     'Weigh same day weekly. ADG target ~0.65kg/d grower-finisher. Below 0.40 two weeks → review feed, parasites, health. Market ~90-110kg depending on buyer.',
     'Farm practice guide'),
    ('Farrowing Prep', 'breeding',
     'Prepare clean, dry, draft-free pen 1 week before due date (~114 days gestation). Vitamin ADE pre-farrow per vet; monitor gilt/sow feed intake; assist only when needed, call vet for dystocia.',
     'Breeding guide (verify locally)'),
]


def seed(apps, schema_editor):
    Medicine = apps.get_model('farm', 'Medicine')
    ReferenceArticle = apps.get_model('farm', 'ReferenceArticle')
    for m in MEDICINES:
        Medicine.objects.get_or_create(name=m['name'], defaults=m)
    for title, cat, content, src in ARTICLES:
        ReferenceArticle.objects.get_or_create(title=title, defaults={
            'category': cat, 'content': content, 'source': src})


def unseed(apps, schema_editor):
    pass


class Migration(migrations.Migration):
    dependencies = [('farm', '0001_initial')]
    operations = [migrations.RunPython(seed, unseed)]
