#!/usr/bin/env python3
"""Line coverage of the C++ engine (packages/micropolis-engine/src and native).

Run from apps/micropolis-mac:

    scripts/engine_coverage.py --run          # run the tests with coverage, then report
    scripts/engine_coverage.py --run --filter ToolTests   # quick look while working
    scripts/engine_coverage.py                # report from the last coverage run
    scripts/engine_coverage.py --show tool.cpp   # list the uncovered lines of one file
    scripts/engine_coverage.py --check        # exit 1 unless every line is covered

An uncovered line counts as covered when its source line carries the marker
`// coverage: unreachable (<reason>)`, or when it lies between a line marked
`// coverage: unreachable-begin (<reason>)` and one marked
`// coverage: unreachable-end`. Use the markers only for code no input can
reach, never for code that is merely hard to test.
"""

import argparse
import glob
import os
import re
import subprocess
import sys

APP = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENGINE = os.path.normpath(os.path.join(APP, "..", "..", "packages", "micropolis-engine"))
DEBUG = os.path.join(APP, ".build", "out", "Products", "Debug")
PROFDATA = os.path.join(APP, ".build", "engine-coverage.profdata")
BINARIES = [
    os.path.join(DEBUG, "MicropolisMacTests.xctest", "Contents", "MacOS", "MicropolisMacTests"),
    os.path.join(DEBUG, "MicropolisKitTests.xctest", "Contents", "MacOS", "MicropolisKitTests"),
]
MARK = "// coverage: unreachable"
BEGIN = "// coverage: unreachable-begin"
END = "// coverage: unreachable-end"


def run_tests(test_filter):
    for old in glob.glob(os.path.join(DEBUG, "codecov", "*.profraw")):
        os.remove(old)
    command = ["swift", "test", "--enable-code-coverage"]
    if test_filter:
        command += ["--filter", test_filter]
    # A failing test still writes its profile, so the report goes ahead regardless.
    result = subprocess.run(command, cwd=APP)
    if result.returncode != 0:
        print("warning: swift test failed; coverage below is from a failing run", file=sys.stderr)


def merge_profiles():
    raws = glob.glob(os.path.join(DEBUG, "codecov", "*.profraw"))
    if not raws:
        sys.exit("no coverage data: run with --run first")
    subprocess.run(["xcrun", "llvm-profdata", "merge", "-sparse", *raws, "-o", PROFDATA], check=True)


def line_counts():
    """{engine-relative path: {line: hit count}} for every executable engine line."""
    cmd = ["xcrun", "llvm-cov", "export", "-format=lcov", "-skip-functions",
           BINARIES[0], "-object", BINARIES[1], "-instr-profile", PROFDATA,
           os.path.join(ENGINE, "src"), os.path.join(ENGINE, "native")]
    out = subprocess.run(cmd, check=True, capture_output=True, text=True).stdout
    files, current = {}, None
    for line in out.splitlines():
        if line.startswith("SF:"):
            path = os.path.realpath(line[3:])
            current = os.path.relpath(path, ENGINE) if path.startswith(ENGINE) else None
            if current is not None:
                files.setdefault(current, {})
        elif line.startswith("DA:") and current is not None:
            number, count = line[3:].split(",")[:2]
            lines = files[current]
            lines[int(number)] = lines.get(int(number), 0) + int(count)
    return files


def excluded_lines(path):
    with open(os.path.join(ENGINE, path), errors="replace") as f:
        source = f.read().splitlines()
    excluded, inside = set(), False
    for number, text in enumerate(source, start=1):
        if BEGIN in text:
            inside = True
        if inside or (MARK in text and BEGIN not in text and END not in text):
            excluded.add(number)
        if END in text:
            inside = False
    return excluded, source


def summarize(files):
    rows, total, missed_total = [], 0, 0
    for path, lines in sorted(files.items()):
        excluded, source = excluded_lines(path)
        missed = sorted(n for n, c in lines.items() if c == 0 and n not in excluded)
        rows.append((path, len(lines), missed, source))
        total += len(lines)
        missed_total += len(missed)
    return rows, total, missed_total


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--run", action="store_true", help="run swift test with coverage first")
    parser.add_argument("--filter", help="with --run, run only the tests matching this filter")
    parser.add_argument("--show", metavar="FILE", help="list uncovered lines of files whose path contains FILE")
    parser.add_argument("--check", action="store_true", help="exit 1 unless the engine is fully covered")
    args = parser.parse_args()

    if args.run:
        run_tests(args.filter)
    elif args.filter:
        parser.error("--filter needs --run")
    merge_profiles()
    rows, total, missed_total = summarize(line_counts())

    if args.show:
        for path, _, missed, source in rows:
            if args.show in path:
                print(f"== {path}: {len(missed)} uncovered lines")
                for n in missed:
                    print(f"{path}:{n}: {source[n - 1].rstrip()}")
        return

    print(f"{'file':34} {'lines':>6} {'missed':>7} {'cover':>8}")
    for path, count, missed, _ in sorted(rows, key=lambda r: -len(r[2])):
        cover = 100.0 * (count - len(missed)) / count if count else 100.0
        print(f"{path:34} {count:6} {len(missed):7} {cover:7.2f}%")
    cover = 100.0 * (total - missed_total) / total
    print(f"{'TOTAL':34} {total:6} {missed_total:7} {cover:7.2f}%")

    if args.check and missed_total:
        sys.exit(1)


if __name__ == "__main__":
    main()
