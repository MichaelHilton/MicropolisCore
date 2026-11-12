"""Locate coverage products with both SwiftPM and Xcode build layouts."""

import glob
import os
import subprocess


def coverage_paths(app):
    debug = subprocess.check_output(
        ["swift", "build", "--show-bin-path"], cwd=app, text=True
    ).strip()
    binaries = []
    for bundle in sorted(glob.glob(os.path.join(debug, "*.xctest"))):
        name = os.path.basename(bundle).removesuffix(".xctest")
        binary = os.path.join(bundle, "Contents", "MacOS", name)
        if os.path.isfile(binary):
            binaries.append(binary)
    if not binaries:
        raise SystemExit("no test executables: run coverage-enabled tests first")
    return debug, binaries
