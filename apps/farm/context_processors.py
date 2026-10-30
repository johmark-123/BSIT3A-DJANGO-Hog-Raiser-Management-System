"""Template context for the floating farm chat widget."""

from .models import Hog


def chat_widget(request):
    match = getattr(request, 'resolver_match', None)
    if not match or match.namespace != 'farm':
        return {'chat_widget_enabled': False}
    hogs = Hog.objects.exclude(status__in=['sold', 'deceased']).order_by('code')
    return {
        'chat_widget_enabled': True,
        'chat_hogs': [
            {
                'id': hog.id,
                'code': hog.code,
                'label': f'{hog.code} - {hog.name}' if hog.name else hog.code,
            }
            for hog in hogs[:200]
        ],
    }
