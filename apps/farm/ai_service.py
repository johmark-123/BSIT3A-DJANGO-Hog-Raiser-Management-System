"""Central AI service: Gemini primary, OpenRouter fallback, rules otherwise.

- Keys stay on the server (settings / env). Never expose to templates.
- AI output is advisory only: checked against safety rules, never auto-prescribes.
- Without keys, deterministic rule-based analysis still works (capstone-safe).
"""

import json
import logging
import urllib.request

from django.conf import settings

logger = logging.getLogger(__name__)

SAFETY_FOOTER = (
    '\n\nNote: This is farm-management guidance only, not a veterinary diagnosis. '
    'Consult a licensed veterinarian before giving any medicine.'
)

# Simple symptom -> possible-cause map for offline/rule-based mode.
SYMPTOM_KB = [
    (('diarrhea', 'scour', 'watery stool', 'pagtatae'),
     'Possible: bacterial scours (E. coli), viral enteritis, feed change, parasites, dirty water.',
     'needs_attention',
     'Isolate affected hog; keep clean water; disinfect pen; record duration/severity; call vet if bloody, dehydrated, or >2 days.'),
    (('cough', 'ubo', 'sneeze', 'difficulty breathing', 'hingal'),
     'Possible: respiratory infection, dust/poor ventilation, pneumonia risk.',
     'needs_attention',
     'Improve ventilation; reduce dust; separate coughing hogs; monitor temperature; call vet if labored breathing or fever.'),
    (('fever', 'lagnat', 'hot', 'matamlay'),
     'Possible: systemic infection (including ASF risk if high fever + multiple deaths — reportable).',
     'urgent',
     'Quarantine immediately; restrict farm visitors; disinfect; contact municipal vet promptly, especially with multiple cases.'),
    (('loss of appetite', 'not eating', 'eating less', 'walang gana', 'ayaw kumain'),
     'Possible: stress, heat, early infection, dental/feed issue.',
     'needs_attention',
     'Check water/feed freshness; monitor temperature; record intake daily; call vet if appetite loss >24-48h.'),
    (('vomit', 'suka', 'skin lesion', 'red skin', 'lumps', 'sugat'),
     'Possible: skin infection, mange, erysipelas, injury.',
     'needs_attention',
     'Clean/isolate; photograph lesions for vet; avoid home-dosing antibiotics; seek vet assessment.'),
    (('lameness', 'pilay', 'limp', 'swollen leg'),
     'Possible: foot injury, arthritis, flooring issue.',
     'routine',
     'Check flooring/nails; rest the hog on dry bedding; vet check if non-weight-bearing.'),
]


def _rule_analyze(symptoms_text, appetite='normal', duration_days=1, affected=1):
    text = (symptoms_text or '').lower()
    urgency_rank = {'routine': 0, 'needs_attention': 1, 'urgent': 2}
    urgency = 'routine'
    causes, steps = [], []
    for keywords, cause, urg, step in SYMPTOM_KB:
        if any(k in text for k in keywords):
            causes.append(cause)
            steps.append(step)
            if urgency_rank[urg] > urgency_rank[urgency]:
                urgency = urg
    if appetite in ('loss',):
        if urgency_rank['urgent'] > urgency_rank[urgency] and duration_days >= 2:
            urgency = 'urgent'
        elif urgency_rank['needs_attention'] > urgency_rank[urgency]:
            urgency = 'needs_attention'
        causes.append('Appetite loss often accompanies infection/stress — track intake closely.')
    if duration_days >= 3 and urgency == 'routine':
        urgency = 'needs_attention'
    if affected and affected >= 3:
        urgency = 'urgent' if urgency != 'routine' else 'needs_attention'
        causes.append('Multiple hogs affected — consider contagious cause / outbreak protocol.')
    if not causes:
        causes = ['General observation needed: could be stress, environment, or early illness. Monitor closely.']
        steps = ['Record temperature, feed/water intake, and stool; re-check in 12-24h; call vet if worsening.']
    vet = urgency in ('needs_attention', 'urgent') or duration_days >= 2 or (affected or 1) >= 2
    summary = (
        f"Reported: {symptoms_text[:220]} | appetite={appetite} | "
        f"{duration_days}d | {affected} affected. Preliminary level: {urgency}."
    )
    return {
        'urgency': urgency,
        'summary': summary,
        'possible_causes': '\n'.join(f'- {c}' for c in causes),
        'recommended_steps': '\n'.join(f'{i+1}. {s}' for i, s in enumerate(steps)) + SAFETY_FOOTER,
        'vet_referral': vet,
        'provider': 'rules',
    }


def _post_json(url, payload, headers, timeout=25):
    req = urllib.request.Request(
        url, data=json.dumps(payload).encode(),
        headers={'Content-Type': 'application/json', **headers},
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode())


def _call_gemini(prompt, system=''):
    key = getattr(settings, 'GEMINI_API_KEY', '') or ''
    if not key:
        return None
    model = getattr(settings, 'GEMINI_MODEL', 'gemini-1.5-flash')
    url = (f'https://generativelanguage.googleapis.com/v1beta/models/{model}'
           f':generateContent?key={key}')
    payload = {'contents': [{'parts': [{'text': (system + "\n\n" + prompt) if system else prompt}]}],
               'generationConfig': {'temperature': 0.4, 'maxOutputTokens': 800}}
    try:
        data = _post_json(url, payload, {})
        parts = data.get('candidates', [{}])[0].get('content', {}).get('parts', [])
        text = ' '.join(p.get('text', '') for p in parts).strip()
        return text or None
    except Exception as exc:  # noqa: BLE001 - fallback to rules
        logger.warning('Gemini call failed: %s', exc)
        return None


