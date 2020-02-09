#include <AZ-INVEST/SDK/CommonSettings.mqh>

#ifdef DEVELOPER_VERSION
   #define CUSTOM_CHART_NAME "TickChart_TEST"
#else
   #ifdef AMP_VERSION
      #define CUSTOM_CHART_NAME "DTA Tickchart"
   #else
      #define CUSTOM_CHART_NAME "X Tick Chart"
   #endif
#endif

//
// Tick chart specific settings
//
#ifdef SHOW_INDICATOR_INPUTS
   #ifdef MQL5_MARKET_DEMO // hardcoded values
   
      int               barSizeInTicks = 900;                     // Ticks per bar
      int               showNumberOfDays = 7;                     // Show history for number of days
      ENUM_BOOL         resetOpenOnNewTradingDay = true;          // Synchronize first bar's open on new day
   
   #else // user defined settings
   
      input int         barSizeInTicks = 610;                     // Ticks per bar
      input int         showNumberOfDays = 5;                     // Show history for number of days
      input ENUM_BOOL   resetOpenOnNewTradingDay = true;          // Synchronize first bar's open on new day
   
   #endif
#else // don't SHOW_INDICATOR_INPUTS 
      int         barSizeInTicks = 610;                           // Ticks per bar
      int         showNumberOfDays = 5;                           // Show history for number of days
      ENUM_BOOL   resetOpenOnNewTradingDay = true;                // Synchronize first bar's open on new day
#endif

//
// Remaining settings are located in the include file below.
// These are common for all custom charts
//
#include <az-invest/sdk/CustomChartSettingsBase.mqh>

struct TICKCHART_SETTINGS
{
   int         barSizeInTicks;
   int         showNumberOfDays;
   ENUM_BOOL   resetOpenOnNewTradingDay;   
};

class CTickCustomChartSettigns : public CCustomChartSettingsBase
{
   protected:
      
   TICKCHART_SETTINGS settings;

   public:
   
   CTickCustomChartSettigns();
   ~CTickCustomChartSettigns();

   TICKCHART_SETTINGS GetTickChartSettings() { return this.settings; };   
   
   virtual void SetCustomChartSettings();
   virtual string GetSettingsFileName();
   virtual uint CustomChartSettingsToFile(int handle);
   virtual uint CustomChartSettingsFromFile(int handle);
};

void CTickCustomChartSettigns::CTickCustomChartSettigns()
{
   settingsFileName = GetSettingsFileName();
}

void CTickCustomChartSettigns::~CTickCustomChartSettigns()
{
}

string CTickCustomChartSettigns::GetSettingsFileName()
{
   return CUSTOM_CHART_NAME+(string)ChartID()+".set";  
}

uint CTickCustomChartSettigns::CustomChartSettingsToFile(int file_handle)
{
   return FileWriteStruct(file_handle,this.settings);
}

uint CTickCustomChartSettigns::CustomChartSettingsFromFile(int file_handle)
{
   return FileReadStruct(file_handle,this.settings);
}

void CTickCustomChartSettigns::SetCustomChartSettings()
{
   settings.barSizeInTicks = barSizeInTicks;
   settings.showNumberOfDays = showNumberOfDays;
   settings.resetOpenOnNewTradingDay = resetOpenOnNewTradingDay;
}
