#!/usr/bin/env python3
"""Check that every configured Linux tool has a usable lock entry."""

import pathlib
import sys
import tomllib

ROOT = pathlib.Path(__file__).resolve().parents[1]
PLATFORMS = ('linux-x64', 'linux-arm64')


def validate(config, lock):
    errors = []
    for name, request in config.get('tools', {}).items():
        version = request.get('version') if isinstance(request, dict) else request
        entries = lock.get('tools', {}).get(name, [])
        matches = [entry for entry in entries
                   if version in entry.get('specifiers', [])
                   and entry.get('version', '').removeprefix('v') == version.removeprefix('v')]
        if not matches:
            errors.append(f'{name}@{version}: missing matching lock entry')
            continue
        # pipx locks the package version without platform-specific artifacts.
        if name.startswith('pipx:'):
            continue
        for platform in PLATFORMS:
            if not any(entry.get(f'platforms.{platform}', {}).get('url') for entry in matches):
                errors.append(f'{name}@{version}: missing URL for {platform}')
    return errors


def main():
    directory = ROOT / 'dot_config/mise'
    config = tomllib.loads((directory / 'config.toml').read_text())
    lock = tomllib.loads((directory / 'mise.lock').read_text())
    errors = validate(config, lock)
    if errors:
        print('Invalid Linux mise lockfile:\n' + '\n'.join(errors), file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
