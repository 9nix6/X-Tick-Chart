"""Produce every file this repository takes from the Renko bundle, from the bundle.

The bundle (9nix6/Median-and-Turbo-Renko-indicator-bundle) is the master copy of
the shared SDK. This repository carries the same code for another product, and
until now the copies were kept in step by hand: a refactor landed in one and not
the other, the shared indicators stopped compiling against the stale half, and
nothing said so until somebody tried to build.

This script derives all of it from one pinned bundle commit. Three kinds of file:

  verbatim  -- copied byte for byte (shared SDK headers, vendored helpers, the
               ported indicators)
  selected  -- the bundle's file with this product's #define switched on in
               place of the bundle's (CustomBarConfig.mqh, the two shared EAs)
  shim      -- the bundle's MedianRenkoIndicator.mqh with this product's names
               substituted and a few declared differences (SHIM_PATCHES) applied

What stays owned here and is NOT produced by this script: the client class and
the settings class. Their indicator-name ladder, settings struct and iCustom()
argument list are the product itself.

Every substitution asserts how often it matches. When a bundle file changes
shape, the run stops and names the step, rather than writing a file that is
quietly wrong.

Run:
  python3 tools/sync_from_bundle.py            # rewrite from the pinned commit (network)
  python3 tools/sync_from_bundle.py --bundle ../Median-and-Turbo-Renko-indicator-bundle
  python3 tools/sync_from_bundle.py --check    # exit 1 if any produced file differs

To move to a newer bundle: change BUNDLE_COMMIT, run, compile, commit everything.
"""

import argparse
import io
import sys
import tarfile
import urllib.request
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

BUNDLE_REPO = "9nix6/Median-and-Turbo-Renko-indicator-bundle"
BUNDLE_COMMIT = "fef65beef00c66cbcfbbacc228604c8dfe8d1c8f"

# Everything that differs between the sibling repositories is in this block.
PRODUCT = {
    "indicators_dir": "TickChart",                    # Indicators/<this>/
    "license_define": "VOLUMECHART_LICENSE",          # CustomBarConfig.mqh
    "ea_define": "EA_ON_TICK_VOLUME_CHART",           # 2MA_Cross / PriceMA_Cross
    "shim": "VolumeChartIndicator",                   # class and file name of the shim
    "shim_version": "4.02",
    "client_header": "VolumeBarChart.mqh",            # owned here
    "client_class": "TickChart",
    "client_variable": "tickChart",
    "buffer_prefix": "VOLUMECHART_",
    "shim_input": "input bool UseOnTickChart = true; // Use this indicator with TickChart handle",
    "shim_input_name": "UseOnTickChart",
}

BOM = b"\xef\xbb\xbf"

SDK = "Include/AZ-INVEST/SDK/"
VERBATIM = [
    SDK + "CommonSettings.mqh",
    SDK + "CustomChartInputs.mqh",
    SDK + "CustomChartInputsBR.mqh",
    SDK + "CustomChartSettingsBase.mqh",
    SDK + "ICustomChartSettings.mqh",
    SDK + "Normailze.mqh",
    SDK + "RSI.mqh",
    SDK + "TimeControl.mqh",
    SDK + "TradeFunctions.mqh",
    SDK + "TradeManager.mqh",
    SDK + "TradingChecks.mqh",
    SDK + "HistoryHandler.mqh",
    SDK + "IndicatorAccess.mqh",
    "Include/Double.mqh",
    "Include/smoothalgorithms.mqh",
    "Include/IncOnRingBuffer/cadxonringbuffer.mqh",
    "Include/IncOnRingBuffer/carrayring.mqh",
    "Include/IncOnRingBuffer/catronringbuffer.mqh",
    "Include/IncOnRingBuffer/cmaonringbuffer.mqh",
]
BUNDLE_INDICATORS = "Indicators/MedianRenko/"
SHIM_SOURCE = SDK + "MedianRenkoIndicator.mqh"

# (bundle path, the define the bundle has on, the define to turn on instead).
# The trailing space on the EA defines is deliberate: EA_ON_RENKO must not match
# a longer name that starts the same way.
SELECTED = [
    ("Include/AZ-INVEST/CustomBarConfig.mqh", "ULTIMATE_RENKO_LICENSE", PRODUCT["license_define"]),
    ("Experts/2MA_Cross.mq5", "EA_ON_RENKO ", PRODUCT["ea_define"] + " "),
    ("Experts/PriceMA_Cross.mq5", "EA_ON_RENKO ", PRODUCT["ea_define"] + " "),
]

