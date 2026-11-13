"""Generate Include/AZ-INVEST/SDK/VolumeChartIndicator.mqh from the Renko bundle's shim.

Why this exists: VolumeChartIndicator.mqh is a structural clone of
MedianRenkoIndicator.mqh in 9nix6/Median-and-Turbo-Renko-indicator-bundle -- the
same class with the product's names in it. The two were edited by hand, separately,
from 2021 on and drifted: a refactor landed in one and not the other, and the 64
shared indicators stopped compiling against this copy until the missing methods
were ported across. Deriving the file removes the second copy to maintain.

The output is the bundle's file at BUNDLE_COMMIT with

  * the product's names substituted (RENAMES), and
  * the few deliberate differences applied (PATCHES), each with its reason.

Every substitution and patch must match the number of times it says it does. When
the bundle's file changes shape, generation stops with the name of the step that
no longer fits rather than emitting a file that is quietly wrong.

Run:
  python3 tools/gen_shim.py                    # regenerate from the pinned commit (network)
  python3 tools/gen_shim.py --bundle ../Median-and-Turbo-Renko-indicator-bundle
  python3 tools/gen_shim.py --check            # exit 1 if the committed file differs

To move to a newer bundle: change BUNDLE_COMMIT, regenerate, compile, commit both.
"""

import argparse
import sys
import urllib.request
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
TARGET = REPO_ROOT / "Include" / "AZ-INVEST" / "SDK" / "VolumeChartIndicator.mqh"

BUNDLE_REPO = "9nix6/Median-and-Turbo-Renko-indicator-bundle"
BUNDLE_COMMIT = "fef65beef00c66cbcfbbacc228604c8dfe8d1c8f"
SOURCE_PATH = "Include/AZ-INVEST/SDK/MedianRenkoIndicator.mqh"

BOM = b"\xef\xbb\xbf"

# (old, new, exact number of occurrences expected). Order matters: the longer
# names go first so the shorter ones do not eat them.
RENAMES = [
    ("MedianRenkoIndicator", "VolumeChartIndicator", None),
    ("#include <AZ-INVEST/SDK/MedianRenko.mqh>", "#include <AZ-INVEST/SDK/VolumeBarChart.mqh>", 1),
    (
        "input bool UseOnRenkoChart = true; // Use this indicator on Renko chart handle",
        "input bool UseOnTickChart = true; // Use this indicator with TickChart handle",
        1,
    ),
    ("UseOnRenkoChart", "UseOnTickChart", None),
    ("MedianRenko", "TickChart", None),
    ("medianRenko", "tickChart", None),
    ("RENKO_", "VOLUMECHART_", None),
    ('#property version   "3.00"', '#property version   "4.02"', 1),
    ('Get "count" Renko MqlRates', 'Get "count" custom chart\'s MqlRates', 1),
    ("based on Renko OLHC values", "based on the custom chart's OLHC values", 1),
]

GENERATED_NOTICE = """\
//
// GENERATED FILE -- do not edit by hand.
// Source: {repo} @ {commit}
//         {path}
// Regenerate with: python3 tools/gen_shim.py   (see that file for what differs and why)
//
"""

