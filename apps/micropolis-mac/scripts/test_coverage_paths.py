import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from types import SimpleNamespace

from coverage_paths import coverage_paths
import engine_coverage


class CoveragePathsTests(unittest.TestCase):
    def check_layout(self, names):
        with tempfile.TemporaryDirectory() as directory:
            for name in names:
                binary = Path(directory, name + ".xctest", "Contents", "MacOS", name)
                binary.parent.mkdir(parents=True)
                binary.touch()
            with patch("coverage_paths.subprocess.check_output", return_value=directory + "\n"):
                debug, binaries = coverage_paths("/example/app")
            self.assertEqual(debug, directory)
            self.assertEqual([Path(binary).name for binary in binaries], sorted(names))

    def test_combined_swiftpm_bundle(self):
        self.check_layout(["MicropolisMacPackageTests"])

    def test_separate_xcode_bundles(self):
        self.check_layout(["MicropolisMacTests", "MicropolisKitTests"])

    def test_missing_bundles_fail_instead_of_reporting_empty_coverage(self):
        with tempfile.TemporaryDirectory() as directory:
            with patch("coverage_paths.subprocess.check_output", return_value=directory):
                with self.assertRaisesRegex(SystemExit, "no test executables"):
                    coverage_paths("/example/app")

    def test_engine_runner_propagates_test_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            with patch("engine_coverage.subprocess.check_output", return_value=directory):
                with patch("engine_coverage.subprocess.run", return_value=SimpleNamespace(returncode=7)):
                    with self.assertRaises(SystemExit) as failure:
                        engine_coverage.run_tests(None)
                    self.assertEqual(failure.exception.code, 7)

    def test_engine_gate_rejects_missing_native_instrumentation(self):
        with patch("sys.argv", ["engine_coverage.py", "--check"]), \
             patch("engine_coverage.coverage_paths", return_value=("/example", ["/example/tests"])), \
             patch("engine_coverage.merge_profiles"), \
             patch("engine_coverage.line_counts", return_value={}):
            with self.assertRaisesRegex(SystemExit, "no instrumented engine lines"):
                engine_coverage.main()


if __name__ == "__main__":
    unittest.main()
