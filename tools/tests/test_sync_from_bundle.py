"""Tests for tools/sync_from_bundle.py.

No network: the transforms are exercised on miniatures of the bundle's files,
and the committed shim is checked for the properties generation gives it.
Nothing here names the product -- it is read from the script's PRODUCT block,
so the same tests serve every sibling repository.
"""

import importlib.util
import unittest
from pathlib import Path

TOOLS_DIR = Path(__file__).resolve().parent.parent


def load():
    path = TOOLS_DIR / "sync_from_bundle.py"
    spec = importlib.util.spec_from_file_location("_uut_sync_from_bundle", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


# The lines of MedianRenkoIndicator.mqh that the renames and patches anchor on.
SHIM = """\
#property copyright "Copyright 2018-2020, Level Up Software"
#property version   "3.00"

input bool UseOnRenkoChart = true; // Use this indicator on Renko chart handle

//#define DEVELOPER_VERSION
#include <AZ-INVEST/SDK/MedianRenko.mqh>

class MedianRenkoIndicator
{
   private:
      MedianRenko          * medianRenko;
   public:
      bool     OnCalculate(const int _rates_total,const int _prev_calculated, const datetime &_Time[], const double &_Close[]);
      void     OnDeinit(const int reason);
};

MedianRenkoIndicator::MedianRenkoIndicator()
{
   medianRenko = new MedianRenko(UseOnRenkoChart);
}

bool MedianRenkoIndicator::OnCalculate(const int _rates_total,const int _prev_calculated, const datetime &_Time[], const double &_Close[])
{
      ChartSetSymbolPeriod(ChartID(), _Symbol, _Period); // try to force reload
   int copied = CopyBuffer(handle,RENKO_OPEN,start,count,temp);
   return false;
}

// Get "count" Renko MqlRates into "ratesInfoArray[]" array starting from "start" bar
//  Function used for calculating the Apllied Price based on Renko OLHC values
"""

CONFIG = """\
//#define DEVELOPER_VERSION\r
#define MQL5_MARKET_VERSION\r
\r
#define ULTIMATE_RENKO_LICENSE\r
//#define RANGEBAR_LICENSE\r
//#define SECONDSCHART_LICENSE\r
//#define TICKCHART_LICENSE\r
//#define VOLUMECHART_LICENSE\r
"""

EA = """\
// SELECT ONE OF THE FOLLOWING
//#define EA_ON_RANGE_BARS          // Use EA on RangeBar chart
#define EA_ON_RENKO               // Use EA on Renko charts
//#define EA_ON_XTICK_CHART         // Use EA on XTick Chart (obsolete)
//#define EA_ON_TICK_VOLUME_CHART   // Use EA on Tick & Volume Bar Chart
//#define EA_ON_SECONDS_CHART       // Use EA on Seconds Interval chart
#ifdef EA_ON_RENKO
#endif
"""


class TransformShim(unittest.TestCase):
    def setUp(self):
        self.m = load()
        self.p = self.m.PRODUCT
        self.out = self.m.transform_shim(SHIM)

    def test_the_products_names_replace_the_bundles(self):
        p = self.p
        self.assertIn("class " + p["shim"], self.out)
        self.assertIn(f"{p['client_class']}          * {p['client_variable']};", self.out)
        self.assertIn(f"{p['client_variable']} = new {p['client_class']}({p['shim_input_name']});", self.out)
        self.assertIn(f"#include <AZ-INVEST/SDK/{p['client_header']}>", self.out)
        self.assertIn(f"CopyBuffer(handle,{p['buffer_prefix']}OPEN,", self.out)

    def test_the_input_keeps_the_name_saved_presets_use(self):
        self.assertIn(self.p["shim_input"], self.out)

    def test_nothing_of_the_bundles_product_survives_in_the_code(self):
        code = "\n".join(line for line in self.out.splitlines() if not line.startswith("//"))
        self.assertNotIn("enko", code)
        self.assertNotIn("RENKO", code)

    def test_the_reload_is_guarded(self):
        """An iCustom() instance must not switch the caller's chart."""
        self.assertIn("ReloadChartIfOwn(ChartID(), _Symbol, _Period);", self.out)
        self.assertNotIn("ChartSetSymbolPeriod(", self.out)
        self.assertIn("#include <AZ-INVEST/ChartOwnership.mqh>", self.out)

    def test_on_deinit_is_declared_once_and_defined(self):
        """The bundle declares it without a body; a second declaration is error 222."""
        self.assertEqual(self.out.count("void     OnDeinit(const int reason);"), 1)
        self.assertEqual(self.out.count(f"void {self.p['shim']}::OnDeinit(const int reason)"), 1)

    def test_the_output_says_it_is_generated_and_from_what(self):
        self.assertIn("GENERATED FILE", self.out)
        self.assertIn(self.m.BUNDLE_COMMIT, self.out)

    def test_crlf_input_gives_the_same_output(self):
        self.assertEqual(self.m.transform_shim(SHIM.replace("\n", "\r\n")), self.out)

    def test_a_missing_anchor_stops_generation(self):
        """A bundle refactor must fail loudly, not emit a half-renamed file."""
        broken = SHIM.replace("// try to force reload", "// reload")
        with self.assertRaises(self.m.ShapeChanged) as caught:
            self.m.transform_shim(broken)
        self.assertIn("guarded reload", str(caught.exception))

    def test_a_rename_that_no_longer_occurs_stops_generation(self):
        with self.assertRaises(self.m.ShapeChanged):
            self.m.transform_shim(SHIM.replace("RENKO_OPEN", "0"))


class SelectDefine(unittest.TestCase):
    def setUp(self):
        self.m = load()
        self.p = self.m.PRODUCT

    def test_the_products_licence_is_on_and_the_bundles_off(self):
        out = self.m.select_define(CONFIG, "ULTIMATE_RENKO_LICENSE", self.p["license_define"], "config")
        self.assertIn("\n//#define ULTIMATE_RENKO_LICENSE\r\n", out)
        self.assertIn("\n#define " + self.p["license_define"] + "\r\n", out)

    def test_exactly_one_licence_define_is_left_on(self):
        out = self.m.select_define(CONFIG, "ULTIMATE_RENKO_LICENSE", self.p["license_define"], "config")
        on = [line for line in out.splitlines() if line.startswith("#define ") and line.endswith("_LICENSE")]
        self.assertEqual(on, ["#define " + self.p["license_define"]])

    def test_the_edition_define_and_line_ends_are_untouched(self):
        out = self.m.select_define(CONFIG, "ULTIMATE_RENKO_LICENSE", self.p["license_define"], "config")
        self.assertIn("#define MQL5_MARKET_VERSION\r\n", out)
        self.assertEqual(out.count("\r\n"), CONFIG.count("\r\n"))

    def test_the_ea_define_moves_and_ifdefs_are_left_alone(self):
        out = self.m.select_define(EA, "EA_ON_RENKO ", self.p["ea_define"] + " ", "ea")
        self.assertIn("\n//#define EA_ON_RENKO ", out)
        self.assertIn("\n#define " + self.p["ea_define"] + " ", out)
        self.assertIn("#ifdef EA_ON_RENKO\n", out)

    def test_a_bundle_that_already_switched_stops_the_run(self):
        with self.assertRaises(self.m.ShapeChanged):
            self.m.select_define(CONFIG.replace("#define ULTIMATE", "//#define ULTIMATE"),
                                 "ULTIMATE_RENKO_LICENSE", self.p["license_define"], "config")


class Produce(unittest.TestCase):
    def setUp(self):
        self.m = load()
        self.p = self.m.PRODUCT
        self.bundle = {path: b"verbatim " + path.encode() for path in self.m.VERBATIM}
        self.bundle["Indicators/MedianRenko/RSI.mq5"] = b"rsi"
        self.bundle["Indicators/MedianRenko/AGENTS.md"] = b"not a source"
        self.bundle["Include/AZ-INVEST/CustomBarConfig.mqh"] = self.m.encode(CONFIG)
        self.bundle["Experts/2MA_Cross.mq5"] = self.m.encode(EA)
        self.bundle["Experts/PriceMA_Cross.mq5"] = self.m.encode(EA)
        self.bundle[self.m.SHIM_SOURCE] = self.m.encode(SHIM)

    def test_shared_files_are_copied_byte_for_byte(self):
        out = self.m.produce(self.bundle)
        for path in self.m.VERBATIM:
            self.assertEqual(out[path], self.bundle[path])

    def test_indicators_land_in_the_products_folder_and_only_sources(self):
        out = self.m.produce(self.bundle)
        folder = "Indicators/" + self.p["indicators_dir"] + "/"
        self.assertEqual(out[folder + "RSI.mq5"], b"rsi")
        self.assertNotIn(folder + "AGENTS.md", out)

    def test_the_owned_headers_are_never_produced(self):
        out = self.m.produce(self.bundle)
        self.assertNotIn("Include/AZ-INVEST/SDK/" + self.p["client_header"], out)
        self.assertFalse(any("MedianRenko" in path for path in out))

    def test_a_file_missing_from_the_bundle_stops_the_run(self):
        del self.bundle[self.m.VERBATIM[0]]
        with self.assertRaises(self.m.ShapeChanged):
            self.m.produce(self.bundle)


class TheCommittedShim(unittest.TestCase):
    def setUp(self):
        self.m = load()
        self.raw = (self.m.REPO_ROOT / (self.m.SDK + self.m.PRODUCT["shim"] + ".mqh")).read_bytes()
        self.text = self.m.decode(self.raw)

    def test_it_is_utf8_with_a_bom(self):
        self.assertEqual(self.raw[:3], self.m.BOM)

    def test_it_carries_the_pinned_commit(self):
        """Moving BUNDLE_COMMIT without regenerating leaves the two disagreeing."""
        self.assertIn(self.m.BUNDLE_COMMIT, self.text)

    def test_it_has_the_guard_and_no_private_itime(self):
        self.assertIn("ReloadChartIfOwn(", self.text)
        # The hand-kept file declared its own iTime(string,int,int), which
        # shadowed the built-in one inside the class.
        self.assertNotIn("::iTime(string", self.text)
        self.assertNotIn("TFMigrate", self.text)

    def test_the_header_it_includes_is_shipped(self):
        self.assertTrue((self.m.REPO_ROOT / "Include" / "AZ-INVEST" / "ChartOwnership.mqh").is_file())


if __name__ == "__main__":
    unittest.main()
