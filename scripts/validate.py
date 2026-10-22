#!/usr/bin/env python3
"""Validate source and rendered dotfiles without applying or running setup."""

import io
import itertools
import json
import pathlib
import subprocess
import sys
import tarfile
import tempfile
import tomllib

from validate_mise_lock import main as validate_mise_lock

ROOT = pathlib.Path(__file__).resolve().parents[1]

if validate_mise_lock():
    raise SystemExit(1)
subprocess.run([sys.executable, '-m', 'unittest', 'discover',
                '-s', str(ROOT / 'scripts'), '-p', 'test_*.py'], check=True)


def run(*args, **kwargs):
    return subprocess.run(args, check=True, **kwargs)


def shell(path, name):
    if name.endswith('.zsh') or name in ('dot_zshrc', 'dot_zprofile') or name.startswith('dot_zfunc/'):
        run('zsh', '-n', str(path))
    elif name.endswith('.sh') or name == 'modify_dot_bashrc':
        dialect = 'sh' if name in ('dot_config/shell/path.sh', 'modify_dot_bashrc') else 'bash'
        run(dialect, '-n', str(path))
        run('shellcheck', '--shell=' + dialect, str(path))


with tempfile.TemporaryDirectory(prefix='dotfiles-validation-') as directory:
    work = pathlib.Path(directory)
    config = work / 'empty.toml'
    config.write_text('')
    base = ['chezmoi', '--config', str(config), '--source', str(ROOT),
            '--destination', str(work / 'home'), '--cache', str(work / 'cache'),
            '--persistent-state', str(work / 'state.boltdb')]
    files = run('git', 'ls-files', '-z', cwd=ROOT, stdout=subprocess.PIPE).stdout.decode().split('\0')
    for name in filter(None, files):
        if not name.endswith('.tmpl'):
            shell(ROOT / name, name)
    for os_name, arch, profile in itertools.product(('darwin', 'linux'), ('amd64', 'arm64'), ('desktop', 'server')):
        print(f'Validating {os_name}/{arch}/{profile}', flush=True)
        data = {'chezmoi': {'os': os_name, 'arch': arch}, 'email': 'ci@example.invalid',
                'machineProfile': profile, 'has1password': False}
        command = base + ['--override-data', json.dumps(data)]
        for name in filter(None, files):
            if not name.endswith('.tmpl'):
                continue
            args = command + ['execute-template', '--file']
            if name == '.chezmoi.toml.tmpl':
                args += ['--init', '--promptString', 'email=ci@example.invalid',
                         '--promptChoice', 'machineProfile=' + profile]
            content = run(*args, str(ROOT / name), stdout=subprocess.PIPE).stdout
            rendered = work / pathlib.Path(name).name.removesuffix('.tmpl')
            rendered.write_bytes(content)
            shell(rendered, name.removesuffix('.tmpl'))
            if name == '.chezmoi.toml.tmpl':
                tomllib.loads(content.decode())
        # Archive renders the managed target state without applying or running scripts.
        archive = run(*command, 'archive', '--format', 'tar', stdout=subprocess.PIPE).stdout
        with tarfile.open(fileobj=io.BytesIO(archive)) as targets:
            names = {item.name.removeprefix('./') for item in targets}
            for item in targets.getmembers():
                if not item.isfile():
                    continue
                name = item.name.removeprefix('./')
                content = targets.extractfile(item).read()
                target = work / 'rendered-target'
                target.write_bytes(content)
                if name in ('.zshrc', '.zprofile') or name.startswith(('.zsh.d/', '.zfunc/')):
                    run('zsh', '-n', str(target))
                elif name == '.bashrc':
                    run('bash', '-n', str(target))
                elif name.endswith('.sh'):
                    shell(target, name.removeprefix('.').replace('config/', 'dot_config/', 1))
                if name.endswith(('.toml', '.lock')):
                    tomllib.loads(content.decode())
            assert '.zshrc' in names
            assert ('.config/kitty/kitty.conf' in names) == (os_name == 'linux' and profile == 'desktop')
            assert ('.config/mise/config.toml' in names) == (os_name == 'linux')
            assert not names.intersection({'scripts', '.github', 'AGENTS.md', 'README.md'})
        run(*command, 'managed', stdout=subprocess.DEVNULL)

for path in ROOT.glob('dot_config/**/*.toml'):
    tomllib.loads(path.read_text())
tomllib.loads((ROOT / 'dot_config/mise/mise.lock').read_text())
json.loads((ROOT / 'renovate.json').read_text())
run('git', 'diff', '--check', cwd=ROOT)
