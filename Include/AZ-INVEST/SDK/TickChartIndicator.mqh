#property copyright "Copyright 2018-2020, Level Up Software"
#property link      "http://www.az-invest.eu"
#property version   "4.00"

input bool UseOnTickChart = true; // Use this indicator with TickChart handle

#include <AZ-INVEST/SDK/TickChart.mqh>

class TickChartIndicator
{
   private: 
   
      TickChart          * tickChart;
      int                  rates_total;
      int                  prev_calculated;
      bool                 getVolumes;
      bool                 getVolumeBreakdown;
      bool                 getTime;
      bool                 useAppliedPrice;
      ENUM_APPLIED_PRICE   applied_price;
      
      bool                 firstRun;
      bool                 dataReady;
      
      datetime             prevTime;
      int                  prevRatesTotal;
      
   public:
      
      datetime Time[];
      double   Open[];
      double   Low[];
      double   High[];
      double   Close[];
      double   Price[];
      long     Tick_volume[];
      long     Real_volume[];
      double   Buy_volume[];
      double   Sell_volume[];
      double   BuySell_volume[];

      datetime GetTime(int index) { return GetArrayValueDateTime(Time, index); };
      double   GetOpen(int index) { return GetArrayValueDouble(Open, index); };
      double   GetLow(int index) { return GetArrayValueDouble(Low, index); };
      double   GetHigh(int index) { return GetArrayValueDouble(High, index); };
      double   GetClose(int index) { return GetArrayValueDouble(Close, index); };
      double   GetPrice(int index) { return GetArrayValueDouble(Price, index); };
      long     GetTick_volume(int index) { return GetArrayValueLong(Tick_volume, index); };
      long     GetReal_volume(int index) { return GetArrayValueLong(Real_volume, index); };
      double   GetBuy_volume(int index)  { return GetArrayValueDouble(Buy_volume, index); };
      double   GetSell_volume(int index) { return GetArrayValueDouble(Sell_volume, index); };
      double   GetBuySell_volume(int index) { return GetArrayValueDouble(BuySell_volume, index); };
   
   
      bool     IsNewBar;
   
               TickChartIndicator();
               ~TickChartIndicator();
               
      void     SetUseAppliedPriceFlag(ENUM_APPLIED_PRICE _applied_price) { this.useAppliedPrice = true; this.applied_price = _applied_price; };
      void     SetGetVolumesFlag() { this.getVolumes = true; };
      void     SetGetVolumeBreakdownFlag() { this.getVolumeBreakdown = true; };
      void     SetGetTimeFlag() { this.getTime = true; };
      
      bool     OnCalculate(const int rates_total,const int prev_calculated, const datetime &_Time[]);
      void     OnDeinit(const int reason);
      int      GetPrevCalculated() { return prev_calculated; };     
      int      GetRatesTotal() { return ArraySize(Open); };     
      void     BufferShiftLeft(double &buffer[]);
            
   private:
  
      bool  CheckStatus();
      bool  NeedsReload();
      int   GetOLHC(int start, int count);
      int   GetOLHCForIndicatorCalc(double &o[],double &l[],double &h[],double &c[],datetime &t[],long &tickVolume[],long &realVolume[], double &buyVolume[], double &sellVolume[], double &buySellVolume[], int start, int count);
      int   GetOLHCAndApplPriceForIndicatorCalc(double &o[],double &l[],double &h[],double &c[],datetime &t[],long &tickVolume[],long &realVolume[], double &buyVolume[], double &sellVolume[], double &buySellVolume[], double &price[],ENUM_APPLIED_PRICE applied_price, int start, int count);
      void  OLHCShiftRight();
      void  OLHCResize();
      
      bool  Canvas_IsNewBar(const datetime &_Time[]);
      bool  Canvas_IsRatesTotalChanged(int ratesTotalNow);      
      int   Canvas_RatesTotalChangedBy(int ratesTotalNow);
      