def _call_openrouter(prompt, system=''):
    key = getattr(settings, 'OPENROUTER_API_KEY', '') or ''
    if not key:
        return None
    url = 'https://openrouter.ai/api/v1/chat/completions'
    payload = {
        'model': getattr(settings, 'OPENROUTER_MODEL', 'meta-llama/llama-3-8b-instruct'),
        'messages': [
            {'role': 'system', 'content': system or 'You are a hog-farm assistant.'},
            {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.4,
        'max_tokens': 800,
    }
    headers = {'Authorization': f'Bearer {key}',
               'HTTP-Referer': getattr(settings, 'OPENROUTER_REFERER', 'http://localhost'),
               'X-Title': 'Hog Raiser Management System'}
    try:
        data = _post_json(url, payload, headers)
        return data['choices'][0]['message']['content'].strip()
    except Exception as exc:  # noqa: BLE001
        logger.warning('OpenRouter call failed: %s', exc)
        return None


HEALTH_SYSTEM = (
    'You are an AI Hog Health Assistant for Filipino hog raisers. '
    'Classify urgency as routine / needs_attention / urgent. '
    'List possible explanations (never a confirmed diagnosis), safe immediate precautions, '
    'and when to call a veterinarian. Never prescribe specific drug dosages. '
    'Reply in this exact format:\nURGENCY: <level>\nSUMMARY: <2 sentences>\n'
    'POSSIBLE CAUSES:\n- ...\nNEXT STEPS:\n1. ...\nVET REFERRAL: yes/no'
)


def analyze_health(symptoms, appetite='normal', duration_days=1, affected=1,
                   hog_info='', extra_context=''):
    """Return dict(urgency, summary, possible_causes, recommended_steps, vet_referral, provider)."""
    prompt = (f'Hog: {hog_info}\nSymptoms: {symptoms}\nAppetite: {appetite}\n'
              f'Duration: {duration_days} day(s)\nAffected: {affected}\nContext: {extra_context}\n'
              'Assess urgency and safe next steps.')
    text = _call_gemini(prompt, HEALTH_SYSTEM) or _call_openrouter(prompt, HEALTH_SYSTEM)
    if not text:
        return _rule_analyze(symptoms, appetite, duration_days, affected)
    # light parse of structured reply
    low = text.lower()
    urgency = 'routine'
    if 'urgent' in low:
        urgency = 'urgent'
    elif 'needs_attention' in low or 'needs attention' in low:
        urgency = 'needs_attention'
    vet = ('vet referral: yes' in low) or urgency in ('needs_attention', 'urgent')
    return {
        'urgency': urgency,
        'summary': text[:600],
        'possible_causes': text,
        'recommended_steps': text + SAFETY_FOOTER,
        'vet_referral': vet,
        'provider': 'gemini' if getattr(settings, 'GEMINI_API_KEY', '') else 'openrouter',
    }


def answer_question(question, context=''):
    prompt = f'Farmer question: {question}\nFarm context:\n{context[:2000]}'
    system = ('You answer hog-raising questions (feeding, vitamins, biosecurity, growth, costs) '
              'in English or Filipino. Be practical, cite withdrawal/vet-safety when relevant, '
              'and never prescribe medication dosages.')
    text = _call_gemini(prompt, system) or _call_openrouter(prompt, system)
    if not text:
        q = (question or '').lower()
        if any(k in q for k in ('feed', 'pakain', 'grower', 'finisher')):
            text = ('General guide: piglet pre-starter → starter (8-12 wks) → grower (12-20 wks, ~1.8-2.3 kg/day) '
                    '→ finisher (20-26 wks, ~2.8 kg/day to ~100 kg). Change feeds gradually over 5-7 days; '
                    'vitamins per label; clean water always.' + SAFETY_FOOTER)
        elif any(k in q for k in ('sick', 'sakit', 'diarrhea', 'ubo', 'fever', 'lagnat')):
            text = ('Record symptoms, appetite, duration, and affected count in Health Reports. Quarantine if fever, '
                    'diarrhea, or multiple hogs affected; keep the pen clean/dry; contact your vet promptly.' + SAFETY_FOOTER)
        else:
            text = ('I can help with feeding plans, growth tracking, health triage, medicines info, and costs. '
                    'Tell me the hog code, age/weight, and what you observe.' + SAFETY_FOOTER)
        return {'answer': text, 'provider': 'rules'}
    return {'answer': text + SAFETY_FOOTER, 'provider': 'ai'}


def summarize_farm(owner, stats):
    prompt = ('Summarize this hog farm in 6-10 bullets: totals, growth concerns, open health cases, '
              f'low/expiring stock, due care, expenses.\nData:\n{json.dumps(stats, default=str)[:3000]}')
    system = 'You write concise farm-management summaries for farmers. End with top 3 priority actions.'
    text = _call_gemini(prompt, system) or _call_openrouter(prompt, system)
    if not text:
        lines = [f"- {k}: {v}" for k, v in stats.items()]
        text = 'Farm summary (rule-based):\n' + '\n'.join(lines) + '\nPriorities: check alerts, due care, and slow-growth hogs.'
        return {'summary': text, 'provider': 'rules'}
    return {'summary': text, 'provider': 'ai'}