# Deliberate differences from the bundle's file, applied after the renames.
# (name, old, new) -- `old` must occur exactly once.
PATCHES = [
    (
        "generated notice",
        "\n//#define DEVELOPER_VERSION\n",
        "\n{notice}\n//#define DEVELOPER_VERSION\n",
    ),
    # An instance created by iCustom() has no chart of its own: ChartID() is the
    # caller's chart while _Symbol/_Period are the indicator's. The unguarded
    # reload below would switch the caller's chart. The installer ships this guard.
    (
        "chart-ownership include",
        "#include <AZ-INVEST/SDK/VolumeBarChart.mqh>\n",
        "#include <AZ-INVEST/ChartOwnership.mqh>\n#include <AZ-INVEST/SDK/VolumeBarChart.mqh>\n",
    ),
    (
        "guarded reload",
        "ChartSetSymbolPeriod(ChartID(), _Symbol, _Period); // try to force reload",
        "ReloadChartIfOwn(ChartID(), _Symbol, _Period); // try to force reload",
    ),
    # Public since 2020 and a no-op; kept so customer indicators that call it
    # from their own OnDeinit() keep compiling. The bundle's class never had it.
    (
        "OnDeinit declaration",
        "      bool     OnCalculate(const int _rates_total,const int _prev_calculated, const datetime &_Time[], const double &_Close[]);\n",
        "      bool     OnCalculate(const int _rates_total,const int _prev_calculated, const datetime &_Time[], const double &_Close[]);\n"
        "      void     OnDeinit(const int reason);\n",
    ),
    (
        "OnDeinit definition",
        "bool VolumeChartIndicator::OnCalculate(",
        "void VolumeChartIndicator::OnDeinit(const int reason)\n{\n}\n\nbool VolumeChartIndicator::OnCalculate(",
    ),
]


class ShapeChanged(Exception):
    """The bundle's file no longer matches what a rename or patch expects."""


def decode(raw):
    if raw[:2] in (b"\xff\xfe", b"\xfe\xff"):
        return raw.decode("utf-16")
    if raw[:3] == BOM:
        return raw[3:].decode("utf-8")
    return raw.decode("utf-8")


def transform(source_text):
    """The bundle's shim text -> this product's shim text. Pure; no I/O."""
    text = source_text.replace("\r\n", "\n")

    for old, new, expected in RENAMES:
        found = text.count(old)
        if found == 0 or (expected is not None and found != expected):
            want = "at least 1" if expected is None else str(expected)
            raise ShapeChanged(f"rename {old!r}: expected {want} occurrence(s), found {found}")
        text = text.replace(old, new)

    notice = GENERATED_NOTICE.format(repo=BUNDLE_REPO, commit=BUNDLE_COMMIT, path=SOURCE_PATH)
    for name, old, new in PATCHES:
        found = text.count(old)
        if found != 1:
            raise ShapeChanged(f"patch {name!r}: expected 1 occurrence of {old!r}, found {found}")
        text = text.replace(old, new.replace("{notice}", notice.rstrip("\n")))

    leftovers = [w for w in ("Renko", "RENKO", "renko") if w in text.replace(BUNDLE_REPO, "").replace(SOURCE_PATH, "")]
    if leftovers:
        raise ShapeChanged(f"the bundle's product name survived the renames: {leftovers}")

    return text.rstrip() + "\n"


def encode(text):
    """UTF-8 with a BOM and LF line ends, as the hand-kept file was saved."""
    return BOM + text.encode("utf-8")


def read_source(bundle_dir):
    if bundle_dir:
        return decode((Path(bundle_dir) / SOURCE_PATH).read_bytes())
    url = f"https://raw.githubusercontent.com/{BUNDLE_REPO}/{BUNDLE_COMMIT}/{SOURCE_PATH}"
    with urllib.request.urlopen(url, timeout=30) as response:
        return decode(response.read())


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--bundle", help="path to a checkout of the bundle (default: fetch the pinned commit)")
    parser.add_argument("--check", action="store_true", help="compare instead of writing; exit 1 on a difference")
    args = parser.parse_args(argv)

    try:
        generated = encode(transform(read_source(args.bundle)))
    except ShapeChanged as error:
        print(f"gen_shim: {error}")
        print("The bundle's shim changed shape. Update RENAMES/PATCHES in tools/gen_shim.py to match.")
        return 1

    relative = TARGET.relative_to(REPO_ROOT)
    if args.check:
        if TARGET.read_bytes() == generated:
            print(f"{relative} matches the bundle's shim at {BUNDLE_COMMIT[:7]}.")
            return 0
        print(f"{relative} differs from what tools/gen_shim.py generates.")
        print("It is a generated file: change tools/gen_shim.py (or the bundle) and regenerate.")
        return 1

    TARGET.write_bytes(generated)
    print(f"wrote {relative} from {BUNDLE_REPO}@{BUNDLE_COMMIT[:7]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