      double CalcAppliedPrice(const MqlRates &_rates, ENUM_APPLIED_PRICE applied_price);
      double CalcAppliedPrice(const double &o,const double &l,const double &h,const double &c,ENUM_APPLIED_PRICE applied_price);

      ENUM_TIMEFRAMES TFMigrate(int tf);
      datetime iTime(string symbol,int tf,int index);
      double GetArrayValueDouble(double &arr[], int index);
      long GetArrayValueLong(long &arr[], int index);
      datetime GetArrayValueDateTime(datetime &arr[], int index);
};

TickChartIndicator::TickChartIndicator(void)
{
   tickChart = new TickChart(UseOnTickChart);
   if(tickChart != NULL)
      tickChart.Init();
      
   useAppliedPrice = false;
   getVolumes = false;
   getTime = false;
   
   dataReady = false;
   firstRun = true;
   prevTime = 0;
   prevRatesTotal = 0;
}

TickChartIndicator::~TickChartIndicator(void)
{
   if(tickChart != NULL)
   {
      tickChart.Deinit();
      delete tickChart;
   }
}

bool TickChartIndicator::CheckStatus(void)
{
   int handle = tickChart.GetHandle();
   if(handle == INVALID_HANDLE)
      return false;
   
   return true;
}

bool TickChartIndicator::NeedsReload(void)
{
   if(tickChart.Reload())
   {
     Print("Chart settings changed - reloading indicator with new settings");
     return true;
   }
   
   return false;
}

void TickChartIndicator::OnDeinit(const int reason) 
{
}

bool TickChartIndicator::OnCalculate(const int _rates_total,const int _prev_calculated, const datetime &_Time[])
{   
   if(firstRun)
   {
      Canvas_IsNewBar(_Time); 
      Canvas_RatesTotalChangedBy(_rates_total);   
      IsNewBar = tickChart.IsNewBar();   
   }

   if(!CheckStatus())
   {
      if(tickChart != NULL)
         delete tickChart;
      
      tickChart = new TickChart(UseOnTickChart);
      if(tickChart != NULL)
         tickChart.Init();
      
      Print("CheckStatus block failed");
            
      return false;
   }

   ArraySetAsSeries(this.Time,false);
   ArraySetAsSeries(this.Open,false);
   ArraySetAsSeries(this.High,false);
   ArraySetAsSeries(this.Low,false);
   ArraySetAsSeries(this.Close,false);   
   ArraySetAsSeries(this.Price,false);   
   ArraySetAsSeries(this.Tick_volume,false);   
   ArraySetAsSeries(this.Real_volume,false);   
   ArraySetAsSeries(this.Buy_volume,false);   
   ArraySetAsSeries(this.Sell_volume,false);   
   ArraySetAsSeries(this.BuySell_volume,false);   
   
   if(firstRun)
   {
      GetOLHC(0,_rates_total);
      firstRun = false;   
   }   
   
   if(NeedsReload() || !this.dataReady) 
   {
      GetOLHC(0,_rates_total);
      this.prev_calculated = 0;
      
      return false;
   }                    
                
   bool change = Canvas_RatesTotalChangedBy(_rates_total);

   if(change != 0)
   {
      #ifdef DISPLAY_DEBUG_MSG
         Print("rates total changed to:"+_rates_total);
      #endif
      
      if(change == 1)
      {
         #ifdef DISPLAY_DEBUG_MSG
            Print("changed by 1 => Resize called");   
         #endif
         OLHCResize();
      }
      else      
      {
         #ifdef DISPLAY_DEBUG_MSG
            Print("changed by "+change+" => getting ALL");
         #endif
         GetOLHC(0,_rates_total);
      }
      
      this.prev_calculated = 0;
      Canvas_IsNewBar(_Time);
      return true;   
   }
   else if(Canvas_IsNewBar(_Time))
   {
      #ifdef DISPLAY_DEBUG_MSG
         Print("Got Canvas_IsNewBar");
      #endif

      if(ArraySize(this.Open) == 0)
      {
         GetOLHC(0,_rates_total);
         this.prev_calculated = 0;
         return true; 
      }

      OLHCShiftRight();
      this.prev_calculated = _prev_calculated; 
      return true;
   }

   IsNewBar = tickChart.IsNewBar();
   if(IsNewBar)
   {
      GetOLHC(0,_rates_total);
      this.prev_calculated = 0;
      return true;
   } 
   
   //
   // Only recalculate last bar
   //
   
   GetOLHC(0,0);
   this.prev_calculated = _prev_calculated;

   return true;
}

