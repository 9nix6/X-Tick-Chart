#property copyright "Copyright 2018-2020, Level Up Software"
#property link      "https://www.az-invest.eu"

#include <AZ-INVEST/SDK/CommonSettings.mqh>

#ifdef SHOW_INDICATOR_INPUTS
         
   #ifdef USE_CUSTOM_SYMBOL
   
      input group                      "### Misc"
   
      #ifdef MQL5_MARKET_DEMO
         string                        InpCustomChartName = "";                     // Override default custom chart name with
      #else
         input string                  InpCustomChartName = "";                     // Override default custom chart name with
      #endif // MQL5_MARKET_DEMO
   
      input string                     InpApplyTemplate = "default";                // Apply template to custom chart
      input ENUM_BOOL                  InpForceFasterRefresh = false;               // Force faster chart refresh
      input ENUM_BOOL                  InpForBacktester = false;                    // Create chart for backtesting only
      input ENUM_BOOL                  InpShowTradeLevels = false;                  // Show trade levels on chart
   
   #endif // end of USE_CUSTOM_SYMBOL
      
   #ifndef USE_CUSTOM_SYMBOL // Main Inputs block
       
      #ifdef AMP_VERSION  
         input string                  InpTradingSessionTime = "14:30-23:00";       // Trading session time
         input double                  InpTopBottomPaddingPercentage = 0.30;        // Use padding top/bottom (0.0 - 1.0)
      #endif
      
         input group                   "### Pivots"

         input ENUM_PIVOT_POINTS       InpShowPivots = ppNone;                      // Show pivot levels
         input ENUM_PIVOT_TYPE         InpPivotPointCalculationType = ppHLC3;       // Pivot point calculation method
               ENUM_BOOL               InpShowNextBarLevels = false;                // Show current bar's close projections
