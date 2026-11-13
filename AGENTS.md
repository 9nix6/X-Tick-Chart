# AGENTS.md — X Tick & Volume Bar Chart (MT5 SDK + companion code)

**READ THIS FIRST.** This file is navigational: it says which file and which function to open.

## The single most important fact

**The Tick & Volume chart indicator itself is NOT in this repository.** This repo is the open-source
companion SDK to a closed-source, commercially sold MT5 indicator. The bar-building engine ships
only as a compiled `.ex5`. So "the chart isn't building" / "bars are wrong" is almost never a bug
here. What lives here is everything that *consumes* those bars:

| Layer | Where | What it is |
|---|---|---|
| Bar engine (closed source) | not in this repo | builds the bars, publishes them as indicator buffers |
| Buffer-reading client library | `Include/AZ-INVEST/SDK/VolumeBarChart.mqh` | class `TickChart`: `iCustom()` handle + `CopyBuffer()` wrappers |
| Indicator-porting shim | `Include/AZ-INVEST/SDK/VolumeChartIndicator.mqh` | makes an ordinary MT5 indicator calculate on the custom chart's OHLC |
| 64 ported indicators | `Indicators/TickChart/` | stock/community MT5 indicators patched through that shim |
| EAs | `Experts/` | robots trading off the custom bars |

## Shared code — where the source of truth is

This repo is one of several SDKs in one product line. **Most of it is not maintained here.**
The authoritative copy is `9nix6/Median-and-Turbo-Renko-indicator-bundle` (checked out alongside
as `../Median-and-Turbo-Renko-indicator-bundle`); change shared files there first, then copy.

| Files | Status |
|---|---|
| `Include/AZ-INVEST/SDK/` — `CommonSettings`, `CustomChartInputs`, `CustomChartInputsBR`, `CustomChartSettingsBase`, `ICustomChartSettings`, `Normailze`, `RSI`, `TimeControl`, `TradeFunctions`, `TradeManager`, `TradingChecks`, `HistoryHandler`, `IndicatorAccess` | **byte-identical** to the bundle |
| `Include/Double.mqh`, `Include/smoothalgorithms.mqh`, `Include/IncOnRingBuffer/` | byte-identical (vendored third-party) |
| `Indicators/TickChart/*.mq5` | byte-identical to the bundle's `Indicators/MedianRenko/` — they only talk to the global `customChartIndicator`, so they are product-agnostic |
| `Include/AZ-INVEST/CustomBarConfig.mqh` | the bundle's file with `VOLUMECHART_LICENSE` selected instead of `ULTIMATE_RENKO_LICENSE` |
| `Experts/2MA_Cross.mq5`, `PriceMA_Cross.mq5` | the bundle's files with `EA_ON_TICK_VOLUME_CHART` selected instead of `EA_ON_RENKO` |
| `tools/`, `.github/workflows/mql-build.yml` | the bundle's, with folder names and release text adapted |
| `Include/AZ-INVEST/SDK/VolumeChartIndicator.mqh` | **generated** by `tools/gen_shim.py` from the bundle's `MedianRenkoIndicator.mqh` at the commit pinned in that script — never edit it by hand |
| `Include/AZ-INVEST/ChartOwnership.mqh` | the guard the product installer ships; the generated shim uses it so an `iCustom()` instance never reloads the caller's chart |
| `VolumeBarChart.mqh`, `VolumeCustomChartSettings.mqh`, example EAs | **owned here** |

The bundle's `Include/AGENTS.md`, `Indicators/AGENTS.md` and `Experts/AGENTS.md` describe the
settings handshake, the resync state machine, the porting contract and the EA conventions. They
apply here unchanged once you read `MedianRenko` as `TickChart` and `MedianRenkoIndicator` as
`VolumeChartIndicator` — `VolumeBarChart.mqh` is a structural clone of the first, and
`VolumeChartIndicator.mqh` is generated from the second.

To change the shim: change the bundle's file (or `RENAMES`/`PATCHES` in `tools/gen_shim.py`),
move `BUNDLE_COMMIT`, run `python3 tools/gen_shim.py`, commit the script and the output together.
`Scan` runs `tools/gen_shim.py --check` and fails when the committed file is not what the
script produces.

## Editions

Two, and only two — this SDK does not serve P-Renko or any other brand:

