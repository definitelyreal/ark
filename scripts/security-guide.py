"""Compare proposed prose with a baseline; report changes without applying them."""
import argparse
import hashlib
import json
from pathlib import Path
import re

OPEN = re.compile(r'^\[(category|item)="([a-z0-9][a-z0-9._-]*)"\]$')
CLOSE = re.compile(r'^\[/(category|item)\]$')

def parse(text):
    items, stack, outside, roots = {}, [], [], []
    fence = None
    for number, line in enumerate(text.splitlines(), 1):
        stripped = line.strip()
        fenced = re.match(r'^(`{3,}|~{3,})', stripped)
        if fenced:
            mark=fenced.group(1)
            if fence is None: fence=mark
            elif mark[0]==fence[0] and len(mark)>=len(fence) and stripped==mark: fence=None
            if stack: items[stack[-1]]['lines'].append(line)
            else: outside.append(line)
            continue
        if fence:
            if stack: items[stack[-1]]['lines'].append(line)
            else: outside.append(line)
            continue
        opening=OPEN.fullmatch(stripped)
        closing=CLOSE.fullmatch(stripped)
        if opening:
            marker,key=opening.groups()
            if key in items:raise ValueError(f'Line {number}: duplicate item {key}')
            parent=stack[-1] if stack else None
            if parent and items[parent]['marker']=='item':
                raise ValueError(f'Line {number}: an item cannot contain another block; use a category')
            items[key]={'line':number,'marker':marker,'parent':parent,'children':[],'lines':[]}
            if parent:items[parent]['children'].append(key)
            else:roots.append(key)
            stack.append(key)
        elif closing:
            if not stack:raise ValueError(f'Line {number}: closing marker without an open block')
            if closing.group(1)!=items[stack[-1]]['marker']:
                raise ValueError(f'Line {number}: expected [/{items[stack[-1]]["marker"]}], found {stripped}')
            stack.pop()
        elif stripped.startswith(('[item','[/item','[category','[/category')):
            raise ValueError(f'Line {number}: malformed marker')
        elif stack:
            items[stack[-1]]['lines'].append(line)
        else:
            outside.append(line)
    if fence:raise ValueError('Unclosed code fence')
    if stack:raise ValueError('Unclosed '+items[stack[-1]]['marker']+': '+stack[-1])
    for item in items.values():
        item['text']='\n'.join(item.pop('lines')).strip()
        if not item['text']:raise ValueError(f'Line {item["line"]}: item has no content')
        item['sha256']=hashlib.sha256(item['text'].encode()).hexdigest()
    text='\n'.join(outside).strip()
    items['__document__']={'line':1,'marker':'document','parent':None,'children':roots,'text':text,'sha256':hashlib.sha256(text.encode()).hexdigest()}
    return items

def compare(baseline, proposal):
    old=parse(baseline);new=parse(proposal)
    common=old.keys() & new.keys()
    changed=sorted(k for k in common if old[k]['sha256']!=new[k]['sha256'])
    moved=sorted(k for k in common if old[k]['parent']!=new[k]['parent'] or old[k]['children']!=new[k]['children'] or old[k]['marker']!=new[k]['marker'])
    added=sorted(new.keys()-old.keys());removed=sorted(old.keys()-new.keys())
    areas=set()
    for key in changed:
        parent=new[key]['parent']
        while parent:
            areas.add(parent);parent=new[parent]['parent']
    return {'status':'review-required' if changed or moved or added or removed else 'unchanged',
            'changed_items':changed,'structure_changed':moved,'new_ids':added,'missing_ids':removed,
            'related_parent_items':sorted(areas),'publication_authorized':False,
            'note':'Review wording, related variants and prompt effects before adapting site content. No files were changed.'}

def prompts(text):
    blocks = parse(text)
    result = {}
    for key in ('prompt.basic', 'prompt.full'):
        if key not in blocks:
            raise ValueError('Missing ' + key)
        matches = re.findall(r'^```text\n(.*?)\n```$', blocks[key]['text'], re.M | re.S)
        if len(matches) != 1 or not matches[0].strip():
            raise ValueError(key + ' needs one nonempty text code block')
        result[key] = matches[0].strip()
    return result

if __name__ == '__main__':
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument('proposal', type=Path)
    cli.add_argument('--baseline', type=Path, help='Report changes from this accepted guide')
    args = cli.parse_args()
    try:
        text = args.proposal.read_text()
        extracted = prompts(text)
        result = compare(args.baseline.read_text(), text) if args.baseline else {
            'status': 'valid', 'blocks': len(parse(text)) - 1,
            'prompt_words': {key: len(value.split()) for key, value in extracted.items()},
            'publication_authorized': False}
    except (ValueError, OSError) as exc:
        raise SystemExit(str(exc))
    print(json.dumps(result, indent=2))
