#!/usr/bin/env python3
"""Generate README tables and an academic project page from the method registry.

Uses the Python standard library. Optional exports prepare a static preview or
an additive Jekyll overlay; neither writes to an existing personal homepage.
"""
import argparse
from html import escape
import json
from pathlib import Path
import re
import shutil
from urllib.parse import quote, unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]


def read_json(name):
    return json.loads((ROOT / name).read_text())


def replace_block(text, name, body):
    pattern = rf"(<!-- {name}:START -->).*?(<!-- {name}:END -->)"
    text, count = re.subn(pattern, lambda m: m[1] + '\n' + body + '\n' + m[2], text, flags=re.S)
    if count != 1:
        raise ValueError(f'Expected one generated {name} block')
    return text


def web_markdown(text, source, project):
    """Keep downloaded notes usable after moving them out of the repository."""
    ref = 'v' + project['version'] if project['repository_published'] else 'main'
    def target_url(target, image=False):
        target = target.strip('<>')
        parts = urlsplit(target)
        if parts.scheme or parts.netloc:
            return target
        path = (source.parent / unquote(parts.path)).resolve() if parts.path else source
        relative = path.relative_to(ROOT).as_posix()
        if not path.exists():
            raise ValueError(f'Missing link in {source.relative_to(ROOT)}: {target}')
        kind = 'raw' if image else ('tree' if path.is_dir() else 'blob')
        url = f"{project['repository_url']}/{kind}/{ref}/{quote(relative, safe='/')}"
        return url + ('#' + parts.fragment if parts.fragment else '')
    chunks = re.split(r'(```.*?```|~~~.*?~~~)', text, flags=re.S)
    for i in range(0, len(chunks), 2):
        chunks[i] = re.sub(
            r'(!?\[[^\]\n]*\]\()(<[^>\n]+>|[^)\n]+)(\))',
            lambda m: m[1] + target_url(m[2], m[1].startswith('!')) + m[3], chunks[i])
        chunks[i] = re.sub(
            r'(\b(?:src|href)=")([^"]+)(")',
            lambda m: m[1] + target_url(m[2], m[1].startswith('src')) + m[3], chunks[i])
    return ''.join(chunks)


