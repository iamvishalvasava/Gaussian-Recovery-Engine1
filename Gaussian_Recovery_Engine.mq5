//+------------------------------------------------------------------+
//|                                     Gaussian_Recovery_Engine.mq5 |
//|                                  Copyright 2025, Quant Strategy  |
//|                                       |
//+------------------------------------------------------------------+
#property copyright "@Defini8(Vasava vishal m)"
#property link      "@Defini8"
#property version   "1.00"
#include <Trade\Trade.mqh>

//--- INPUT PARAMETERS (Tame ahiya settings badli sako cho) ---
input group "--- Grid Settings ---"
input double   InpLotSize     = 0.01;      // First Trade Lot Size
input int      InpGridStep    = 200;       // Grid Distance (Points) - ex: 20 pips
input double   InpBasketTP    = 5.0;       // Basket Target Profit in USD ($)
input int      InpMaxOrders   = 10;        // Max Open Orders (Safety)

input group "--- Indicator Settings ---"
input int      InpADX_Period  = 14;        // ADX Period
input int      InpADX_Min     = 25;        // Minimum ADX Strength
input int      InpQQE_RSI_Per = 14;        // QQE (RSI Base) Period
input int      InpFisher_Per  = 10;        // Fisher Period

input group "--- Magic Number ---"
input int      InpMagicNum    = 999999;    // Magic Number ID

//--- Global Variables
CTrade trade;
int handle_adx;
int handle_rsi; // Used for QQE Logic
double adx_buff[];
double rsi_buff[]; // QQE Base

//+------------------------------------------------------------------+
//| Expert Initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   //-- Initialize Handles
   handle_adx = iADX(_Symbol, _Period, InpADX_Period);
   handle_rsi = iRSI(_Symbol, _Period, InpQQE_RSI_Per, PRICE_CLOSE);
   
   if(handle_adx == INVALID_HANDLE || handle_rsi == INVALID_HANDLE)
     {
      Print("Error creating indicators handles");
      return(INIT_FAILED);
     }

   trade.SetExpertMagicNumber(InpMagicNum);
   
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert Deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(handle_adx);
   IndicatorRelease(handle_rsi);
  }

//+------------------------------------------------------------------+
//| Expert Tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   //--- 1. Check Basket Profit (Badha Trade no Profit) ---
   CheckBasketTP();

   //--- 2. Update Indicator Data ---
   double adxValue = GetADX(0);
   double fisherCurr = CalculateFisher(0);
   double fisherPrev = CalculateFisher(1);
   double qqeTrend = GetQQE_Trend_Value(0); // RSI Smoothed as QQE proxy

   int totalOrders = CountOrders();
   
   //--- 3. ENTRY LOGIC (First Trade) ---
   if(totalOrders == 0)
     {
      // ADX Filter
      if(adxValue < InpADX_Min) return; // Market weak che, trade nahi

      // BUY SETUP
      // QQE > 50 (Trend Up) AND Fisher Cross Up from Bottom (-1)
      if(qqeTrend > 50 && fisherPrev < -1.0 && fisherCurr > fisherPrev)
        {
         trade.Buy(InpLotSize, _Symbol, 0, 0, 0, "QuantDada_Buy");
        }
      
      // SELL SETUP
      // QQE < 50 (Trend Down) AND Fisher Cross Down from Top (1)
      if(qqeTrend < 50 && fisherPrev > 1.0 && fisherCurr < fisherPrev)
        {
         trade.Sell(InpLotSize, _Symbol, 0, 0, 0, "QuantDada_Sell");
        }
     }

   //--- 4. GRID LOGIC (Add Orders if market goes against) ---
   else 
     {
      // Last Order details melvo
      double lastOpenPrice = 0;
      long lastType = -1;
      
      // History scan karine last order find karo
      for(int i = PositionsTotal()-1; i >= 0; i--)
        {
         ulong ticket = PositionGetTicket(i);
         if(PositionGetInteger(POSITION_MAGIC) == InpMagicNum && PositionGetString(POSITION_SYMBOL) == _Symbol)
           {
             lastOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
             lastType = PositionGetInteger(POSITION_TYPE);
             break; // Last trade mali gayo
           }
        }

      // Grid Step Logic
      double currentPrice = (lastType == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double points = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      
      // Jo Buy hoy ane bhav niche gayo (GridStep jetlo)
      if(lastType == POSITION_TYPE_BUY && (lastOpenPrice - currentPrice) >= InpGridStep * points)
        {
         if(totalOrders < InpMaxOrders)
            trade.Buy(InpLotSize, _Symbol, 0, 0, 0, "QuantDada_Grid_Buy");
        }
      
      // Jo Sell hoy ane bhav upar gayo (GridStep jetlo)
      if(lastType == POSITION_TYPE_SELL && (currentPrice - lastOpenPrice) >= InpGridStep * points)
        {
         if(totalOrders < InpMaxOrders)
            trade.Sell(InpLotSize, _Symbol, 0, 0, 0, "QuantDada_Grid_Sell");
        }
     }
  }

