"""Tests for tools/gen_shim.py.

No network: the transform is exercised on a miniature of the bundle's shim, and
the committed file is checked for the properties generation is meant to give it.
"""

import importlib.util
import unittest
from pathlib import Path

TOOLS_DIR = Path(__file__).resolve().parent.parent


def load():
    path = TOOLS_DIR / "gen_shim.py"
    spec = importlib.util.spec_from_file_location("_uut_gen_shim", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


# The lines of MedianRenkoIndicator.mqh that the renames and patches anchor on.
MINIATURE = """\
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


class Transform(unittest.TestCase):
    def setUp(self):
        self.m = load()
        self.out = self.m.transform(MINIATURE)

    def test_the_products_names_replace_the_bundles(self):
        self.assertIn("class VolumeChartIndicator", self.out)
        self.assertIn("TickChart          * tickChart;", self.out)
        self.assertIn("tickChart = new TickChart(UseOnTickChart);", self.out)
        self.assertIn("#include <AZ-INVEST/SDK/VolumeBarChart.mqh>", self.out)
        self.assertIn("CopyBuffer(handle,VOLUMECHART_OPEN,", self.out)

    def test_the_input_keeps_the_name_saved_presets_use(self):
        self.assertIn("input bool UseOnTickChart = true;", self.out)

    def test_nothing_of_the_bundles_product_survives_in_the_code(self):
        code = "\n".join(line for line in self.out.splitlines() if not line.startswith("//"))
        self.assertNotIn("enko", code)

    def test_the_reload_is_guarded(self):
        """An iCustom() instance must not switch the caller's chart."""
        self.assertIn("ReloadChartIfOwn(ChartID(), _Symbol, _Period);", self.out)
        self.assertNotIn("ChartSetSymbolPeriod(", self.out)
        self.assertIn("#include <AZ-INVEST/ChartOwnership.mqh>", self.out)

    def test_on_deinit_stays_public_api(self):
        self.assertIn("void     OnDeinit(const int reason);", self.out)
        self.assertIn("void VolumeChartIndicator::OnDeinit(const int reason)", self.out)

    def test_the_output_says_it_is_generated_and_from_what(self):
        self.assertIn("GENERATED FILE", self.out)
        self.assertIn(self.m.BUNDLE_COMMIT, self.out)

    def test_crlf_input_gives_the_same_output(self):
        self.assertEqual(self.m.transform(MINIATURE.replace("\n", "\r\n")), self.out)

    def test_a_missing_anchor_stops_generation(self):
        """A bundle refactor must fail loudly, not emit a half-renamed file."""
        broken = MINIATURE.replace("// try to force reload", "// reload")
        with self.assertRaises(self.m.ShapeChanged) as caught:
            self.m.transform(broken)
        self.assertIn("guarded reload", str(caught.exception))

    def test_a_rename_that_no_longer_occurs_stops_generation(self):
        with self.assertRaises(self.m.ShapeChanged):
            self.m.transform(MINIATURE.replace("RENKO_OPEN", "0"))


class TheCommittedShim(unittest.TestCase):
    def setUp(self):
        self.m = load()
        self.raw = self.m.TARGET.read_bytes()
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