# (old, new, exact number of occurrences expected, or None for "at least one").
# Order matters: the longer names go first so the shorter ones do not eat them.
SHIM_RENAMES = [
    ("MedianRenkoIndicator", PRODUCT["shim"], None),
    ("#include <AZ-INVEST/SDK/MedianRenko.mqh>", "#include <AZ-INVEST/SDK/" + PRODUCT["client_header"] + ">", 1),
    ("input bool UseOnRenkoChart = true; // Use this indicator on Renko chart handle", PRODUCT["shim_input"], 1),
    ("UseOnRenkoChart", PRODUCT["shim_input_name"], None),
    ("MedianRenko", PRODUCT["client_class"], None),
    ("medianRenko", PRODUCT["client_variable"], None),
    ("RENKO_", PRODUCT["buffer_prefix"], None),
    ('#property version   "3.00"', '#property version   "' + PRODUCT["shim_version"] + '"', 1),
    ('Get "count" Renko MqlRates', 'Get "count" custom chart\'s MqlRates', 1),
    ("based on Renko OLHC values", "based on the custom chart's OLHC values", 1),
]

GENERATED_NOTICE = """\
//
// GENERATED FILE -- do not edit by hand.
// Source: {repo} @ {commit}
//         {path}
// Regenerate with: python3 tools/sync_from_bundle.py   (see that file for what differs and why)
//"""

# Deliberate differences from the bundle's shim, applied after the renames.
# (name, old, new) -- `old` must occur exactly once.
SHIM_PATCHES = [
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
        "#include <AZ-INVEST/SDK/" + PRODUCT["client_header"] + ">\n",
        "#include <AZ-INVEST/ChartOwnership.mqh>\n#include <AZ-INVEST/SDK/" + PRODUCT["client_header"] + ">\n",
    ),
    (
        "guarded reload",
        "ChartSetSymbolPeriod(ChartID(), _Symbol, _Period); // try to force reload",
        "ReloadChartIfOwn(ChartID(), _Symbol, _Period); // try to force reload",
    ),
    # The bundle's class declares OnDeinit() and never defines it, which only
    # compiles while nobody calls it. This product's header has always defined
    # it (a no-op), so customer indicators that call it keep linking.
    (
        "OnDeinit definition",
        "bool " + PRODUCT["shim"] + "::OnCalculate(",
        "void " + PRODUCT["shim"] + "::OnDeinit(const int reason)\n{\n}\n\nbool " + PRODUCT["shim"] + "::OnCalculate(",
    ),
]


class ShapeChanged(Exception):
    """A bundle file no longer matches what a substitution expects."""


def decode(raw):
    if raw[:2] in (b"\xff\xfe", b"\xfe\xff"):
        return raw.decode("utf-16")
    if raw[:3] == BOM:
        return raw[3:].decode("utf-8")
    return raw.decode("utf-8")


def encode(text):
    """UTF-8 with a BOM, the encoding every source here is saved in."""
    return BOM + text.encode("utf-8")


def select_define(text, bundle_define, product_define, what):
    """Comment out the bundle's define, uncomment this product's. Line ends are kept."""
    for old, new in (
        ("\n#define " + bundle_define, "\n//#define " + bundle_define),
        ("\n//#define " + product_define, "\n#define " + product_define),
    ):
        found = text.count(old)
        if found != 1:
            raise ShapeChanged(f"{what}: expected 1 occurrence of {old.strip()!r}, found {found}")
        text = text.replace(old, new)
    return text


def transform_shim(source_text):
    """The bundle's shim text -> this product's shim text. Pure; no I/O."""
    text = source_text.replace("\r\n", "\n")

    for old, new, expected in SHIM_RENAMES:
        found = text.count(old)
        if found == 0 or (expected is not None and found != expected):
            want = "at least 1" if expected is None else str(expected)
            raise ShapeChanged(f"shim rename {old!r}: expected {want} occurrence(s), found {found}")
        text = text.replace(old, new)

    notice = GENERATED_NOTICE.format(repo=BUNDLE_REPO, commit=BUNDLE_COMMIT, path=SHIM_SOURCE)
    for name, old, new in SHIM_PATCHES:
        found = text.count(old)
        if found != 1:
            raise ShapeChanged(f"shim patch {name!r}: expected 1 occurrence of {old!r}, found {found}")
        text = text.replace(old, new.replace("{notice}", notice))

    code = "\n".join(line for line in text.split("\n") if not line.startswith("//"))
    leftovers = [word for word in ("Renko", "RENKO", "renko") if word in code]
    if leftovers:
        raise ShapeChanged(f"shim: the bundle's product name survived the renames: {leftovers}")

    return text.rstrip() + "\n"