def build(check=False, preview=None, personal=None):
    project = read_json('registry/project.json')
    registry = read_json('registry/reproductions.json')
    labels = read_json('registry/method-display.json')
    papers = {p['id']: p for p in read_json('registry/papers.json')['papers']}
    validation = read_json('docs/validation/matlab-tests.json')
    baseline = dict(registry['baseline'], directory='', fulltext_card='docs/METHOD_CONTRACTS.zh-CN.md')
    methods = [baseline] + registry['methods']
    if {m['id'] for m in methods} != set(labels):
        raise ValueError('Display labels must match the implemented method registry')
    if sum(m['recorded_tests'] for m in methods) != validation['total']:
        raise ValueError('Recorded method counts and validation total differ')
    skill_count = len(list((ROOT / '.agents/skills').glob('*/SKILL.md')))
    tables, html_rows, public_methods = {}, [], []
    materials = {
        'getting-started.md':'docs/GETTING_STARTED.md', 'readme-zh.md':'README.zh-CN.md',
        'validation.md':'VALIDATION.md', 'matlab-tests.csv':'docs/validation/matlab-tests.csv',
        'baseline-trajectory.csv':'docs/assets/data/baseline-trajectory.csv',
        'baseline-convergence.csv':'docs/assets/data/baseline-convergence.csv',
        'baseline-summary.json':'docs/assets/data/baseline-summary.json',
        'contributing.md':'CONTRIBUTING.md', 'roadmap.md':'docs/ROADMAP.md',
        'CITATION.cff':'CITATION.cff', 'third-party.md':'THIRD_PARTY.md',
        'implemented-api.md':'docs/IMPLEMENTED_API.md',
        'experiment-records.md':'docs/EXPERIMENT_RECORDS.md',
        'figure-data.json':'docs/assets/data/figure-data.json'
    }
    for lang in ('en', 'zh'):
        table = ['| Method / source | Model & learning | Tests | Implemented scope |', '|---|---|---:|---|'] if lang == 'en' else ['| 方法 / 来源 | 模型与学习机制 | 测试 | 实际复现范围 |', '|---|---|---:|---|']
        for m in methods:
            label = labels[m['id']]
            paper = papers.get(m.get('paper_id'), {})
            url = 'https://doi.org/' + paper['doi'] if paper.get('doi') else paper.get('source_url')
            folder = m['directory'] or 'docs/GETTING_STARTED.md'
            source = f"[{label['venue']}]({url})" if url else label['venue']
            table.append(f"| [{label['name_' + lang]}]({folder}) · {source} | {label['model_' + lang]} | {m['recorded_tests']} | {label['scope_' + lang]} |")
            if lang != 'en':
                continue
            mid, name = escape(m['id']), escape(label['name_en'])
            paper_link = f'<a href="{escape(url, quote=True)}">{escape(label["venue"])}</a>' if url else escape(label['venue'])
            summary_row = f'<tr class="method-summary"><th scope="row" id="label-{mid}">{name}<small>{paper_link}</small></th><td data-label="Problem">{escape(label["model_en"])}</td><td data-label="Example">{escape(label["example_en"])}</td><td><button type="button" class="method-toggle" aria-expanded="false" aria-controls="panel-{mid}" aria-label="Run and details: {name}">Run &amp; details</button></td></tr>'
            command = f"demo_reproductions( ...\n    '{m['id']}');"
            training = ''
            if m['id'] == 'pinn_infinite_horizon2025':
                command = "demo_reproductions( ...\n    'pinn_infinite_horizon2025', ...\n    'smoke');"
                training = '<p>The smoke mode runs a short neural-training workflow. Use <code>reduced</code> for the recorded reduced-scale procedure; the full paper training schedule is not bundled as a reproduced result.</p>'
            elif m['id'] == 'safe_pinn_icml2025':
                command = "outputDir = fullfile( ...\n    pwd, 'runs', 'safe_pinn_icml2025');\ndemo_reproductions( ...\n    'safe_pinn_icml2025', ...\n    outputDir, 5000);"
                training = '<p>This command runs 5,000 neural-training updates and evaluates the boat example. Author-checkpoint evaluation uses a separately obtained asset.</p>'
            entry_source = Path(m['directory']) / (m['entry_point'] + '.m')
            if not (ROOT / entry_source).is_file():
                raise ValueError(f'Missing native entry source: {entry_source}')
            materials[f"code/{m['entry_point']}.m.txt"] = entry_source.as_posix()
            materials[f"notes/{m['id']}.md"] = m['fulltext_card']
            products = ', '.join(m.get('required_products', ['MATLAB']))
            if m.get('optional_products'):
                products += '; optional: ' + ', '.join(m['optional_products'])
            source_url = f'@@MATERIALS@@/code/{m["entry_point"]}.m.txt'
            card_url = f'@@MATERIALS@@/notes/{m["id"]}.md'
            record_suffix = Path(label['record_path']).suffix
            record_key = f"records/{m['id']}{record_suffix}"
            materials[record_key] = label['record_path']
            content = f'''<div class="method-content" aria-labelledby="label-{mid}">
<p>{escape(label['scope_en'])}</p><p class="method-outcome">{escape(label['outcome_en'])}</p><dl class="method-facts"><div><dt>Products</dt><dd>{escape(products)}</dd></div><div><dt>Native function</dt><dd><code>{escape(m['entry_point'])}</code></dd></div><div><dt>Local checks</dt><dd>{m['recorded_tests']} recorded passing tests</dd></div></dl>{training}
<div class="code-block"><div class="code-toolbar"><span>Run from the repository root</span><button type="button" data-copy="code-{mid}">Copy</button></div><pre id="code-{mid}"><code>{escape(command)}</code></pre><p class="copy-status" role="status" aria-live="polite"></p></div>
<p class="material-links"><a href="{source_url}">Entry source (.m)</a><a href="{card_url}" download>Equation notes (.md)</a><a href="@@MATERIALS@@/{record_key}" download>Experiment &amp; checks ({record_suffix})</a>{('<a href="' + escape(url, quote=True) + '">Original paper</a>') if url else ''}</p></div>'''
            html_rows.append(f'<tbody class="method-group" id="method-{mid}">{summary_row}<tr class="method-panel" id="panel-{mid}" hidden><td colspan="4">{content}</td></tr></tbody>')
            public_methods.append({'id':m['id'],'name':label['name_en'],'venue':label['venue'],'paper_url':url,'tests':m['recorded_tests'],'scope':label['scope_en'],'entry_point':m['entry_point']})
        tables[lang] = '\n'.join(table)
    status_en = '' if project['repository_published'] else ' Public source release is in preparation.'
    status_zh = '' if project['repository_published'] else '公开源码发布仍在准备中。'
    snapshot_en = f"**v{project['version']}:** {len(methods)} runnable entries · {len(registry['methods'])} paper packages · {validation['passed']}/{validation['total']} local tests passed · {skill_count} research skills. Tested on {validation['matlab']} ({validation['platform']}).{status_en}"
    snapshot_zh = f"**v{project['version']}：** {len(methods)}个可运行入口 · {len(registry['methods'])}个论文实现包 · 本地测试{validation['passed']}/{validation['total']}通过 · {skill_count}个研究skill。实际环境：{validation['matlab']}（{validation['platform']}）。{status_zh}"
    generated = {}
    for name, snapshot in [('README.md',snapshot_en),('README.zh-CN.md',snapshot_zh)]:
        lang = 'en' if name == 'README.md' else 'zh'
        generated[name] = replace_block(replace_block((ROOT/name).read_text(), 'METHODS', tables[lang]), 'SNAPSHOT', snapshot)
    methods_doc = '# Methods and current scope\n\nThis table is generated from the implemented-method registry.\n\n' + tables['en'].replace('](reproductions/', '](../reproductions/').replace('](docs/', '](')
    methods_doc += '\n\n## Native entry points\n\n| ID | Entry | Required products | Equation map |\n|---|---|---|---|\n'
    for m in methods:
        products = ', '.join(m.get('required_products', ['MATLAB']))
        if m.get('optional_products'):
            products += '; optional: ' + ', '.join(m['optional_products'])
        methods_doc += f"| `{m['id']}` | `{m['entry_point']}` | {products} | [Method card](../{m['fulltext_card']}) |\n"
    methods_doc += '\nFull training, local mathematical tests and matching a paper’s figures are different records. See [VALIDATION](../VALIDATION.md).\n'
    generated['docs/METHODS.md'] = methods_doc
    body = (ROOT/'website/body.html').read_text()
    values = {'TEST_COUNT':validation['passed'],'ENTRY_COUNT':len(methods),'PAPER_COUNT':len(registry['methods']), 'SOURCE_VERSION':project['matlab_source_version'],
              'PROJECT_VERSION':project['version'], 'LICENSE':project['license'],
              'RELEASE_STATUS':'Published' if project['repository_published'] else 'In preparation',
              'METHOD_ROWS':'\n'.join(html_rows)}
    for key, value in values.items():
        body = body.replace('@@' + key + '@@', str(value))
    layout = (ROOT/'website/layout.html').read_text()
    repository_url = escape(project['repository_url'], quote=True)
    archive_url = repository_url + '/archive/refs/tags/v' + project['version'] + '.zip'
    public_source = (f'<a class="source-link" href="{repository_url}">GitHub code <span aria-hidden="true">↗</span></a>'
                     f'<a class="source-link" href="{archive_url}">Download ZIP <span aria-hidden="true">↓</span></a>') if project['repository_published'] else ''
    public_start = (f'Download the <a href="{archive_url}">v{project["version"]} source</a> or clone the <a href="{repository_url}">GitHub repository</a>. Open its root folder in MATLAB and run the commands alongside.'
                    if project['repository_published'] else 'The public source release is in preparation. The commands alongside show the shared workflow used by the reference.')
    def fill_body(asset_prefix):
        return body.replace('@@RESOURCE_LINKS@@',public_source).replace('@@START_INSTRUCTION@@',public_start).replace('@@MATERIALS@@',asset_prefix+'/materials').replace('@@ASSETS@@',asset_prefix)
    def render(content, asset_prefix):
        return layout.replace('@@CONTENT@@',content).replace('@@ASSETS@@',asset_prefix).replace('@@PAGE_METADATA@@','<meta name="robots" content="noindex,nofollow">').replace('@@HOME_URL@@',project['maintainer']['homepage']).replace('@@FAVICON_URL@@',project['maintainer']['homepage']+'assets/img/visit.png')
    generated['website/rendered/index.html'] = render(fill_body('assets/adp-project'),'assets/adp-project')
    assets = {'project.css':ROOT/'website/project.css','project.js':ROOT/'website/project.js'}
    for filename in ['adp-control-hero.svg','adp-control-hero-mobile.svg','adp-control-hero.pdf','adp-control-hero-source.zip','example-linear.svg','example-koopman.svg','example-pinn.svg','example-figures.zip']:
        assets[filename] = ROOT/'docs/assets'/filename
    assets.update({'materials/'+key:ROOT/value for key,value in materials.items()})
    stale = []
    for name, content in generated.items():
        path = ROOT/name
        if not path.exists() or path.read_text() != content:
            stale.append(name)
            if not check:
                path.parent.mkdir(parents=True,exist_ok=True);path.write_text(content)
    for name, source in assets.items():
        target = ROOT/'website/rendered/assets/adp-project'/name
        if not source.is_file():
            raise ValueError(f'Missing project asset: {source.relative_to(ROOT)}')
        expected = generated.get(str(source.relative_to(ROOT)))
        data = expected.encode() if expected is not None else source.read_bytes()
        if name.startswith('materials/') and source.suffix == '.md':
            data = web_markdown(data.decode(), source, project).encode()
        if not target.exists() or target.read_bytes() != data:
            stale.append(str(target.relative_to(ROOT)))
            if not check:
                target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
    if check:
        if stale:
            raise SystemExit('Generated files are stale: ' + ', '.join(stale))
        print('README tables, project page and downloadable materials are current.')
        return
    if preview:
        preview.mkdir(parents=True,exist_ok=True)
        (preview/'index.html').write_text(render(fill_body('assets/adp-project'),'assets/adp-project'))
        shutil.copytree(ROOT/'website/rendered/assets',preview/'assets',dirs_exist_ok=True)
    if personal:
        def put(name,content):
            p=personal/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(content)
        prefix="{{ '/assets/adp-project' | relative_url }}"
        native_layout=layout.replace('@@CONTENT@@','{{ content }}').replace('@@ASSETS@@',prefix).replace('@@PAGE_METADATA@@','<link rel="canonical" href="https://tanjunkai2001.github.io/projects/adp-matlab/">').replace('@@HOME_URL@@',"{{ '/' | relative_url }}").replace('@@FAVICON_URL@@',"{{ '/assets/img/visit.png' | relative_url }}")
        put('_layouts/adp_project.html',native_layout)
        put('projects/adp-matlab.html','---\nlayout: adp_project\ntitle: ADP-MATLAB\npermalink: /projects/adp-matlab/\n---\n'+fill_body(prefix)+'\n')
        put('_data/adp_project.json',json.dumps({'project':project,'methods':public_methods},ensure_ascii=False,indent=2)+'\n')
        for name,source in assets.items():
            target=personal/'assets/adp-project'/name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/'website/rendered/assets/adp-project'/name,target)
    print(f'Built {len(methods)} method entries, two READMEs and the academic project page.')


if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check',action='store_true')
    parser.add_argument('--preview-dir',type=Path)
    parser.add_argument('--personal-site-dir',type=Path)
    args=parser.parse_args()
    build(args.check,args.preview_dir,args.personal_site_dir)