| Customer bought | `CustomBarConfig.mqh` | Indicator path `iCustom()` asks for |
|---|---|---|
| X Tick Chart (MQL5 Market) | `MQL5_MARKET_VERSION` defined (repo default) | `Market\X Tick Chart` |
| Tick Chart & Volume Chart for MetaTrader 5 (az-invest.eu) | `MQL5_MARKET_VERSION` commented out | `TickChart` |

Resolved in the `#ifdef` ladder at the top of `Include/AZ-INVEST/SDK/VolumeBarChart.mqh`. A wrong
edition means `iCustom()` asks for an indicator that is not installed — an empty chart, no error.
The `P_RENKO_BR_PRO` branches and `CustomChartInputsBR.mqh` are present only because the files are
shared; nothing in this product uses them.

## The owned headers must match the shipped indicator

`VolumeBarChart.mqh` passes every setting positionally to `iCustom()`, and
`VolumeCustomChartSettings.mqh` defines the struct the indicator writes into the `.set` handshake file.
Both are dictated by the closed-source indicator's current inputs, not by this repo:

- A field added to the settings struct or an input added to the indicator has to be mirrored here,
  in the same position, or `iCustom()` binds values to the wrong inputs.
- `CCustomChartSettingsBase::Load()` rejects a `.set` file whose size is not
  `CustomChartSettingsSize() + sizeof(chartIndicatorSettings)`. The override in
  `VolumeCustomChartSettings.mqh` is what makes that check meaningful; without it every file is rejected.
- The installers ship their own copy of `Include/AZ-INVEST/SDK/` built from the private
  `installer-builder` repo. When the two disagree, the installer's copy is the one that matches
  the indicator binary the customer has.

## Symptom → where to look

| Customer says | Start here |
|---|---|
| "indicator won't load", "EA says indicator init failed" | edition table above; name ladder at the top of `VolumeBarChart.mqh` |
| log line `Failed to load indicator settings` | `TickChart::Init()` → `CCustomChartSettingsBase::Load()`; the indicator must be on the chart first |
| log line `settings file ... is N bytes, this build expects M` | indicator and SDK built against different settings layouts — see the section above |
| "EA works live but not in the Strategy Tester" | `SHOW_INDICATOR_INPUTS` must be `#define`d and the EA recompiled |
| "a ported indicator plots nothing / is shifted" | that indicator, against the porting contract (bundle's `Indicators/AGENTS.md`) |
| "objects/arrows are drawn at the wrong bar" | `TimeToCustomChartTime()` / `CustomChartTimeToCanvasTime()` / `CanvasXYToTimePrice()` at the tail of `VolumeChartIndicator.mqh` |
| "activation / licence" | nothing in this repo — `../AzInvestSales_Azure`, `../AzInvestProducts_Lock`, `../installer-builder` |
| trade sizing, SL/TP rejected, trailing stop | `TradeFunctions.mqh`, `TradingChecks.mqh`, `TradeManager.mqh` (shared — fix in the bundle) |

## Build & CI

- No makefile. `.mq5` compiles only in **MetaEditor** (Windows). Do not attempt a build on macOS/Linux.
- `<AZ-INVEST/...>` resolves against `<MT5 data folder>/MQL5/Include/`; the repo's `Experts/`,
  `Include/`, `Indicators/` mirror `MQL5/` one-to-one.
- **Sources only.** `.ex5` is gitignored; binaries come from CI and are attached to releases.
- **Every source is UTF-8 with a BOM** (UTF-16 is invisible to grep; BOM-less is read as ANSI by
  MetaEditor), and **includes match the on-disk spelling exactly** with forward slashes.
  `tools/check_includes.py` enforces both and resolves every include; run it and
  `python3 -m unittest discover -s tools/tests -t .` after touching any source.
- `.github/workflows/mql-build.yml`: `Scan` (hosted) → `Compile (MetaEditor)` on
  `[self-hosted, Windows, mql]`, once per edition, **warnings fail the build** → `Release` on a
  tag push or a dispatch carrying a version. Two archives per release,
  `TickChart-SDK-<version>-MQL5-Market.zip` and `TickChart-SDK-<version>-AZ-INVEST.zip`.
- The compile job needs a runner registered **for this repo** on the Windows VM (a personal
  account cannot share runners). If it sits queued, that registration is missing or lacks the
  `mql` label.

## Invariants

- Do not edit a shared file here. Change it in the bundle, then copy it over.
- Do not add licence/activation logic here.
- Do not reason about bar construction from this repo's code. It is not here.
- 91 sources, 67 programs. If those numbers move, the compile job's staged-count guard and
  `tools/tests` will say so.
