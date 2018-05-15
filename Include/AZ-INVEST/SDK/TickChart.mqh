#property copyright "Copyright 2018, AZ-iNVEST"
#property link      "http://www.az-invest.eu"

//#define TICKCHART_INDICATOR_NAME "TickChart\\TickChart213"
#define TICKCHART_INDICATOR_NAME "Market\\X Tick Chart" 

#define TICKCHART_OPEN            00
#define TICKCHART_HIGH            01
#define TICKCHART_LOW             02
#define TICKCHART_CLOSE           03 
#define TICKCHART_BAR_COLOR       04
#define TICKCHART_MA1             05
#define TICKCHART_MA2             06
#define TICKCHART_MA3             07
#define TICKCHART_CHANNEL_HIGH    08
#define TICKCHART_CHANNEL_MID     09
#define TICKCHART_CHANNEL_LOW     10
#define TICKCHART_BAR_OPEN_TIME   11
#define TICKCHART_TICK_VOLUME     12
#define TICKCHART_REAL_VOLUME     13
#define TICKCHART_BUY_VOLUME      14
#define TICKCHART_SELL_VOLUME     15
#define TICKCHART_BUYSELL_VOLUME  16

#include <AZ-INVEST/SDK/TickChartSettings.mqh>

class TickChart
{
   private:
   
      TickChartSettings * tickChartSettings;

      //
      //  Median renko indicator handle
      //
      
      int tickChartHandle;
      string tickChartSymbol;
      bool usedByIndicatorOnTickChart;
   
   public:
      
      TickChart();   
      TickChart(bool isUsedByIndicatorOnTickChart);
      TickChart(string symbol);
      ~TickChart(void);
      
      int Init();
      void Deinit();
      bool Reload();
      
      int GetHandle(void) { return tickChartHandle; };
      bool GetMqlRates(MqlRates &ratesInfoArray[], int start, int count);
      bool GetBuySellVolumeBreakdown(double &buy[], double &sell[], double &buySell[], int start, int count);      
      bool GetMA1(double &MA[], int start, int count);
      bool GetMA2(double &MA[], int start, int count);
      bool GetMA3(double &MA[], int start, int count);
      bool GetDonchian(double &HighArray[], double &MidArray[], double &LowArray[], int start, int count);
      bool GetBollingerBands(double &HighArray[], double &MidArray[], double &LowArray[], int start, int count);
      bool GetSuperTrend(double &SuperTrendHighArray[], double &SuperTrendArray[], double &SuperTrendLowArray[], int start, int count); 
      
      bool IsNewBar();
      
   private:

      bool GetChannel(double &HighArray[], double &MidArray[], double &LowArray[], int start, int count);
      int GetIndicatorHandle(void);
};

TickChart::TickChart(void)
{
   tickChartSettings = new TickChartSettings();
   tickChartHandle = INVALID_HANDLE;
   tickChartSymbol = _Symbol;
   usedByIndicatorOnTickChart = false;
}

TickChart::TickChart(bool isUsedByIndicatorOnTickChart)
{
   tickChartSettings = new TickChartSettings();
   tickChartHandle = INVALID_HANDLE;
   tickChartSymbol = _Symbol;
   usedByIndicatorOnTickChart = isUsedByIndicatorOnTickChart;
}

TickChart::TickChart(string symbol)
{
   tickChartSettings = new TickChartSettings();
   tickChartHandle = INVALID_HANDLE;
   tickChartSymbol = symbol;
   usedByIndicatorOnTickChart = false;
}

TickChart::~TickChart(void)
{
   if(tickChartSettings != NULL)
      delete tickChartSettings;
}

//
//  Function for initializing the median renko indicator handle
//