def produce(bundle):
    """{repo-relative path: bytes} for every file this repository takes from the bundle.

    `bundle` maps bundle-relative paths to bytes.
    """
    def need(path):
        if path not in bundle:
            raise ShapeChanged(f"the bundle no longer has {path}")
        return bundle[path]

    out = {}
    for path in VERBATIM:
        out[path] = need(path)

    indicators = sorted(p for p in bundle if p.startswith(BUNDLE_INDICATORS) and p.lower().endswith(".mq5"))
    if not indicators:
        raise ShapeChanged(f"the bundle has no indicators under {BUNDLE_INDICATORS}")
    for path in indicators:
        out["Indicators/" + PRODUCT["indicators_dir"] + "/" + path[len(BUNDLE_INDICATORS):]] = bundle[path]

    for path, bundle_define, product_define in SELECTED:
        out[path] = encode(select_define(decode(need(path)), bundle_define, product_define, path))

    out[SDK + PRODUCT["shim"] + ".mqh"] = encode(transform_shim(decode(need(SHIM_SOURCE))))
    return out


def strays(produced):
    """Indicators on disk that the bundle does not have -- left behind by a removal upstream."""
    folder = REPO_ROOT / "Indicators" / PRODUCT["indicators_dir"]
    on_disk = {p.relative_to(REPO_ROOT).as_posix() for p in folder.glob("*.mq5")}
    return sorted(on_disk - set(produced))


def read_bundle(bundle_dir):
    """{bundle-relative path: bytes}, from a checkout or from the pinned commit's tarball."""
    if bundle_dir:
        root = Path(bundle_dir)
        return {
            p.relative_to(root).as_posix(): p.read_bytes()
            for p in root.rglob("*")
            if p.is_file() and ".git" not in p.relative_to(root).parts
        }
    url = f"https://codeload.github.com/{BUNDLE_REPO}/tar.gz/{BUNDLE_COMMIT}"
    with urllib.request.urlopen(url, timeout=60) as response:
        payload = response.read()
    files = {}
    with tarfile.open(fileobj=io.BytesIO(payload), mode="r:gz") as archive:
        for member in archive:
            if member.isfile():
                # members are "<repo>-<sha>/<path>"
                files[member.name.split("/", 1)[1]] = archive.extractfile(member).read()
    return files


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--bundle", help="path to a checkout of the bundle (default: fetch the pinned commit)")
    parser.add_argument("--check", action="store_true", help="compare instead of writing; exit 1 on a difference")
    args = parser.parse_args(argv)

    try:
        produced = produce(read_bundle(args.bundle))
    except ShapeChanged as error:
        print(f"sync_from_bundle: {error}")
        print("The bundle changed shape. Update tools/sync_from_bundle.py to match.")
        return 1

    different = []
    for path, data in sorted(produced.items()):
        target = REPO_ROOT / path
        if not target.is_file() or target.read_bytes() != data:
            different.append(path)
    extra = strays(produced)

    if args.check:
        for path in different:
            print(f"{path}: differs from the bundle at {BUNDLE_COMMIT[:7]}")
        for path in extra:
            print(f"{path}: not in the bundle at {BUNDLE_COMMIT[:7]}")
        if different or extra:
            print("\nThese files come from the bundle. Change them there (or change")
            print("tools/sync_from_bundle.py), then run it and commit the result.")
            return 1
        print(f"{len(produced)} files match the bundle at {BUNDLE_COMMIT[:7]}.")
        return 0

    for path in different:
        target = REPO_ROOT / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(produced[path])
        print(f"wrote {path}")
    for path in extra:
        (REPO_ROOT / path).unlink()
        print(f"removed {path}")
    print(f"{len(produced)} files from {BUNDLE_REPO}@{BUNDLE_COMMIT[:7]}; {len(different)} written, {len(extra)} removed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