//               color                   InpHighThresholdIndicatorColor = clrLime;    // Bullish bar projection color
//               color                   InpLowThresholdIndicatorColor = clrRed;      // Bearish bar projection color
               color                   InpInfoTextColor = clrNONE;                  // Current bar's open time info color
         
      #ifdef AMP_VERSION  

         input ENUM_BOOL               InphowCurrentBarOpenTime = true;            // Display chart info

         input ENUM_BOOL               InpNewBarAlert = false;                      // Alert on new a bar
         input ENUM_BOOL               InpReversalBarAlert = false;                 // Alert on reversal bar
         input ENUM_BOOL               InpMaCrossAlert = false;                     // Alert on MA crossover
         input ENUM_BOOL               InpUseAlertWindow = false;                   // Display alert in Alert Window
         input ENUM_BOOL               InpUseSound = false;                         // Play sound on alert
         input ENUM_BOOL               InpUsePushNotifications = false;             // Send alert via push notification to a smartphone
         input string                  InpSoundFileBull = "news.wav";               // Use sound file for bullish alert
         input string                  InpSoundFileBear = "timeout.wav";            // Use sound file for bearish alert
      
      #else
         
         input group                   "### Alerts"

         input ENUM_ALERT_WHEN         InpAlertMeWhen = ALERT_WHEN_None;            // Alert condition
         input ENUM_ALERT_NOTIFY_TYPE  InpAlertNotificationType = ALERT_NOTIFY_TYPE_None; // Alert notification type
         
      #endif
         

         
      #ifdef AMP_VERSION  
      
            input ENUM_BOOL               InpMA1on = false;                            // Show tick
            input ENUM_MA_LINE_TYPE       InpMA1lineType = MA_DOTS;                    // Tick Draw as
            input int                     InpMA1period = 1;                            // Tick period
            input ENUM_MA_METHOD_EXT      InpMA1method =  _MODE_EMA;                   // Tick method
            input ENUM_APPLIED_PRICE      InpMA1applyTo = PRICE_CLOSE;                 // Tick apply to
            input int                     InpMA1shift = 0;                             // Tick shift
            input ENUM_BOOL               InpMA1priceLabel = false;                    // Show tick price label
            
            input ENUM_BOOL               InpMA2on = false;                            // Show FYL
            input ENUM_MA_LINE_TYPE       InpMA2lineType = MA_LINE;                    // FYL draw as
            input int                     InpMA2period = 86;                           // FYL period
            input ENUM_MA_METHOD_EXT      InpMA2method = _LINEAR_REGRESSION;           // FLY method
            input ENUM_APPLIED_PRICE      InpMA2applyTo = PRICE_CLOSE;                 // FLY apply to
            input int                     InpMA2shift = 0;                             // FLY shift
            input ENUM_BOOL               InpMA2priceLabel = false;                    // Show FLY price label
            
            input ENUM_BOOL               InpMA3on = false;                            // Show third MA 
            input ENUM_MA_LINE_TYPE       InpMA3lineType = MA_LINE;                    // 3rd MA draw as
            input int                     InpMA3period = 20;                           // 3rd MA period
            input ENUM_MA_METHOD_EXT      InpMA3method = _VWAP_TICKVOL;                // 3rd MA method
            input ENUM_APPLIED_PRICE      InpMA3applyTo = PRICE_CLOSE;                 // 3rd MA apply to
            input int                     InpMA3shift = 0;                             // 3rd MA shift
            input ENUM_BOOL               InpMA3priceLabel = false;                    // 3rd MA show price label
   
            input ENUM_BOOL               InpMA4on = false;                            // Show fourth MA 
            input ENUM_MA_LINE_TYPE       InpMA4lineType = MA_LINE;                    // 4th MA draw as
            input int                     InpMA4period = 21;                           // 4th MA period
            input ENUM_MA_METHOD_EXT      InpMA4method = _MODE_SMA;                    // 4th MA method
            input ENUM_APPLIED_PRICE      InpMA4applyTo = PRICE_CLOSE;                 // 4th MA apply to
            input int                     InpMA4shift = 0;                             // 4th MA shift
            input ENUM_BOOL               InpMA4priceLabel = false;                    // 4st MA show price label
            
            input ENUM_CHANNEL_TYPE       InpShowChannel = _None;                      // Show Keltner Channel
            input int                     InpChannelPeriod = 20;                       // Keltner channel period
            input int                     InpChannelAtrPeriod = 10;                    // Keltner channel ATR period
            input ENUM_APPLIED_PRICE      InpChannelAppliedPrice = PRICE_CLOSE;        // Keltner channel applied price
            input double                  InpChannelMultiplier = 2;                    // Keltner channel multiplier
                  double                  InpChannelBandsDeviations = 2.0;             
            input ENUM_BOOL               InpChannelPriceLabel = false;                // Show Keltner channel price labels
            input ENUM_BOOL               InpChannelMidPriceLabel = false;             // Show Keltner channel mid-price label

      #else /////////////////////////////////////////////////////////////////////////////

            input group                   "### Moving Averages"

            input ENUM_MA_LINE_TYPE       InpMA1lineType = MA_NONE;                    // 1st MA
            input int                     InpMA1period = 9;                            // 1st MA period
            input ENUM_MA_METHOD_EXT      InpMA1method =  _MODE_EMA;                   // 1st MA method
            input ENUM_APPLIED_PRICE      InpMA1applyTo = PRICE_CLOSE;                 // 1st MA apply to
            input int                     InpMA1shift = 0;                             // 1st MA shift
            input ENUM_BOOL               InpMA1priceLabel = false;                    // 1st MA show price label
            
            input ENUM_MA_LINE_TYPE       InpMA2lineType = MA_NONE;                    // 2nd MA
            input int                     InpMA2period = 86;                           // 2nd MA period
            input ENUM_MA_METHOD_EXT      InpMA2method = _LINEAR_REGRESSION;           // 2nd MA method
            input ENUM_APPLIED_PRICE      InpMA2applyTo = PRICE_CLOSE;                 // 2nd MA apply to
            input int                     InpMA2shift = 0;                             // 2nd MA shift
            input ENUM_BOOL               InpMA2priceLabel = false;                    // 2nd MA show price label
            
            input ENUM_MA_LINE_TYPE       InpMA3lineType = MA_NONE;                    // 3rd MA
            input int                     InpMA3period = 20;                           // 3rd MA period
            input ENUM_MA_METHOD_EXT      InpMA3method = _VWAP_TICKVOL;                // 3rd MA method
            input ENUM_APPLIED_PRICE      InpMA3applyTo = PRICE_CLOSE;                 // 3rd MA apply to
            input int                     InpMA3shift = 0;                             // 3rd MA shift
            input ENUM_BOOL               InpMA3priceLabel = false;                    // 3rd MA show price label
   
            input ENUM_MA_LINE_TYPE       InpMA4lineType = MA_NONE;                    // 4th MA
            input int                     InpMA4period = 21;                           // 4th MA period
            input ENUM_MA_METHOD_EXT      InpMA4method = _MODE_SMA;                    // 4th MA method
            input ENUM_APPLIED_PRICE      InpMA4applyTo = PRICE_CLOSE;                 // 4th MA apply to
            input int                     InpMA4shift = 0;                             // 4th MA shift
            input ENUM_BOOL               InpMA4priceLabel = false;                    // 4st MA show price label
            
            input group                   "### Channel"
            
            input ENUM_CHANNEL_TYPE       InpShowChannel = _None;                      // Show Channel
            input int                     InpChannelPeriod = 20;                       // Channel period
            input int                     InpChannelAtrPeriod = 10;                    // Channel ATR period
            input ENUM_APPLIED_PRICE      InpChannelAppliedPrice = PRICE_CLOSE;        // Channel applied price
            input double                  InpChannelMultiplier = 2;                    // Channel multiplier
            input double                  InpChannelBandsDeviations = 2.0;             // Channel Bands deviations
            input ENUM_CHANNEL_LABEL_DISP InpChannelPriceLabels = LABEL_NONE;          // Channel Bands price labels   
            //input ENUM_BOOL               InpChannelPriceLabel = false;                // Channel Bands price labels   
            //input ENUM_BOOL               InpChannelMidPriceLabel = false;             // Channel mid-price label   
         
      #endif // AMP_VERSION  
                  
         input group                   "### Misc"

         input ENUM_BOOL               InpUsedInEA = false;                            // Indicator used in EA via iCustom()

      #ifndef AMP_VERSION  
         input string                  InpTradingSessionTime = "00:00-00:00";          // Trading session time
         input double                  InpTopBottomPaddingPercentage = 0.30;           // Use padding top/bottom (0.0 - 1.0)
         input color                   InpRColor = clrDodgerBlue;                      // Resistance line color
         input color                   InpPColor = clrGold;                            // Pivot line color
         input color                   InpSColor = clrFireBrick;                       // Support line color   
         input color                   InpPDHColor = clrHotPink;                       // Previous day's high
         input color                   InpPDLColor = clrLightSkyBlue;                  // Previous day's low
         input color                   InpPDCColor = clrGainsboro;                     // Previous day's close         

        #ifdef USES_PRICE_PROJECTIONS      
         input color                   InpHighThresholdIndicatorColor = clrGreen;      // Bullish bar projection color
         input color                   InpLowThresholdIndicatorColor = clrFireBrick;   // Bearish bar projection color
        #endif
        #ifdef USES_COUNTER  
         input color                   InpCounterColor = clrGold;                      // Counter color
        #endif 
         input color                   InpMA1PriceLabelColor = clrWhiteSmoke;          // MA1 label color
         input color                   InpMA2PriceLabelColor = clrWhiteSmoke;          // MA2 label color
         input color                   InpMA3PriceLabelColor = clrWhiteSmoke;          // MA3 label color
         input color                   InpMA4PriceLabelColor = clrWhiteSmoke;          // MA4 label color
         input color                   InpChannelHighPriceLabelColor = clrWhiteSmoke;  // Channel high label color
         input color                   InpChannelMidPriceLabelColor = clrWhiteSmoke;   // Channel mid label color
         input color                   InpChannelLowPriceLabelColor = clrWhiteSmoke;   // Channel low label color

         input ENUM_BOOL               InpShowCurrentBarOpenTime = true;               // Display chart info
         input string                  InpSoundFileBull = "news.wav";                  // Use sound file for bullish alert
         input string                  InpSoundFileBear = "timeout.wav";               // Use sound file for bearish alert
      #endif // !AMP_VERSION  
      
