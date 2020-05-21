# X-Tick-Chart
MQL5 header files for 'X Tick Chart' indicator available for MT5 via MQL5 Market. The files lets you easily create a TickChart based EA in MT5.
The created EA will automatically acquire the settings used on the tick chart it is applied to, so it is not required to clone the indicator's settings 
used on the chart to the XTickChart settings that should be used in the EA.

## The files
**TickChart.mqh** - The header file for including in the EA code. It contains the definition and implementation of the TickChart class

**CommonSettings.mqh**, **TickChartSettings.mqh**, **CustomChartSettingsBase.mqh**, **ICustomChartSettings** & **CustomChartInputs.mqh**  - These header files are used by the **TickChart** class to automatically read the EA settings used on the tick chart where the EA should be attached.

**TickChartIndicator.mqh** - This helper header file includes a **TickChartIndicator** class which is used to patch MQL5 indicators to work directly on the tick charts and use the tick chart's OLHC values for calculation.

## Installation

All folders (Experts, Include & Indicators) & sub-folders should be placed in the **MQL5** sub-folder of your Metatrader's Data Folder.
**All indicator and EA files need to be recompiled**.

Please always grab the latest release from https://github.com/9nix6/X-Tick-Chart/releases

## Resources
The **X Tick Chart** indicator for MT5 can be downloaded from https://www.mql5.com/en/market/product/24312

## Disclaimer:

All of the EAs and indicators presented in this repository are solely for educational and informational purposes and should not be regarded as advice or an invitation to trade. 
Application of the techniques, ideas, and suggestions presented in the videos and files of this repository is done at the user’s sole discretion and risk. 