int TickChart::Init()
{
   if(!MQLInfoInteger((int)MQL5_TESTING))
   {
      if(usedByIndicatorOnTickChart) 
      {
         //
         // Indicator on Tick Chart uses the values of the TickChart for calculations
         //      
         
         IndicatorRelease(tickChartHandle);
         
         tickChartHandle = GetIndicatorHandle();
         return tickChartHandle;
      }
   
      if(!tickChartSettings.Load())
      {
         if(tickChartHandle != INVALID_HANDLE)
         {
            // could not read new settings - keep old settings
            
            return tickChartHandle;
         }
         else
         {
            Print("Failed to load indicator settings - XTickChart indicator not on chart");
            return INVALID_HANDLE;
         }
      }   
      
      if(tickChartHandle != INVALID_HANDLE)
         Deinit();

   }
   else
   {
      if(usedByIndicatorOnTickChart)
      {
         //
         // Indicator on Tick Chart uses the values of the TickChart for calculations
         //      
         tickChartHandle = GetIndicatorHandle();
         return tickChartHandle;      
      }
      else
      {     
         #ifdef SHOW_INDICATOR_INPUTS
            //
            //  Load settings from EA inputs
            //
            tickChartSettings.Load();
         #else
            //
            //  Save indicator inputs for use by EA attached to same chart.
            //
            tickChartSettings.Save();
         #endif
      }
   }   

   TICKCHART_SETTINGS s = tickChartSettings.GetTickChartSettings();         
   CHART_INDICATOR_SETTINGS cis = tickChartSettings.GetChartIndicatorSettings(); 

   //tickChartSettings.Debug();
   
   tickChartHandle = iCustom(this.tickChartSymbol,_Period,TICKCHART_INDICATOR_NAME, 
                                       s.barSizeInTicks,
                                       s.showNumberOfDays,
                                       s.resetOpenOnNewTradingDay,
                                       TopBottomPaddingPercentage,
                                       showPivots,
                                       pivotPointCalculationType,
                                       RColor,
                                       PColor,
                                       SColor,
                                       PDHColor,
                                       PDLColor,
                                       PDCColor,   
                                       showCurrentBarOpenTime,
                                       InfoTextColor,
                                       NewBarAlert,
                                       ReversalBarAlert,
                                       MaCrossAlert,
                                       UseAlertWindow,
                                       UseSound,    
                                       UsePushNotifications,
                                       SoundFileBull,
                                       SoundFileBear,
                                       cis.MA1on, 
                                       cis.MA1period,
                                       cis.MA1method,
                                       cis.MA1applyTo,
                                       cis.MA1shift,
                                       cis.MA2on,
                                       cis.MA2period,
                                       cis.MA2method,
                                       cis.MA2applyTo,
                                       cis.MA2shift,
                                       cis.MA3on,
                                       cis.MA3period,
                                       cis.MA3method,
                                       cis.MA3applyTo,
                                       cis.MA3shift,
                                       cis.ShowChannel,
                                       "",
                                       cis.DonchianPeriod,
                                       cis.BBapplyTo,
                                       cis.BollingerBandsPeriod,
                                       cis.BollingerBandsDeviations,
                                       cis.SuperTrendPeriod,
                                       cis.SuperTrendMultiplier,
                                       "",
                                       DisplayAsBarChart,
                                       UsedInEA,
                                       false);

      
    if(tickChartHandle == INVALID_HANDLE)
    {
      Print("XTickChart indicator init failed on error ",GetLastError());
    }
    else
    {
      Print("XTickChart indicator init OK");
    }
     
    return tickChartHandle;
}

//
// Function for reloading the TickChart indicator if needed
//

bool TickChart::Reload()
{
   if(tickChartSettings.Changed())
   {
      if(Init() == INVALID_HANDLE)
         return false;
      
      return true;
   }
   
   return false;
}

//
// Function for releasing the TickChart indicator handle - free resources
//

void TickChart::Deinit()
{
   if(tickChartHandle == INVALID_HANDLE)
      return;
      
   if(!usedByIndicatorOnTickChart)
   {
      if(IndicatorRelease(tickChartHandle))
         Print("XTickChart indicator handle released");
      else 
         Print("Failed to release XTickChart indicator handle");
   }
}

//
// Function for detecting a new TickChart bar
//

bool TickChart::IsNewBar()
{
   MqlRates currentBar[1];
   static datetime prevBarTime;
   
   GetMqlRates(currentBar,0,1);
   
   if(currentBar[0].time == 0)
      return false;
   
   if(prevBarTime < currentBar[0].time)
   {
      prevBarTime = currentBar[0].time;
      return true;
   }

   return false;}

//
// Get "count" Renko MqlRates into "ratesInfoArray[]" array starting from "start" bar  
//

