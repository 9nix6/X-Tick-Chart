#include <AZ-INVEST/SDK/CommonSettings.mqh>

#ifdef USE_LICENSE
   #ifdef DEVELOPER_VERSION
      #define CUSTOM_CHART_NAME "TickChart_TEST"
   #else
      #ifdef AMP_VERSION
         #define CUSTOM_CHART_NAME "DTA Tickchart"
      #else
         #define CUSTOM_CHART_NAME "Volume bar chart"
      #endif
   #endif
#else 
   #ifdef VOLUMECHART_LICENSE
      #define CUSTOM_CHART_NAME "Volume bar chart"
   #else
      #ifdef DEVELOPER_VERSION
         #define CUSTOM_CHART_NAME "VolumeChart_TEST"
      #else
         #define CUSTOM_CHART_NAME "Volume bar chart"
      #endif
   #endif 
#endif

//
// Volume chart specific settings
//
#ifdef SHOW_INDICATOR_INPUTS
   #ifdef MQL5_MARKET_DEMO // hardcoded values

      // FUTURE TODO IF NEEDED   
   
   #else // user defined settings
   
      input int                           barSizeInVolume = 1000;              // Bar size
      input ENUM_VOLUME_CHART_CALCULATION algorithm = VOLUME_CHART_USE_TICKS;  // Operating mode
      input int                           showNumberOfDays = 5;                // Show history for number of days
      input ENUM_BOOL                     resetOpenOnNewTradingDay = true;     // Synchronize first bar's open on new day
   
   #endif
#else // don't SHOW_INDICATOR_INPUTS 
      int         barSizeInVolume = 1000;                                  // Bar size
      ENUM_VOLUME_CHART_CALCULATION algorithm = VOLUME_CHART_USE_TICKS;    // Operating mode 
      int         showNumberOfDays = 5;                                    // Show history for number of days
      ENUM_BOOL   resetOpenOnNewTradingDay = true;                         // Synchronize first bar's open on new day
#endif

//
// Remaining settings are located in the include file below.
// These are common for all custom charts
//
#include <az-invest/sdk/CustomChartSettingsBase.mqh>

struct VOLUMECHART_SETTINGS
{
   int                           barSizeInVolume;
   ENUM_VOLUME_CHART_CALCULATION algorithm;
   int                           showNumberOfDays;
   ENUM_BOOL                     resetOpenOnNewTradingDay;   
};

class CVolumeCustomChartSettigns : public CCustomChartSettingsBase
{
   protected:
      
   VOLUMECHART_SETTINGS settings;

   public:
   
   CVolumeCustomChartSettigns();
   ~CVolumeCustomChartSettigns();

   VOLUMECHART_SETTINGS GetVolumeChartSettings() { return this.settings; };   
   
   virtual void SetCustomChartSettings();
   virtual string GetSettingsFileName();
   virtual uint CustomChartSettingsToFile(int handle);
   virtual uint CustomChartSettingsFromFile(int handle);
};

void CVolumeCustomChartSettigns::CVolumeCustomChartSettigns()
{
   settingsFileName = GetSettingsFileName();
}

void CVolumeCustomChartSettigns::~CVolumeCustomChartSettigns()
{
}

string CVolumeCustomChartSettigns::GetSettingsFileName()
{
   return CUSTOM_CHART_NAME+(string)ChartID()+".set";  
}

uint CVolumeCustomChartSettigns::CustomChartSettingsToFile(int file_handle)
{
   return FileWriteStruct(file_handle,this.settings);
}

uint CVolumeCustomChartSettigns::CustomChartSettingsFromFile(int file_handle)
{
   return FileReadStruct(file_handle,this.settings);
}

void CVolumeCustomChartSettigns::SetCustomChartSettings()
{
   settings.barSizeInVolume = barSizeInVolume;
   settings.algorithm = algorithm;
   settings.showNumberOfDays = showNumberOfDays;
   settings.resetOpenOnNewTradingDay = resetOpenOnNewTradingDay;
}