//      #ifdef AMP_VERSION    
//         input ENUM_BOOL               DisplayAsBarChart = true;                  // Display as tick chart
//      #else
         input ENUM_BOOL               InpDisplayAsBarChart = false;                   // Display as bar chart
//      #endif // AMP_VERSION 
         input ENUM_BOOL               InpShiftObj = false;                            // Shift objects with chart

   #endif // !USE_CUSTOM_SYMBOL

#else // don't SHOW_INDICATOR_INPUTS

   //
   //  This block sets default values
   //
   
   string                     InpTradingSessionTime = "0:0-0:0"; 
   double                     InpTopBottomPaddingPercentage = 0;
   ENUM_PIVOT_POINTS          InpShowPivots = ppNone;
   ENUM_PIVOT_TYPE            InpPivotPointCalculationType = ppHLC3;
   color                      InpRColor = clrNONE;
   color                      InpPColor = clrNONE;
   color                      InpSColor = clrNONE;
   color                      InpPDHColor = clrNONE;
   color                      InpPDLColor = clrNONE;
   color                      InpPDCColor = clrNONE;

  #ifdef USES_PRICE_PROJECTIONS      
   color                      InpHighThresholdIndicatorColor = clrNONE;
   color                      InpLowThresholdIndicatorColor = clrNONE;
  #endif
  #ifdef USES_COUNTER  
   color                      InpCounterColor = clrNONE;
  #endif
   color                      InpMA1PriceLabelColor = clrNONE;
   color                      InpMA2PriceLabelColor = clrNONE;
   color                      InpMA3PriceLabelColor = clrNONE;
   color                      InpMA4PriceLabelColor = clrNONE;
   color                      InpChannelHighPriceLabelColor = clrNONE;
   color                      InpChannelMidPriceLabelColor = clrNONE;
   color                      InpChannelLowPriceLabelColor = clrNONE;

   ENUM_BOOL                  InpShowNextBarLevels = false;
   ENUM_BOOL                  InpShowCurrentBarOpenTime = false;
   color                      InpInfoTextColor = clrNONE;
   
   #ifdef AMP_VERSION  

      ENUM_BOOL                  InpNewBarAlert = false; 
      ENUM_BOOL                  InpReversalBarAlert = false;
      ENUM_BOOL                  InpMaCrossAlert = false;    
      ENUM_BOOL                  InpUseAlertWindow = false;  
      ENUM_BOOL                  InpUseSound = false;        
      ENUM_BOOL                  InpUsePushNotifications = false;
   
   #else
      
      ENUM_ALERT_WHEN         InpAlertMeWhen = ALERT_WHEN_None;  
      ENUM_ALERT_NOTIFY_TYPE  InpAlertNotificationType = ALERT_NOTIFY_TYPE_None; 
      
   #endif
      
   string                     InpSoundFileBull = "";
   string                     InpSoundFileBear = "";
   ENUM_BOOL                  InpDisplayAsBarChart = true;
   ENUM_BOOL                  InpShiftObj = false;
   ENUM_BOOL                  InpUsedInEA = true; // This should always be set to TRUE for EAs & Indicators
          
#endif // SHOW_INDICATOR_INPUTS