int TickChartIndicator::GetOLHC(int start, int count)
{
   if((start == 0) && (count == 0) && dataReady)
   {
     MqlRates tempRates[1];
     double b[1],s[1],bs[1];
     
     int last = ArraySize(Open)-1;
     
     if(last < 0)
      return 0;
     
     tickChart.GetMqlRates(tempRates,0,1);
     this.Open[last] = tempRates[0].open;
     this.Low[last] = tempRates[0].low;
     this.High[last] = tempRates[0].high;
     this.Close[last] = tempRates[0].close;    
     
     if(getTime)
     {
         this.Time[last] = tempRates[0].time;
     }
     if(getVolumes)
     {
         this.Tick_volume[last] = tempRates[0].tick_volume;
         this.Real_volume[last] = tempRates[0].real_volume;
     }
     if(useAppliedPrice)
     {
         this.Price[last] = CalcAppliedPrice(tempRates[0],this.applied_price);
     }
     if(getVolumeBreakdown)
     {
        tickChart.GetBuySellVolumeBreakdown(b,s,bs,0,1);
        this.Buy_volume[last] = b[0];
        this.Sell_volume[last] = s[0];
        this.BuySell_volume[last] = bs[0];        
     }

     return 1;
   }
   else
   {
      return  GetOLHCAndApplPriceForIndicatorCalc(this.Open,this.Low,this.High,this.Close,this.Time,this.Tick_volume,this.Real_volume, this.Buy_volume, this.Sell_volume, this.BuySell_volume, this.Price,this.applied_price,0,count);   
   }
}


void TickChartIndicator::OLHCShiftRight()
{
   int count = ArraySize(this.Open);

   if(count <= 0)
      return;
   
   count--;
   
   for(int i=count; i>0; i--)
   {
      this.Open[i] = this.Open[i-1];
      this.High[i] = this.High[i-1];
      this.Low[i] = this.Low[i-1];
      this.Close[i] = this.Close[i-1];

      if(getTime)
         this.Time[i] = this.Time[i-1];

      if(useAppliedPrice)
         this.Price[i] = this.Price[i-1];

      if(getVolumes)
      {
         this.Tick_volume[i] = this.Tick_volume[i-1];
         this.Real_volume[i] = this.Real_volume[i-1];         
      }
      if(getVolumeBreakdown)
      {
         this.Buy_volume[i] = this.Buy_volume[i-1];
         this.Sell_volume[i] = this.Sell_volume[i-1];
         this.BuySell_volume[i] = this.BuySell_volume[i-1];
      }
   }
   
   this.Open[0] = 0.0;
   this.High[0] = 0.0;
   this.Low[0] = 0.0;
   this.Close[0] = 0.0;
   
   if(getTime)
      this.Time[0] = 0;

   if(useAppliedPrice)
      this.Price[0] = 0.0;

   if(getVolumes)
   {
      this.Tick_volume[0] = 0.0;
      this.Real_volume[0] = 0.0;         
   }
   if(getVolumeBreakdown)
   {
      this.Buy_volume[0] = 0;
      this.Sell_volume[0] = 0;
      this.BuySell_volume[0] = 0;
   }
}

