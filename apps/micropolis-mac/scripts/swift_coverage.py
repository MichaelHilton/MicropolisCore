#!/usr/bin/env python3
"""Report Swift coverage from SwiftPM's merged profile.

Run from apps/micropolis-mac:

    scripts/swift_coverage.py --run
    scripts/swift_coverage.py

SwiftPM writes ``default.profdata`` after a successful coverage-enabled test
run. Use that file rather than merging the raw profiles: the raw merge can
omit Swift Testing counters and falsely report all application code as 0%.
"""

import argparse
import json
import os
import subprocess
import sys


APP = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEBUG = os.path.join(APP, ".build", "out", "Products", "Debug")
PROFILE = os.path.join(DEBUG, "codecov", "default.profdata")
BINARIES = [
    os.path.join(DEBUG, "MicropolisMacTests.xctest", "Contents", "MacOS", "MicropolisMacTests"),
    os.path.join(DEBUG, "MicropolisKitTests.xctest", "Contents", "MacOS", "MicropolisKitTests"),
]
KNOWN_COVERED = os.path.join(APP, "Sources", "MicropolisMac", "GameModel.swift")


def coverage_command(format_name):
    return [
        "xcrun", "llvm-cov", "export" if format_name == "json" else "report",
        BINARIES[0], "-object", BINARIES[1], "-instr-profile", PROFILE,
        "-ignore-filename-regex", r"\.build|Tests/",
        *( ["-format=text"] if format_name == "json" else [] ),
    ]


def verify_profile():
    if not os.path.exists(PROFILE):
        sys.exit("no merged SwiftPM profile: run scripts/swift_coverage.py --run first")
    missing = [path for path in BINARIES if not os.path.exists(path)]
    if missing:
        sys.exit("missing test executable(s): " + ", ".join(missing))

    result = subprocess.run(coverage_command("json"), check=True, capture_output=True, text=True)
    report = json.loads(result.stdout)
    for item in report["data"][0]["files"]:
        if os.path.realpath(item["filename"]) == os.path.realpath(KNOWN_COVERED):
            covered = item["summary"]["lines"]["covered"]
            if covered:
                return
            break
    sys.exit("coverage error: GameModel.swift has no covered lines; refusing a misleading report")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--run", action="store_true", help="run the complete test suite with coverage first")
    args = parser.parse_args()

    if args.run:
        subprocess.run(["swift", "test", "--enable-code-coverage"], cwd=APP, check=True)
    verify_profile()
    subprocess.run(coverage_command("report"), check=True)


if __name__ == "__main__":
    main()
