import json, os, glob
import pathlib
R = str(pathlib.Path(__file__).resolve().parent.parent)
SRC = R + r'\build\ytm-raw'
DST = R + r'\ReproductorPersonalTests\Fixtures'
DROP = {'menu', 'trackingParams', 'clickTrackingParams', 'accessibility', 'accessibilityData', 'responseContext',
        'loggingContext', 'frameworkUpdates', 'microformat', 'background', 'description', 'shareEndpoint',
        'subscriptionButton', 'moreButton', 'secondSubtitle', 'buttons', 'likeButton', 'sortFilterSubMenuRenderer',
        'musicSortFilterButtonRenderer', 'playerParams', 'queueAddEndpoint', 'targetId'}
KEEP_LISTS = {'contents': 8, 'items': 10, 'thumbnails': 3, 'continuationItems': 8, 'musicResponsiveListItemContinuation': 8}
DROP |= {'serviceEndpoint', 'defaultServiceEndpoint', 'toggledServiceEndpoint', 'defaultNavigationEndpoint'}

def has_cont(x):
    return 'continuationItemRenderer' in json.dumps(x)

def trim(n):
    if isinstance(n, dict):
        return {k: trim(v) for k, v in n.items() if k not in DROP}
    if isinstance(n, list):
        return [trim(v) for v in n]
    return n

def cut(n, key=None):
    if isinstance(n, dict):
        return {k: cut(v, k) for k, v in n.items()}
    if isinstance(n, list):
        limit = KEEP_LISTS.get(key)
        if limit and len(n) > limit and key != 'thumbnails':
            head = n[:limit]
            tail = [x for x in n[limit:] if has_cont(x)]
            n = head + tail
        elif key == 'thumbnails' and len(n) > 3:
            n = n[-3:]
        return [cut(v, key) for v in n]
    return n

for f in sorted(glob.glob(SRC + r'\ytm-*.json')):
    name = os.path.basename(f)
    d = json.load(open(f, encoding='utf-8'))
    d = cut(trim(d))
    out = json.dumps(d, ensure_ascii=False, separators=(',', ':'))
    open(DST + '\\' + name, 'w', encoding='utf-8', newline='').write(out)
    print(f'{name:40s} {os.path.getsize(f):>9} -> {len(out.encode("utf-8")):>7}')