void TickChartIndicator::OLHCResize()
{
   int count = ArraySize(this.Open);
   
   if(count <= 0)
      return;
   
   ArrayResize(this.Open,count+1);
   ArrayResize(this.Low,count+1);
   ArrayResize(this.High,count+1);
   ArrayResize(this.Close,count+1);
   
   if(getTime)
      ArrayResize(this.Time,count+1);

   if(useAppliedPrice)
      ArrayResize(this.Price,count+1);

   if(getVolumes)
   {
      ArrayResize(this.Tick_volume,count+1);
      ArrayResize(this.Real_volume,count+1);
   }
   if(getVolumeBreakdown)
   {
      ArrayResize(this.Buy_volume,count+1);
      ArrayResize(this.Sell_volume,count+1);
      ArrayResize(this.BuySell_volume,count+1);
   }
   
   OLHCShiftRight();
}

bool TickChartIndicator::Canvas_IsNewBar(const datetime &_Time[])
{
   ArraySetAsSeries(_Time,true);
   datetime now = _Time[0]; 
   ArraySetAsSeries(_Time,false);    
   
   if(prevTime != now)
   {
      prevTime = now;
      return true;
   }
   
   return false;
}

bool TickChartIndicator::Canvas_IsRatesTotalChanged(int ratesTotalNow)
{   
   if(prevRatesTotal == 0)
      prevRatesTotal = ratesTotalNow;
         
   if(prevRatesTotal != ratesTotalNow)
   {
      prevRatesTotal = ratesTotalNow;
      return true;
   }
   
   return false;
}

int TickChartIndicator::Canvas_RatesTotalChangedBy(int ratesTotalNow)
{
   int changedBy = 0;
   
   if(prevRatesTotal == 0)
      prevRatesTotal = ratesTotalNow;
         
   if(prevRatesTotal != ratesTotalNow)
   {
      changedBy = (ratesTotalNow - prevRatesTotal);
      prevRatesTotal = ratesTotalNow;
      return changedBy;
   }
   
   return 0;
}

