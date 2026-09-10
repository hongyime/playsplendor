"""Check shell argument boundaries with fake Java tools; no games or sockets run."""

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class ShellRunnerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='splendor runner ')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / 'test').mkdir()
        shutil.copyfile(ROOT / 'test/run_tests.sh', self.root / 'test/run_tests.sh')
        for name in ['test/with space/Fixture.java', 'test/com/splendor/network/NetworkFixture.java']:
            target = self.root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text('class Fixture {}\n', encoding='utf-8')
        binary = self.root / 'bin'
        binary.mkdir()
        scripts = {
            'javac': '#!/usr/bin/env bash\nprintf "%s\\n" "$@" >> "$SPLENDOR_ARGS_DIR/compiler.txt"\n',
            'java': '#!/usr/bin/env bash\nprintf "%s\\n" "$@" > "$SPLENDOR_ARGS_DIR/java.txt"\nexit "${SPLENDOR_JAVA_EXIT:-0}"\n',
        }
        for name, content in scripts.items():
            target = binary / name
            target.write_text(content, encoding='utf-8', newline='\n')
            target.chmod(0o755)
        self.env = {**os.environ, 'PATH': str(binary) + os.pathsep + os.environ['PATH'], 'SPLENDOR_ARGS_DIR': self.root.as_posix()}
        self.bash = str(Path(os.environ.get('ProgramFiles', r'C:\Program Files')) / 'Git/bin/bash.exe') if os.name == 'nt' else shutil.which('bash')

    def run_runner(self, *args, java_exit=0):
        env = {**self.env, 'SPLENDOR_JAVA_EXIT': str(java_exit)}
        return subprocess.run([self.bash, 'test/run_tests.sh', *args], cwd=self.root, env=env, capture_output=True, text=True, timeout=15)

    def captured(self, name):
        path = self.root / name
        return path.read_text(encoding='utf-8').splitlines() if path.exists() else []

    def test_spaces_in_source_paths_remain_one_argument(self):
        result = self.run_runner()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('test/with space/Fixture.java', self.captured('compiler.txt'))

    def test_default_excludes_network_compilation_and_execution(self):
        self.run_runner()
        self.assertFalse(any('NetworkFixture' in value for value in self.captured('compiler.txt')))
        self.assertIn('com.splendor.network', self.captured('java.txt'))

    def test_network_flag_is_explicit_opt_in(self):
        result = self.run_runner('--include-network')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('test/com/splendor/network/NetworkFixture.java', self.captured('compiler.txt'))
        self.assertNotIn('com.splendor.network', self.captured('java.txt'))

    def test_exclusion_regex_is_passed_literally(self):
        expression = 'com[.]splendor[.](network|integration)'
        result = self.run_runner('--exclude-package', expression, '--class', 'com.splendor.Fixture')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(expression, self.captured('java.txt'))
        self.assertIn('com.splendor.Fixture', self.captured('java.txt'))

    def test_missing_selector_value_fails_before_compilation(self):
        result = self.run_runner('--class')
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.captured('compiler.txt'))

    def test_junit_failure_exit_is_preserved(self):
        result = self.run_runner(java_exit=7)
        self.assertEqual(result.returncode, 7)


if __name__ == '__main__':
    unittest.main()
