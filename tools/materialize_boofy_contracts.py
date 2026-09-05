#!/usr/bin/env python3
from pathlib import Path
import hashlib
import json
import os
import sys

# Trigger revision 3: materialize the full source tree from upstream in one GitHub Actions run.
root = Path(sys.argv[1] if len(sys.argv) > 1 else '.').resolve()

PROTECTED = '__BOOFY_EXTERNAL_ADDRESSBOOK_SCOPE__'


def in_workflows(p: Path) -> bool:
    try:
        rel = p.relative_to(root)
    except Exception:
        return False
    return len(rel.parts) >= 2 and rel.parts[0] == '.github' and rel.parts[1] == 'workflows'


def rebrand_text(text: str) -> str:
    out = []
    for line in text.splitlines(keepends=True):
        low = line.lower()
        # Preserve upstream legal/source attribution exactly.
        if '@author' in low or 'copyright' in low:
            out.append(line)
            continue
        if 'blockchain-addressbook' in low:
            line = line.replace('beefyfinance', PROTECTED).replace('BeefyFinance', PROTECTED).replace('BEEFYFINANCE', PROTECTED)
        line = line.replace('BEEFY', 'BOOFY').replace('Beefy', 'Boofy').replace('beefy', 'boofy')
        line = line.replace(PROTECTED, 'beefyfinance')
        out.append(line)
    return ''.join(out)


# Rebrand text files. Binary files and workflow files are left untouched here.
for p in list(root.rglob('*')):
    if not p.is_file() or '.git' in p.parts or in_workflows(p):
        continue
    if p.name in {'LICENSE', 'LICENSE.md', 'COPYING', 'NOTICE'}:
        continue
    try:
        raw = p.read_bytes()
        text = raw.decode('utf-8')
    except Exception:
        continue
    new = rebrand_text(text)
    if new != text:
        p.write_text(new, encoding='utf-8')

# Rename files/directories from deepest path first, excluding workflows.
paths = [p for p in root.rglob('*') if '.git' not in p.parts and not in_workflows(p)]
for p in sorted(paths, key=lambda x: len(x.parts), reverse=True):
    name = p.name.replace('BEEFY', 'BOOFY').replace('Beefy', 'Boofy').replace('beefy', 'boofy')
    if name != p.name and p.exists():
        dest = p.with_name(name)
        if not dest.exists():
            p.rename(dest)

# Normalize package metadata and keep the published upstream address-book dependency.
pkg = root / 'package.json'
if pkg.exists():
    try:
        data = json.loads(pkg.read_text(encoding='utf-8'))
        data['name'] = 'boofy-contracts'
        deps = data.get('dependencies', {})
        if '__PROTECTED_EXTERNAL_BOOFY_0__' in deps:
            deps['@beefyfinance/blockchain-addressbook'] = deps.pop('__PROTECTED_EXTERNAL_BOOFY_0__')
        data['dependencies'] = deps
        pkg.write_text(json.dumps(data, indent=2) + '\n', encoding='utf-8')
    except Exception:
        pass

# Repair any protected dependency placeholders that may appear in scripts/config.
for p in root.rglob('*'):
    if not p.is_file() or '.git' in p.parts or in_workflows(p):
        continue
    try:
        text = p.read_text(encoding='utf-8')
    except Exception:
        continue
    fixed = text.replace('__PROTECTED_EXTERNAL_BOOFY_0__', '@beefyfinance/blockchain-addressbook')
    if fixed != text:
        p.write_text(fixed, encoding='utf-8')

team = '''# Boofy Development Team\n\n- **Fan Long** — Co-Founder\n- **David Woo** — Developer\n- **Tyler Casselman** — Developer\n- **Albert Jones** — Developer\n\nThese names identify the current Boofy fork/rebrand team and do not replace upstream authorship, copyright, or license attribution.\n'''
(root / 'BOOFY_TEAM.md').write_text(team, encoding='utf-8')

migration = '''# Boofy Migration Notice\n\nThis repository is a Boofy fork/rebrand of upstream open-source software. Original license, copyright, and author attribution must be preserved.\n\nExisting blockchain addresses, transaction hashes, token symbols, pool IDs, treasury/governance/multisig values, and other on-chain deployment data are **not automatically Boofy deployments**. Replace them only with verified Boofy values before production use.\n\nThe external published dependency `@beefyfinance/blockchain-addressbook` is intentionally preserved until a compatible Boofy package is published and verified.\n'''
(root / 'BOOFY_MIGRATION_NOTICE.md').write_text(migration, encoding='utf-8')

finalization = '''# Boofy Contracts Finalization\n\nProject: **Boofy Contracts**\n\nSelected brand direction: **Geometric / Tech — Concept 4**.\n\n## Team\n- Fan Long — Co-Founder\n- David Woo — Developer\n- Tyler Casselman — Developer\n- Albert Jones — Developer\n\n## Deployment boundary\nRebranding does not create or verify blockchain deployments. Upstream addresses, transaction hashes, token symbols, pool IDs, fee recipients, treasury, governance, timelock, and multisig values must be replaced only with verified Boofy production values. Legally required upstream attribution is retained.\n'''
(root / 'BOOFY_FINALIZATION.md').write_text(finalization, encoding='utf-8')

(root / 'BOOFY_REBRAND_REPORT.md').write_text(
    '# Boofy Rebrand Report\n\nThe source tree was rebranded case-sensitively from Beefy naming to Boofy naming while preserving legal attribution and the external `@beefyfinance/blockchain-addressbook` dependency.\n',
    encoding='utf-8'
)

branding = root / 'branding'
branding.mkdir(exist_ok=True)
(branding / 'README.md').write_text(
    '# Boofy Branding\n\nOfficial direction: **Geometric / Tech (Concept 4)**. Token-icon PNG assets are maintained separately from the source materialization step.\n',
    encoding='utf-8'
)

# Add a team pointer to the main readme if not already present.
for readme_name in ('README.md', 'readme.md'):
    rp = root / readme_name
    if rp.exists():
        txt = rp.read_text(encoding='utf-8', errors='ignore')
        if 'BOOFY_TEAM.md' not in txt:
            rp.write_text(txt.rstrip() + '\n\n## Boofy Development Team\nSee [BOOFY_TEAM.md](./BOOFY_TEAM.md).\n', encoding='utf-8')
        break

# Generate integrity manifest last (excluding itself and .git).
manifest = root / 'BOOFY_FILE_MANIFEST.sha256'
rows = []
for p in sorted(root.rglob('*')):
    if not p.is_file() or '.git' in p.parts or p == manifest:
        continue
    h = hashlib.sha256(p.read_bytes()).hexdigest()
    rows.append(f'{h}  {p.relative_to(root).as_posix()}')
manifest.write_text('\n'.join(rows) + '\n', encoding='utf-8')

print(f'Materialized Boofy Contracts tree at {root}')