bool TickChart::GetMqlRates(MqlRates &ratesInfoArray[], int start, int count)
{
   double o[],l[],h[],c[],barColor[],time[],tick_volume[],real_volume[];

   if(ArrayResize(o,count) == -1)
      return false;
   if(ArrayResize(l,count) == -1)
      return false;
   if(ArrayResize(h,count) == -1)
      return false;
   if(ArrayResize(c,count) == -1)
      return false;
   if(ArrayResize(barColor,count) == -1)
      return false;
   if(ArrayResize(time,count) == -1)
      return false;
   if(ArrayResize(tick_volume,count) == -1)
      return false;
   if(ArrayResize(real_volume,count) == -1)
      return false;

  
   if(CopyBuffer(tickChartHandle,TICKCHART_OPEN,start,count,o) == -1)
      return false;
   if(CopyBuffer(tickChartHandle,TICKCHART_LOW,start,count,l) == -1)
      return false;
   if(CopyBuffer(tickChartHandle,TICKCHART_HIGH,start,count,h) == -1)
      return false;
   if(CopyBuffer(tickChartHandle,TICKCHART_CLOSE,start,count,c) == -1)
      return false;
   if(CopyBuffer(tickChartHandle,TICKCHART_BAR_OPEN_TIME,start,count,time) == -1)
      return false;
   if(CopyBuffer(tickChartHandle,TICKCHART_BAR_COLOR,start,count,barColor) == -1)
      return false;
   if(CopyBuffer(tickChartHandle,TICKCHART_TICK_VOLUME,start,count,tick_volume) == -1)
      return false;
   if(CopyBuffer(tickChartHandle,TICKCHART_REAL_VOLUME,start,count,real_volume) == -1)
      return false;

   if(ArrayResize(ratesInfoArray,count) == -1)
      return false; 

   int tempOffset = count-1;
   for(int i=0; i<count; i++)
   {
      ratesInfoArray[tempOffset-i].open = o[i];
      ratesInfoArray[tempOffset-i].low = l[i];
      ratesInfoArray[tempOffset-i].high = h[i];
      ratesInfoArray[tempOffset-i].close = c[i];
      ratesInfoArray[tempOffset-i].time = (datetime)time[i];
      ratesInfoArray[tempOffset-i].tick_volume = (long)tick_volume[i];
      ratesInfoArray[tempOffset-i].real_volume = (long)real_volume[i];
      ratesInfoArray[tempOffset-i].spread = (int)barColor[i];
   }
   
   ArrayFree(o);
   ArrayFree(l);
   ArrayFree(h);
   ArrayFree(c);
   ArrayFree(barColor);
   ArrayFree(time);
   ArrayFree(tick_volume);   
   ArrayFree(real_volume);  
   
   return true;
}
bool TickChart::GetBuySellVolumeBreakdown(double &buy[], double &sell[], double &buySell[], int start, int count)
{
   double b[],s[],bs[];
   
   if(ArrayResize(b,count) == -1)
      return false;
   if(ArrayResize(s,count) == -1)
      return false;
   if(ArrayResize(bs,count) == -1)
      return false;

   if(CopyBuffer(tickChartHandle,TICKCHART_BUY_VOLUME,start,count,b) == -1)
      return false;
   if(CopyBuffer(tickChartHandle,TICKCHART_SELL_VOLUME,start,count,s) == -1)
      return false;
   if(CopyBuffer(tickChartHandle,TICKCHART_BUYSELL_VOLUME,start,count,bs) == -1)
      return false;

   if(ArrayResize(buy,count) == -1)
      return false; 
   if(ArrayResize(sell,count) == -1)
      return false; 
   if(ArrayResize(buySell,count) == -1)
      return false; 

   int tempOffset = count-1;
   for(int i=0; i<count; i++)
   {
      buy[tempOffset-i] = b[i];
      sell[tempOffset-i] = s[i];
      buySell[tempOffset-i] = bs[i];
   }
   
   ArrayFree(b);
   ArrayFree(s);
   ArrayFree(bs);
   
   return true;


}

//
// Get "count" MovingAverage1 values into "MA[]" array starting from "start" bar  
//

bool TickChart::GetMA1(double &MA[], int start, int count)
{
   double tempMA[];
   if(ArrayResize(tempMA,count) == -1)
      return false;

   if(ArrayResize(MA,count) == -1)
      return false;
   
   if(CopyBuffer(tickChartHandle,TICKCHART_MA1,start,count,tempMA) == -1)
      return false;

   for(int i=0; i<count; i++)
   {
      MA[count-1-i] = tempMA[i];
   }

   ArrayFree(tempMA);      
   return true;
}