int TickChartIndicator::GetOLHCForIndicatorCalc(double &o[],double &l[],double &h[],double &c[],datetime &t[], long &tickVolume[],long &realVolume[], double &buyVolume[], double &sellVolume[], double &buySellVolume[], int start, int count)
{
   int handle;
   double temp[];
   
   if(ArrayResize(temp,count) == -1)
      return -1;
   if(ArrayResize(o,count) == -1)
      return -1;
   if(ArrayResize(l,count) == -1)
      return -1;
   if(ArrayResize(h,count) == -1)
      return -1;
   if(ArrayResize(c,count) == -1)
      return -1;
   
   if(getVolumes)
   {
      if(ArrayResize(tickVolume,count) == -1)
         return -1;
      if(ArrayResize(realVolume,count) == -1)
         return -1;
   }
   
   if(getTime)
   {
      if(ArrayResize(t,count) == -1)
         return -1;
   }
   
   if(getVolumeBreakdown)
   {
      if(ArrayResize(buyVolume,count) == -1)
         return -1;
      if(ArrayResize(sellVolume,count) == -1)
         return -1;
      if(ArrayResize(buySellVolume,count) == -1)
         return -1; 
   }
   
   handle = tickChart.GetHandle();
   if(handle == INVALID_HANDLE)
      return -1;

   int __count = CopyBuffer(handle,TICKCHART_OPEN,start,count,temp);
   if(__count == -1)
   {
      if(GetLastError() == ERR_INDICATOR_DATA_NOT_FOUND)
      {
         Print("Waiting for buffers ready flag");
         return -2;
      }
      else
         return -1;
   }   
      
   if(__count < count)
   {
      #ifdef DISPLAY_DEBUG_MSG
         Print("Fixing offset (req:"+count+" res:"+__count+")");
      #endif
      
      ArrayInitialize(o,0x0);
      ArrayInitialize(l,0x0);
      ArrayInitialize(h,0x0);
      ArrayInitialize(c,0x0);
      
      if(getTime)
         ArrayInitialize(t,0x0);
         
      if(getVolumes)
      {
         ArrayInitialize(tickVolume,0x0);
         ArrayInitialize(realVolume,0x0);
      }
      
      if(getVolumeBreakdown)
      {
         ArrayInitialize(buyVolume,0x0);
         ArrayInitialize(sellVolume,0x0);
         ArrayInitialize(buySellVolume,0x0);
      }
      
      // less data - indicator requres more
      
      ArrayCopy(o,temp,(count-__count),0);

      if(CopyBuffer(handle,TICKCHART_LOW,start,__count,temp) == -1)
         return -1;
      ArrayCopy(l,temp,(count-__count),0);
         
      if(CopyBuffer(handle,TICKCHART_HIGH,start,__count,temp) == -1)
         return -1;
      ArrayCopy(h,temp,(count-__count),0);

      if(CopyBuffer(handle,TICKCHART_CLOSE,start,__count,temp) == -1)
         return -1;

      ArrayCopy(c,temp,(count-__count),0);
      
      if(getTime)
      {
         if(CopyBuffer(handle,TICKCHART_BAR_OPEN_TIME,start,__count,temp) == -1)
            return -1;
            
         ArrayCopy(t,temp,(count-__count),0);      
      }
      
      if(getVolumes)
      {
         if(CopyBuffer(handle,TICKCHART_TICK_VOLUME,start,__count,temp) == -1)
            return -1;
            
         ArrayCopy(tickVolume,temp,(count-__count),0);
   
         if(CopyBuffer(handle,TICKCHART_REAL_VOLUME,start,__count,temp) == -1)
            return -1;
            
         ArrayCopy(realVolume,temp,(count-__count),0);      
      }
      
#ifdef P_TICKCHART_BR
   #ifdef P_TICKCHART_BR_PRO
      if(getVolumeBreakdown)
      {      
         if(CopyBuffer(handle,TICKCHART_BUY_VOLUME,start,__count,temp) == -1)
            return -1;
            
         ArrayCopy(buyVolume,temp,(count-__count),0);

         if(CopyBuffer(handle,TICKCHART_SELL_VOLUME,start,__count,temp) == -1)
            return -1;
            
         ArrayCopy(sellVolume,temp,(count-__count),0);

         if(CopyBuffer(handle,TICKCHART_BUYSELL_VOLUME,start,__count,temp) == -1)
            return -1;
            
         ArrayCopy(buySellVolume,temp,(count-__count),0);
      }
   #else
   #endif
#else      
      if(getVolumeBreakdown)
      {      
         if(CopyBuffer(handle,TICKCHART_BUY_VOLUME,start,__count,temp) == -1)
            return -1;
            
         ArrayCopy(buyVolume,temp,(count-__count),0);

         if(CopyBuffer(handle,TICKCHART_SELL_VOLUME,start,__count,temp) == -1)
            return -1;
            
         ArrayCopy(sellVolume,temp,(count-__count),0);

         if(CopyBuffer(handle,TICKCHART_BUYSELL_VOLUME,start,__count,temp) == -1)
            return -1;
            
         ArrayCopy(buySellVolume,temp,(count-__count),0);
      }
#endif

   }
   else
   {
      if(CopyBuffer(handle,TICKCHART_OPEN,start,count,o) == -1)
         return -1;
         
      if(CopyBuffer(handle,TICKCHART_LOW,start,count,l) == -1)
         return -1;
         
      if(CopyBuffer(handle,TICKCHART_HIGH,start,count,h) == -1)
         return -1;
         
      if(CopyBuffer(handle,TICKCHART_CLOSE,start,count,c) == -1)
         return -1;
      
      if(getTime)
      {
         if(CopyBuffer(handle,TICKCHART_BAR_OPEN_TIME,start,count,temp) == -1)
            return -1;
            
         ArrayCopy(t,temp);
      }   
      
      if(getVolumes)
      {
         if(CopyBuffer(handle,TICKCHART_TICK_VOLUME,start,count,temp) == -1)
            return -1;
            
         ArrayCopy(tickVolume,temp);
         
         if(CopyBuffer(handle,TICKCHART_REAL_VOLUME,start,count,temp) == -1)
            return -1;   
         
         ArrayCopy(realVolume,temp);
      }
      
#ifdef P_TICKCHART_BR
   #ifdef P_TICKCHART_BR_PRO
      if(getVolumeBreakdown)
      {      
         if(CopyBuffer(handle,TICKCHART_BUY_VOLUME,start,count,temp) == -1)
            return -1;
            
         ArrayCopy(buyVolume,temp);

         if(CopyBuffer(handle,TICKCHART_SELL_VOLUME,start,count,temp) == -1)
            return -1;
            
         ArrayCopy(sellVolume,temp);

         if(CopyBuffer(handle,TICKCHART_BUYSELL_VOLUME,start,count,temp) == -1)
            return -1;
            
         ArrayCopy(buySellVolume,temp);
      }
   #else
   #endif
#else
      if(getVolumeBreakdown)
      {      
         if(CopyBuffer(handle,TICKCHART_BUY_VOLUME,start,count,temp) == -1)
            return -1;
            
         ArrayCopy(buyVolume,temp);

         if(CopyBuffer(handle,TICKCHART_SELL_VOLUME,start,count,temp) == -1)
            return -1;
            
         ArrayCopy(sellVolume,temp);

         if(CopyBuffer(handle,TICKCHART_BUYSELL_VOLUME,start,count,temp) == -1)
            return -1;
            
         ArrayCopy(buySellVolume,temp);
      }
#endif      
   }
     
   return count;
}

