"""Rule-based feeding & vitamin planner.

Approximate Philippine backyard/commercial guide. Adjust freely for thesis.
Values are suggestions only — not a substitute for a nutritionist/vet.
"""

FEED_GUIDE = [
    # (min_wks, max_wks, category, kg_per_day, notes)
    (0, 4, 'pre_starter', 0.25, 'Creep feed + sow milk. Fresh water always.'),
    (4, 8, 'pre_starter', 0.50, 'Pre-starter ad lib. Introduce starter gradually.'),
    (8, 12, 'starter', 1.00, 'Starter 18-20% CP. Vitamin ADE + B-complex weekly per label.'),
    (12, 16, 'grower', 1.80, 'Grower 16-18% CP. Monitor ADG target ~0.65 kg/day.'),
    (16, 20, 'grower', 2.30, 'Grower. Increase gradually; avoid sudden feed change.'),
    (20, 26, 'finisher', 2.80, 'Finisher 14-16% CP until ~100kg market weight.'),
    (26, 999, 'finisher', 3.00, 'Hold at maintenance if past target; schedule selling.'),
]

VITAMIN_NOTES = {
    'piglet': 'Iron shot day 3 (vet protocol) + Vitamin ADE per label at weaning.',
    'weaner': 'Vitamin ADE + B-complex for 5-7 days post-weaning stress.',
    'grower': 'Monthly multivitamins; Vitamin E + Selenium per label.',
    'finisher': 'Vitamin supplement 1 week/month; stop per withdrawal guidance before sale.',
    'sow': 'Farrowing: Vitamin ADE pre-farrow; calcium support per vet.',
    'boar': 'ADE monthly; avoid over-conditioning.',
}


def suggest_feeding(hog):
    """Return dict with feed_category, kg/day, vitamin note, explanation."""
    weeks = hog.age_weeks() if hasattr(hog, 'age_weeks') else 12
    weight = float(getattr(hog, 'current_weight_kg', 0) or 0)
    # breeder overrides
    stage = getattr(hog, 'stage', 'grower')
    if stage in ('sow', 'gilt'):
        base = {'feed_category': 'gestating' if weight < 180 else 'lactating',
                'kg_per_day': 2.5 if weight < 180 else 4.5}
    elif stage == 'boar':
        base = {'feed_category': 'boar', 'kg_per_day': 2.5}
    else:
        cat, kg, note = 'grower', 1.8, ''
        for lo, hi, c, k, n in FEED_GUIDE:
            if lo <= weeks < hi:
                cat, kg, note = c, k, n
                break
        # scale slightly by weight for finisher stage
        if weight >= 80:
            kg = max(kg, 2.8)
        elif weight >= 50:
            kg = max(kg, 2.3)
        base = {'feed_category': cat, 'kg_per_day': kg, 'note': note}

    if stage in VITAMIN_NOTES:
        vitamin = VITAMIN_NOTES[stage]
    elif weeks < 8:
        vitamin = VITAMIN_NOTES['piglet']
    elif weeks < 12:
        vitamin = VITAMIN_NOTES['weaner']
    elif weeks < 20:
        vitamin = VITAMIN_NOTES['grower']
    else:
        vitamin = VITAMIN_NOTES['finisher']

    base['vitamin_plan'] = vitamin
    base['explanation'] = (
        f"Based on ~{weeks:.1f} weeks old"
        + (f" and {weight:.1f} kg" if weight else "")
        + f", suggested {base['feed_category']} at ~{base['kg_per_day']} kg/day."
    )
    return base