//
// Get "count" MovingAverage2 values into "MA[]" starting from "start" bar  
//

bool TickChart::GetMA2(double &MA[], int start, int count)
{
   double tempMA[];
   if(ArrayResize(tempMA,count) == -1)
      return false;

   if(ArrayResize(MA,count) == -1)
      return false;
   
   if(CopyBuffer(tickChartHandle,TICKCHART_MA2,start,count,tempMA) == -1)
      return false;
   
   for(int i=0; i<count; i++)
   {
      MA[count-1-i] = tempMA[i];
   }
   
   ArrayFree(tempMA);   
   return true;
}

//
// Get "count" MovingAverage3 values into "MA[]" starting from "start" bar  
//

bool TickChart::GetMA3(double &MA[], int start, int count)
{
   double tempMA[];
   if(ArrayResize(tempMA,count) == -1)
      return false;

   if(ArrayResize(MA,count) == -1)
      return false;
   
   if(CopyBuffer(tickChartHandle,TICKCHART_MA3,start,count,tempMA) == -1)
      return false;
   
   for(int i=0; i<count; i++)
   {
      MA[count-1-i] = tempMA[i];
   }
   
   ArrayFree(tempMA);   
   return true;
}

//
// Get "count" Renko Donchian channel values into "HighArray[]", "MidArray[]", and "LowArray[]" arrays starting from "start" bar  
//

bool TickChart::GetDonchian(double &HighArray[], double &MidArray[], double &LowArray[], int start, int count)
{
   return GetChannel(HighArray,MidArray,LowArray,start,count);
}

//
// Get "count" Bollinger band values into "HighArray[]", "MidArray[]", and "LowArray[]" arrays starting from "start" bar  
//

bool TickChart::GetBollingerBands(double &HighArray[], double &MidArray[], double &LowArray[], int start, int count)
{
   return GetChannel(HighArray,MidArray,LowArray,start,count);
}

//
// Get "count" SuperTrend values into "HighArray[]", "MidArray[]", and "LowArray[]" arrays starting from "start" bar  
//

bool TickChart::GetSuperTrend(double &SuperTrendHighArray[], double &SuperTrendArray[], double &SuperTrendLowArray[], int start, int count)
{
   return GetChannel(SuperTrendHighArray,SuperTrendArray,SuperTrendLowArray,start,count);
}


//
// Private function used by GetRenkoDonchian and GetRenkoBollingerBands functions to get data
//

bool TickChart::GetChannel(double &HighArray[], double &MidArray[], double &LowArray[], int start, int count)
{
   double tempH[], tempM[], tempL[];

   if(ArrayResize(tempH,count) == -1)
      return false;
   if(ArrayResize(tempM,count) == -1)
      return false;
   if(ArrayResize(tempL,count) == -1)
      return false;

   if(ArrayResize(HighArray,count) == -1)
      return false;
   if(ArrayResize(MidArray,count) == -1)
      return false;
   if(ArrayResize(LowArray,count) == -1)
      return false;
   
   if(CopyBuffer(tickChartHandle,TICKCHART_CHANNEL_HIGH,start,count,tempH) == -1)
      return false;
   if(CopyBuffer(tickChartHandle,TICKCHART_CHANNEL_MID,start,count,tempM) == -1)
      return false;
   if(CopyBuffer(tickChartHandle,TICKCHART_CHANNEL_LOW,start,count,tempL) == -1)
      return false;
   
   int tempOffset = count-1;
   for(int i=0; i<count; i++)
   {
      HighArray[tempOffset-i] = tempH[i];
      MidArray[tempOffset-i] = tempM[i];
      LowArray[tempOffset-i] = tempL[i];
   }   
   
   ArrayFree(tempH);
   ArrayFree(tempM);
   ArrayFree(tempL);
   
   return true;
}

int TickChart::GetIndicatorHandle(void)
{
   int i = ChartIndicatorsTotal(0,0);
   int j=0;
   string iName;
   
   while(j < i)
   {
      iName = ChartIndicatorName(0,0,j);
      if(StringFind(iName,CUSTOM_CHART_NAME) != -1)
      {
         Print("Using handle of "+iName);
         return ChartIndicatorGet(0,0,iName);   
      }   
      j++;
   }
   
   Print("Failed getting handle of "+CUSTOM_CHART_NAME);
   return INVALID_HANDLE;
}
