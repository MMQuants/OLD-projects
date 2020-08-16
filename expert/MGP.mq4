//+------------------------------------------------------------------+
//|                                                MNewsTrading.mq4 |
//|                                                   Marin Stoyanov |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright "Marin Stoyanov"
#property link      "http://www.mql4.com"
#property version   "1.00"
#property strict
#include <mt4gui2.mqh>


// Global Variables
int hwnd = 0;
int tradeBtn = 0;
int GUIposX = 20;
int GUIposY = 20;
double inputLotSize = 0.1;
int deviationPipsInput = 20;
int stopLossDeviationPipsInput = 10;
int lotsList;
int TickerHandle;
int lotSelected = 0;
double UsePoint;
int UseSlippage;
int SlippageInPips = 5;




//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(IsTradeAllowed()== false)
   {
         Alert("Auto trading is not anabled");
   }
   UsePoint = PipPoint(Symbol());
   UseSlippage = GetSlippage(Symbol(),SlippageInPips);
   //---
    EventSetMillisecondTimer(300);
    hwnd = WindowHandle(Symbol(),Period()); 
    BuildInterface(GUIposX,GUIposY);
    return(0);
   //---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   //Clean MT4GUI elements

   if (hwnd>0) { 
      guiRemoveAll(hwnd);    
      guiCleanup(hwnd);
   }
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void start()
  {

   if (guiIsClicked(hwnd,tradeBtn)) {
      TradeNews();
   }
  }
  
void OnTimer() 
{
      if(guiGetListSel(hwnd,lotsList) > (-1) && guiGetListSel(hwnd,lotsList) != lotSelected)
      {
         lotSelected = guiGetListSel(hwnd,lotsList);
         string text = guiGetText(hwnd,lotsList);
         guiSetText(hwnd,inputLotSize,text,16,"Arial");
      }

}
//+------------------------------------------------------------------+

void BuildInterface(int posX, int posY){

    hwnd = WindowHandle(Symbol(),Period());        
    // In case there have GUI Items on chart, lets remove them all
    guiRemoveAll(hwnd);
    // Add a button to Chart by 100,100 Coordinate, Width 100 and Height 30
    // Button caption "Trade"
    tradeBtn = guiAdd(hwnd,"button",205,65,100,28,"Trade");
    // Every GUI Item returns a handle

    //Add Lot size input 
    int lotX = posX + 75;
    int lotY = posY + 40;
    int inputWidth = 40;
    int labelLotInput;
    labelLotInput  = guiAdd(hwnd,"label",posX,lotY + 1,180,20,"LOT SIZE");
    guiSetBgColor(hwnd, labelLotInput, clrGray);
    guiSetTextColor(hwnd, labelLotInput, clrAquamarine);
    
    inputLotSize = guiAdd(hwnd,"text",lotX ,lotY,inputWidth,23,"0.1");   
    guiSetBgColor(hwnd,inputLotSize,Gainsboro);
    guiSetTextColor(hwnd,inputLotSize,Black);
   
    lotsList   = guiAdd(hwnd,"list",lotX + inputWidth + 15, lotY,45,40,"lotsLis");
            guiAddListItem(hwnd,lotsList,"0.1");
            guiAddListItem(hwnd,lotsList,"0.2");
            guiAddListItem(hwnd,lotsList,"0.3");
            guiAddListItem(hwnd,lotsList,"0.4");
            guiAddListItem(hwnd,lotsList,"0.5");
            guiAddListItem(hwnd,lotsList,"1.0");
            guiAddListItem(hwnd,lotsList,"2.0");
            guiSetListSel(hwnd,lotsList,0);
            
     //Add Pending Price of the order input
    int deviationX = posX + 75;
    int deviationY = posY + 65;
    int deviationLabel;
    deviationLabel  = guiAdd(hwnd,"label",posX,deviationY + 1,180,20,"DEVIATION");
    guiSetBgColor(hwnd, deviationLabel, clrGray);
    guiSetTextColor(hwnd, deviationLabel, clrAquamarine);
    
    deviationPipsInput = guiAdd(hwnd,"text",deviationX ,deviationY,inputWidth,23,"20");   
    guiSetBgColor(hwnd,deviationPipsInput,Gainsboro);
    guiSetTextColor(hwnd,deviationPipsInput,Black);
    
    //Add stop loss distance
    int stopDeviatonX = posX + 75;
    int stopDeviationY = posY + 90;
    int stopLossLabel;
    stopLossLabel  = guiAdd(hwnd,"label",posX,stopDeviationY + 1,180,20,"StopLoss");
    guiSetBgColor(hwnd, stopLossLabel, clrGray);
    guiSetTextColor(hwnd, stopLossLabel, clrAquamarine);
    
    stopLossDeviationPipsInput = guiAdd(hwnd,"text",stopDeviatonX ,stopDeviationY,inputWidth,23,"10");   
    guiSetBgColor(hwnd,stopLossDeviationPipsInput,Gainsboro);
    guiSetTextColor(hwnd,stopLossDeviationPipsInput,Black);
   
}

bool TradeNews()
{
   bool successfulTrade = false;

   int slippage = GetSlippage(Symbol(),SlippageInPips);
   double LotSize = StrToDouble(guiGetText(hwnd,inputLotSize));
   double deviation = StrToDouble(guiGetText(hwnd,deviationPipsInput)) * UsePoint; 
   double stopLossDeviation = StrToDouble(guiGetText(hwnd,stopLossDeviationPipsInput)) * UsePoint;

   double askPrice = MarketInfo(Symbol(),MODE_ASK);
   double bidPrice = MarketInfo(Symbol(),MODE_BID);
   
    //buyStop order
   double buyPendingPrice = askPrice + deviation;
   double stopLossBuyPrice = bidPrice - stopLossDeviation;
   
   bool buyOrder = OrderSend(Symbol(), OP_BUYSTOP, LotSize, buyPendingPrice, slippage, stopLossBuyPrice, 0, "BuyOrder_", 666, 0, clrLime);
   
   //sellStop order
   double sellPendingPrice = bidPrice - deviation;
   double stopLossSellPrice = askPrice + stopLossDeviation;
   
   bool sellOrder = OrderSend(Symbol(), OP_SELLSTOP, LotSize, sellPendingPrice, slippage, stopLossSellPrice, 0, "SellOrder_", 666, 0, clrRed);
   
   successfulTrade = (sellOrder && buyOrder);
   return successfulTrade;
}

double PipPoint(string Currency)
{
   double calcPoint = 0;
   int CalcDigits = MarketInfo(Currency,MODE_DIGITS);
   
   if (CalcDigits == 2 || CalcDigits == 3) 
   {
      calcPoint = 0.01;
   }
   else if (CalcDigits == 4 || CalcDigits == 5 )
   {
      calcPoint = 0.0001;
   }
   
   if(calcPoint == 0)
   {
      Print("PipPoint calculation error",GetLastError());
      return -1;
   }
   else
   {
      return calcPoint;
   }
}

int GetSlippage(string Currency, int SlippagePips)
{
   int calcSlippage = -1;
   int CalcDigits = MarketInfo(Currency,MODE_DIGITS);
   
   if (CalcDigits == 2 || CalcDigits == 4) 
   {
      calcSlippage = SlippagePips;
   }
   else if (CalcDigits == 3 || CalcDigits == 5 )
   {
      calcSlippage = SlippagePips * 10;
   }
   
      if(calcSlippage == -1)
   {
      Print("Slippage calculation error",GetLastError());
      return -1;
   }
   else
   {
      return calcSlippage;
   }
}