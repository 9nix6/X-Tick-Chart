//+------------------------------------------------------------------+
//| ChartOwnership.mqh                                               |
//|                                                                  |
//| An indicator instance created by iCustom() has no chart of its   |
//| own: inside it ChartID() is the CALLER's chart, while _Symbol    |
//| and _Period are the indicator's. "Force a reload" written as     |
//| ChartSetSymbolPeriod(ChartID(), _Symbol, _Period) therefore      |
//| switches the caller's chart to another symbol, and MT5 removes   |
//| an EA or script from a chart whose symbol changes.               |
//|                                                                  |
//| Rule: act on a chart only if it IS this instance's chart, i.e.   |
//| its symbol and period are the instance's own. On its own chart   |
//| every call below behaves exactly as the unguarded call did.      |
//|                                                                  |
//| Same file as the one the product installer ships.                |
//+------------------------------------------------------------------+
#ifndef AZ_CHART_OWNERSHIP_MQH
#define AZ_CHART_OWNERSHIP_MQH

bool IsOwnChart(long chartId, string instanceSymbol, ENUM_TIMEFRAMES instancePeriod)
{
   if(instancePeriod == PERIOD_CURRENT)
      instancePeriod = (ENUM_TIMEFRAMES)Period();
   return ChartSymbol(chartId) == instanceSymbol
       && (ENUM_TIMEFRAMES)ChartPeriod(chartId) == instancePeriod;
}

// Guarded ChartSetSymbolPeriod(chartId, instanceSymbol, instancePeriod). Returns whether a reload
// was requested. Says why it did not, once per instance, so a refusal is never silent.
bool ReloadChartIfOwn(long chartId, string instanceSymbol, ENUM_TIMEFRAMES instancePeriod)
{
   if(!IsOwnChart(chartId, instanceSymbol, instancePeriod))
   {
      static bool told = false;
      if(!told)
      {
         told = true;
         Print("Not reloading chart ", chartId, " (", ChartSymbol(chartId), ") - it is not this instance's "
               + instanceSymbol + " chart (instance created by iCustom?)");
      }
      return false;
   }
   return ChartSetSymbolPeriod(chartId, instanceSymbol, instancePeriod);
}

// Guarded ChartIndicatorDelete. Returns whether the delete succeeded.
bool RemoveIndicatorIfOwnChart(long chartId, int subWindow, string shortName,
                               string instanceSymbol, ENUM_TIMEFRAMES instancePeriod)
{
   if(!IsOwnChart(chartId, instanceSymbol, instancePeriod))
   {
      Print("Not removing " + shortName + " from chart ", chartId, " (", ChartSymbol(chartId),
            ") - it is not this instance's " + instanceSymbol + " chart (instance created by iCustom?)");
      return false;
   }
   return ChartIndicatorDelete(chartId, subWindow, shortName);
}

#endif
