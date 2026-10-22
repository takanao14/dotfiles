#!/usr/bin/env python3
"""Regression tests for incomplete and stale Linux lock entries."""

import unittest

from validate_mise_lock import validate


class LockValidationTests(unittest.TestCase):
    def entry(self, **changes):
        return dict(version='1.2.3', specifiers=['1.2.3'], **{
            'platforms.linux-x64': {'url': 'https://example.invalid/x64'},
            'platforms.linux-arm64': {'url': 'https://example.invalid/arm64'},
        }) | changes

    def check(self, entry, request='1.2.3', name='github:owner/tool'):
        return validate({'tools': {name: request}}, {'tools': {name: [entry]}})

    def test_both_platforms_and_table_request(self):
        self.assertEqual(self.check(self.entry(), {'version': '1.2.3', 'asset_pattern': 'tool-*'}), [])

    def test_github_tag_prefix_can_be_normalized_in_version(self):
        self.assertEqual(self.check(self.entry(specifiers=['v1.2.3']), request='v1.2.3'), [])

    def test_tool_header_without_arm64_is_rejected(self):
        entry = self.entry()
        del entry['platforms.linux-arm64']
        self.assertEqual(self.check(entry), ['github:owner/tool@1.2.3: missing URL for linux-arm64'])

    def test_platform_table_without_url_is_rejected(self):
        entry = self.entry(**{'platforms.linux-x64': {}})
        self.assertIn('missing URL for linux-x64', self.check(entry)[0])

    def test_platform_options_can_split_one_version_across_entries(self):
        x64 = self.entry()
        arm64 = self.entry()
        del x64['platforms.linux-arm64']
        del arm64['platforms.linux-x64']
        x64['options'] = {'asset_pattern': 'tool-amd64.zip'}
        arm64['options'] = {'asset_pattern': 'tool-aarch64.zip'}
        config = {'tools': {'github:owner/tool': {'version': '1.2.3'}}}
        lock = {'tools': {'github:owner/tool': [x64, arm64]}}
        self.assertEqual(validate(config, lock), [])
        arm64['version'] = '1.2.2'
        self.assertEqual(validate(config, lock),
                         ['github:owner/tool@1.2.3: missing URL for linux-arm64'])

    def test_missing_and_stale_versions_are_rejected(self):
        self.assertTrue(validate({'tools': {'github:owner/tool': '1.2.3'}}, {'tools': {}}))
        self.assertTrue(self.check(self.entry(version='1.2.2')))
        self.assertTrue(self.check(self.entry(specifiers=['1.2.2'])))

    def test_pipx_needs_version_but_no_platform_tables(self):
        entry = {'version': '1.2.3', 'specifiers': ['1.2.3']}
        self.assertEqual(self.check(entry, name='pipx:tool'), [])
        self.assertTrue(self.check(entry, request='1.2.4', name='pipx:tool'))


if __name__ == '__main__':
    unittest.main()