//
// Get "count" custom chart's MqlRates into "ratesInfoArray[]" array starting from "start" bar  
//

int TickChartIndicator::GetOLHCAndApplPriceForIndicatorCalc(double &o[],double &l[],double &h[],double &c[],datetime &t[],long &tickVolume[],long &realVolume[],double &buyVolume[], double &sellVolume[], double &buySellVolume[],double &price[],ENUM_APPLIED_PRICE _applied_price, int start, int count)
{
   dataReady = true;
   
   int __count = GetOLHCForIndicatorCalc(o,l,h,c,t,tickVolume,realVolume,buyVolume,sellVolume,buySellVolume,start,count);
   if(__count < 0)
   {
      dataReady = false;
      return __count;
   }
   if(applied_price == PRICE_CLOSE) 
   {
      return ArrayCopy(price,c);
   }
   else if(applied_price == PRICE_OPEN) 
   {
      return ArrayCopy(price,o);
   }
   else if(applied_price == PRICE_HIGH) 
   {
      return ArrayCopy(price,h);
   }
   else if(applied_price == PRICE_LOW) 
   {
      return ArrayCopy(price,l);
   }
   else
   {       
      if(ArrayResize(price,__count) == -1)
         return -1;      

      for(int i=0; i<__count; i++)
      {
         price[i] = CalcAppliedPrice(o[i],l[i],h[i],c[i],_applied_price);
      }
   }
      
   return __count;
}