//+------------------------------------------------------------------+
//| HELPER FUNCTIONS (Maths & Logic)                                 |
//+------------------------------------------------------------------+

//--- Calculate Basket Profit & Close All
void CheckBasketTP()
  {
   double totalProfit = 0;
   for(int i = PositionsTotal()-1; i >= 0; i--)
     {
      if(PositionSelectByTicket(PositionGetTicket(i)))
        {
         if(PositionGetInteger(POSITION_MAGIC) == InpMagicNum && PositionGetString(POSITION_SYMBOL) == _Symbol)
            totalProfit += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
        }
     }
   
   // Check Basket Target
   if(totalProfit >= InpBasketTP)
     {
      Print("Basket Target Hit: ", totalProfit, " USD. Closing All.");
      CloseAllOrders();
     }
  }

//--- Close All Positions
void CloseAllOrders()
  {
   for(int i = PositionsTotal()-1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionGetInteger(POSITION_MAGIC) == InpMagicNum && PositionGetString(POSITION_SYMBOL) == _Symbol)
        {
         trade.PositionClose(ticket);
        }
     }
  }

//--- Count Total Orders
int CountOrders()
  {
   int count = 0;
   for(int i = PositionsTotal()-1; i >= 0; i--)
     {
      if(PositionSelectByTicket(PositionGetTicket(i)))
        {
         if(PositionGetInteger(POSITION_MAGIC) == InpMagicNum && PositionGetString(POSITION_SYMBOL) == _Symbol)
            count++;
        }
     }
   return count;
  }

//--- Get ADX Value
double GetADX(int index)
  {
   double buff[1];
   if(CopyBuffer(handle_adx, 0, index, 1, buff) < 0) return 0;
   return buff[0];
  }

//--- Get QQE Trend Proxy (Smoothed RSI)
// Note: Pure QQE is complex, here we use RSI Strength as QQE Trend Baseline
double GetQQE_Trend_Value(int index)
  {
   double buff[1];
   if(CopyBuffer(handle_rsi, 0, index, 1, buff) < 0) return 50; // Default Neutral
   return buff[0];
  }

//--- Custom Fisher Transform Calculation (Embedded Math)
double CalculateFisher(int shift)
  {
   // Fisher needs High/Low of past N bars
   double MinL = DBL_MAX;
   double MaxH = -DBL_MAX;
   double Value = 0;
   double Fish = 0;
   
   // Simple Fisher Implementation for EA (Recursive approximation)
   // Note: For perfect history we need arrays, but for live trigger, we calculate locally.
   // This is a simplified "Relative" calculation for the requested bar.
   
   double High[], Low[];
   CopyHigh(_Symbol, _Period, shift, InpFisher_Per, High);
   CopyLow(_Symbol, _Period, shift, InpFisher_Per, Low);
   
   for(int i=0; i<InpFisher_Per; i++)
     {
      if(High[i] > MaxH) MaxH = High[i];
      if(Low[i] < MinL) MinL = Low[i];
     }
     
   double price = iClose(_Symbol, _Period, shift); // Using Close for approximation
   
   // Fisher Formula Part 1
   if(MaxH != MinL)
      Value = 0.33 * 2 * ((price - MinL) / (MaxH - MinL) - 0.5) + 0.67 * 0; // Simplified previous
      
   if(Value > 0.99) Value = 0.999;
   if(Value < -0.99) Value = -0.999;
   
   // Fisher Formula Part 2
   Fish = 0.5 * MathLog((1 + Value) / (1 - Value));
   
   return Fish * 10; // Scaling for readability
  }
//+------------------------------------------------------------------+