// TFMigrate: 
// https://www.mql5.com/en/forum/2842#comment_39496
//
ENUM_TIMEFRAMES TickChartIndicator::TFMigrate(int tf)
{
   switch(tf)
   {
      case 0: return(PERIOD_CURRENT);
      case 1: return(PERIOD_M1);
      case 5: return(PERIOD_M5);
      case 15: return(PERIOD_M15);
      case 30: return(PERIOD_M30);
      case 60: return(PERIOD_H1);
      case 240: return(PERIOD_H4);
      case 1440: return(PERIOD_D1);
      case 10080: return(PERIOD_W1);
      case 43200: return(PERIOD_MN1);
      
      case 2: return(PERIOD_M2);
      case 3: return(PERIOD_M3);
      case 4: return(PERIOD_M4);      
      case 6: return(PERIOD_M6);
      case 10: return(PERIOD_M10);
      case 12: return(PERIOD_M12);
      case 16385: return(PERIOD_H1);
      case 16386: return(PERIOD_H2);
      case 16387: return(PERIOD_H3);
      case 16388: return(PERIOD_H4);
      case 16390: return(PERIOD_H6);
      case 16392: return(PERIOD_H8);
      case 16396: return(PERIOD_H12);
      case 16408: return(PERIOD_D1);
      case 32769: return(PERIOD_W1);
      case 49153: return(PERIOD_MN1);      

      default: return(PERIOD_CURRENT);
   }
}

datetime TickChartIndicator::iTime(string symbol,int tf,int index)
{
   if(index < 0)
   {
      return(-1);
   }
   
   ENUM_TIMEFRAMES timeframe=TFMigrate(tf);
   
   datetime Arr[];
   
   if(CopyTime(symbol, timeframe, index, 1, Arr) > 0)
   {
      return(Arr[0]);
   }
   else 
   {
      return(-1);
   }
}

//
//  Function used for calculating the Apllied Price based on Renko OLHC values
//

double TickChartIndicator::CalcAppliedPrice(const MqlRates &_rates, ENUM_APPLIED_PRICE _applied_price)
{
      if(_applied_price == PRICE_CLOSE)
         return _rates.close;
      else if (_applied_price == PRICE_OPEN)
         return _rates.open;
      else if (_applied_price == PRICE_HIGH)
         return _rates.high;
      else if (_applied_price == PRICE_LOW)
         return _rates.low;
      else if (_applied_price == PRICE_MEDIAN)
         return (_rates.high + _rates.low) / 2;
      else if (_applied_price == PRICE_TYPICAL)
         return (_rates.high + _rates.low + _rates.close) / 3;
      else if (_applied_price == PRICE_WEIGHTED)
         return (_rates.high + _rates.low + _rates.close + _rates.close) / 4;
         
      return 0.0;
}

double TickChartIndicator::CalcAppliedPrice(const double &o,const double &l,const double &h,const double &c, ENUM_APPLIED_PRICE _applied_price)
{
      if(_applied_price == PRICE_CLOSE)
         return c;
      else if (_applied_price == PRICE_OPEN)
         return o;
      else if (_applied_price == PRICE_HIGH)
         return h;
      else if (_applied_price == PRICE_LOW)
         return l;
      else if (_applied_price == PRICE_MEDIAN)
         return (h + l) / 2;
      else if (_applied_price == PRICE_TYPICAL)
         return (h + l + c) / 3;
      else if (_applied_price == PRICE_WEIGHTED)
         return (h + l + c +c) / 4;
      
      return 0.0;
}

void TickChartIndicator::BufferShiftLeft(double &buffer[])
{
   int size = ArraySize(buffer);
   
   for(int i=1; i<size; i++)
      buffer[i-1] = buffer[i];

}


long TickChartIndicator::GetArrayValueLong(long &arr[], int index)
{
   int size  = ArraySize(arr);
   if(index < size)
   {
       return(arr[index]);
   } 
   else    
   {
       return(false); 
   }
}

double TickChartIndicator::GetArrayValueDouble(double &arr[], int index)
{
   int size  = ArraySize(arr);
   if(index < size)
   {
       return(arr[index]);
   } 
   else    
   {
       return(false); 
   }
}

datetime TickChartIndicator::GetArrayValueDateTime(datetime &arr[], int index)
{
   int size  = ArraySize(arr);
   if(index < size)
   {
       return(arr[index]);
   } 
   else    
   {
       return(false); 
   }
}

