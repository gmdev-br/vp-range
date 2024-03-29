//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "FXcoder"
#property copyright "© GM, 2020, 2021, 2022, 2023"
#property description "Volume Profile"

#property strict
#property indicator_chart_window
#property indicator_plots 34
#property indicator_buffers 34

#define PUT_IN_RANGE(A, L, H) ((H) < (L) ? (A) : ((A) < (L) ? (L) : ((A) > (H) ? (H) : (A))))
#define COLOR_IS_NONE(C) (((C) >> 24) != 0)
#define RGB_TO_COLOR(R, G, B) ((color)((((B) & 0x0000FF) << 16) + (((G) & 0x0000FF) << 8) + ((R) & 0x0000FF)))
#define ROUND_PRICE(A, P) ((int)((A) / P + 0.5))
#define NORM_PRICE(A, P) (((int)((A) / P + 0.5)) * P)

#include <Math\Stat\Math.mqh>

datetime             data_inicial;         // Data inicial para mostrar as linhas
datetime             data_final;         // Data final para mostrar as linhas

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_VP_CENTER_MODE {
   VP_POC_MODE,            // Top Volume
   VP_VWAP_MODE,           // VWAP
   VP_MEDIAN_MODE          // Median
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_VP_BAR_STYLE {
   VP_BAR_STYLE_LINE,        // Line
   VP_BAR_STYLE_BAR,         // Empty bar
   VP_BAR_STYLE_FILLED,      // Filled bar
   VP_BAR_STYLE_OUTLINE,     // Outline
   VP_BAR_STYLE_COLOR        // Color
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_VP_SOURCE {
   VP_SOURCE_TICKS = 0, // Ticks

   VP_SOURCE_M1 = 1,      // M1 bars
   VP_SOURCE_M2 = 2,      // M2 bars
   VP_SOURCE_M5 = 5,      // M5 bars
   VP_SOURCE_M15 = 15,    // M15 bars
   VP_SOURCE_M30 = 30     // M30 bars
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_REG_SOURCE {
   Open,           // Open
   High,           // High
   Low,             // Low
   Close,         // Close
   Typical,     // Typical
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_MODE_LINE_TYPE {
   Tick,           // Tick
   Percentual           // Percentual
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_VOLUME_TYPE {
   Ticks,           // Ticks (Negócios)
   Real,           // Real (Contratos)
   Financeiro           // Financeiro
};


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_VP_RANGE_MODE {
   VP_RANGE_MODE_BETWEEN_LINES = 0,   // Between lines
   VP_RANGE_MODE_LAST_MINUTES = 1,    // Last minutes
   VP_RANGE_MODE_MINUTES_TO_LINE = 2  // Minitues to line
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_VP_histogram_POSITION {
   VP_histogram_POSITION_WINDOW_LEFT = 0,    // Window left
   VP_histogram_POSITION_WINDOW_RIGHT = 1,   // Window right
   VP_histogram_POSITION_LEFT_OUTSIDE = 2,   // Left outside
   VP_histogram_POSITION_RIGHT_OUTSIDE = 3,  // Right outside
   VP_histogram_POSITION_LEFT_INSIDE = 4,    // Left inside
   VP_histogram_POSITION_RIGHT_INSIDE = 5,   // Right inside
   VP_histogram_POSITION_LEFT_AUTO = 6,      // Automatic left
   VP_histogram_POSITION_RIGHT_AUTO = 7      // Automatic right
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_VP_LABEL_SIDE {
   VP_LABEL_LEFT,          // Left
   VP_LABEL_RIGHT,         // Right
   VP_LABEL_CENTER         // Center
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_VP_MAXVOLUME_MODE {
   VP_MAXVOLUME_POINT_MODE,            // Points
   VP_MAXVOLUME_ZONE_MODE              // Zones
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input group "***************  GERAL ***************"

input ENUM_VP_RANGE_MODE         RangeMode = VP_RANGE_MODE_BETWEEN_LINES;               // MODO
input ENUM_VP_CENTER_MODE        PocMode = VP_POC_MODE;                                 // POC mode: POC, VWAP or Median
input datetime                   DefaultInitialDate = "2022.1.1 9:00:00";            // Data inicial padrão
input datetime                   DefaultFinalDate = -1;                                 // Data final padrão
input int                        RangeMinutes = 50000;                                  // Range minutes
input int                        HistogramPointScaleWIN = 5;                            // Point scale for WIN, IND, IBOV
input double                     HistogramPointScaleWDO = 0.5;                          // Point scale for DOL, WDO
input double                     HistogramPointScaleStock = 0.01;                       // Point scale for stocks
input ENUM_VP_SOURCE             DataSource = VP_SOURCE_M5;                             // Data source
input ENUM_VOLUME_TYPE           VolumeType = Real;                              // Volume type
input int                        WaitMilliseconds = 500000;                             // Timer (milliseconds) for recalculation

input group "***************  HISTOGRAMA ***************"
input color                      HistogramColor = C'0,0,0';                             // Color 1
input color                      HistogramColor2 = C'0,0,0';                            // Color 2
input double                     HistogramWidthPercent = 50;                            // Histogram width, % of chart
input ENUM_VP_histogram_POSITION HistogramPosition = VP_histogram_POSITION_LEFT_AUTO;   // Histogram position
input ENUM_VP_BAR_STYLE          HistogramBarStyle = VP_BAR_STYLE_LINE;                 // Bar style
input int                        HistogramLineWidth = 2;                                // Line width
input int                        FatorDistincao = 4;                                    // Quanto maior, mais distinção entre as cores do histograma
input int                        divisaoPartesTela = 0;
input int                        posicaoPartesTela = 1;

input group "***************  RÓTULOS ***************"
input bool                       ShowSymbol = true;                                     // Mostra o nome do ativo
input color                      SymbolTextColor = clrYellow;                           // Cor do nome do ativo
input int                        SymbolTextSize = 8;                                    // Tamanho do nome do ativo
input bool                       ShowDate = true;                                     // Mostra o nome do ativo
input ENUM_VP_LABEL_SIDE         LabelSide = VP_LABEL_CENTER;                           // Lado do texto
input ENUM_ANCHOR_POINT          LabelAnchor = ANCHOR_LEFT;                             // Posicionamento do texto
input bool                       ShowPrice = true;                                      // Mostrar preços
input bool                       ShowLevel = true;                                      // Mostrar percentuais
input int                        FontSize = 8;                                          // Tamanho do texto


input group "***************  DELIMITADORES ***************"
input string                     Id = "+vpr";                                          // IDENTIFICADOR
input color                      TimeFromColor = clrLime;                              // ESQUERDO: cor
input int                        TimeFromWidth = 1;                                    // ESQUERDO: largura
input ENUM_LINE_STYLE            TimeFromStyle = STYLE_DASH;                           // ESQUERDO: estilo
input color                      TimeToColor = clrRed;                                 // DIREITO: cor
input int                        TimeToWidth = 1;                                      // DIREITO: largura
input ENUM_LINE_STYLE            TimeToStyle = STYLE_DASH;                             // DIREITO: estilo
input bool                       AutoLimitLines = true;                                // Automatic limit left and right lines
input bool                       FitToLines = true;                                    // Automatic fit histogram inside lines
input bool                       KeepRightLineUpdated = true;                          // Automatic update of the rightmost line
input int                        ShiftCandles = 6;                                     // Distance in candles to adjust on automatic

input group "***************  ÁREA DE VALOR ***************"
// percentuais
input string                     ValueAreaPercentages1     = "70";   // PERCENTUAIS 1
input string                     ValueAreaPercentages2     = "";   // PERCENTUAIS 2
input string                     ValueAreaPercentages3     = "";   // PERCENTUAIS 3
input string                     ValueAreaPercentages4     = "";   // PERCENTUAIS 4
input string                     ValueAreaProjPercentages     = "110,120,130,150";     // PROJEÇÕES
input double                     ValueAreaPercentageCalculateProj = 99.95;                // PROJEÇÕES: ponto referência
input color                      PocColor = clrYellow;                                 // POC: Cor
input ENUM_LINE_STYLE            PocStyle             = STYLE_DASH;                    // POC: Estilo
input int                        PocWidth              = 1;                            // POC: Largura
//input group "***************  VAH ***************"
input color                      ValueAreaHighColor    = clrGreen;                     // VAH: Cor
input ENUM_LINE_STYLE            ValueAreaHighStyle   = STYLE_DASH;                    // VAH: Estilo
input int                        ValueAreaHighWidth    = 2;                            // VAH: Largura
//input group "***************  VAL ***************"
input color                      ValueAreaLowColor    = clrRed;                        // VAL: Cor
input ENUM_LINE_STYLE            ValueAreaLowStyle   = STYLE_DASH;                     // VAL: Estilo
input int                        ValueAreaLowWidth    = 2;                             // VAL: Largura

input double                     IntervalStep = 50;                                    // INTERVALO: tamanho
input ENUM_MODE_LINE_TYPE        IntervalLineType = Tick;                             // INTERVALO: tipo
input color                      IntervalColor = clrNONE;                              // INTERVALO: cor
input int                        IntervalLineWidth = 1;                                // INTERVALO: largura
input ENUM_LINE_STYLE            IntervalLevelStyle = STYLE_SOLID;                     // INTERVALO: estilo

input long                       ShowNVolumes = 0;                                     // MAX: mostrar os N maiores volumes
input ENUM_VP_MAXVOLUME_MODE     MaxVolumeMode = VP_MAXVOLUME_ZONE_MODE;               // MAX: modo (zona / pontos)
input int                        DistanceBetweenMaxVolumes = 50;                       // MAX: distância entre pontos
input color                      MaxColor = clrOrange;                                 // MAX: Color
input ENUM_LINE_STYLE            MaxStyle             = STYLE_DASH;                    // MAX: Style
input int                        MaxWidth              = 1;                            // MAX: Width

input color                      MedianColor                       = clrBlueViolet;    // MEDIANA: Cor
input ENUM_LINE_STYLE            MedianLineStyle = STYLE_DOT;                          // MEDIANA: Estilo
input int                        MedianLineWidth              = 1;                     // MEDIANA: Largura

input color                      VwapColor = clrCyan;                                  // VWAP: Cor
input ENUM_LINE_STYLE            VwapLineStyle = STYLE_DOT;                            // VWAP: Estilo
input int                        VwapLineWidth              = 1;                       // VWAP: Largura

input group "***************  REGRESSÃO LINEAR ***************"
input bool                       EnableRegression = false;                              // REGRESSÃO: ativa / desativa
input ENUM_REG_SOURCE            RegressionSource = Close;                             // REGRESSÃO: fonte de dados
input color                      RegColor             = clrMagenta;                    // REGRESSÃO: cor
input int                        RegWidth            = 1;                              // REGRESSÃO: largura
input ENUM_LINE_STYLE            RegStyle             = STYLE_SOLID;                   // REGRESSÃO: estilo
input double                     ChannelWidth         = 1;                             // CANAL DE REGRESSÃO: multiplicador do desvio
input double                     DeviationsNumber          = 1;                        // CANAL DE REGRESSÃO: número de desvios
input double                     DeviationsOffset          = 0;                        // CANAL DE REGRESSÃO: deslocamento
input color                      RegChannelColor             = clrMagenta;             // CANAL DE REGRESSÃO: cor
input int                        RegChannelWidth            = 1;                       // CANAL DE REGRESSÃO: largura
input ENUM_LINE_STYLE            RegChannelStyle             = STYLE_DOT;              // CANAL DE REGRESSÃO: estilo

input group "***************  OUTRAS ***************"
input bool                       EnableTooltip = true;                                  // Exibir balões de volume com o mouse
input bool                       EnablePocSimulator = false;                             // Exibir o simulador de POC
input bool                       EnableMiniMode = false;                                // Modo de exibição de minigráficos
input bool                       EnableEvents = true;                                   // Ativa os eventos de teclado
input bool                       ShowHorizon = true;                                    // TICKS: Show data horizon
input color                      HorizonColor = clrYellow;                              // TICKS: Horizon Line color
input bool debug = false;
input bool inputAgrupar = false;
string ativo1 = "";
string ativo2 = "";
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int ZOrderHistogram = 0;
int ZOrderText = 500;
int ZOrderInteracts = 1000;

double Zoom = 0;
double totalVolume = 0;
double histogramWidthBars;

long intervals[];
double arrayVolumesMain[], arrayVolumesSec[], arrayVolumesMerged[], sortedMaxUserVolumes[];
long indiceVolumesUsuario[];
long TopNVolumes, totalEntriesMain, totalEntriesSec, totalEntriesMerged;
long indexmaxvolume = 0;
double maxVolume = 0;
double fatorVolume = 1;
double arrayPrices1[], arrayPrices2[];

int heightScreen;
int widthScreen;
int totalRates;
double intervalMaxMain, intervalMinMain, intervalMaxSec, intervalMinSec, intervalMaxMerged, intervalMinMerged;
long intervalMaxIndexMain, intervalMinIndexMain, intervalMaxIndexSec, intervalMinIndexSec, intervalMaxIndexMerged, intervalMinIndexMerged;
int HistogramPointScale_calculated;     // Will have to be calculated based number digits in a quote if HistogramPointScale input is 0.
int DigitsM;                        // Number of digits normalized based on HistogramPointScale_calculated.
double onetick;                     // One normalized pip.
double vwapprice = 0, medianprice = 0, pocprice = 0;

datetime timeFrom;
datetime timeTo;
datetime timeLeft;
datetime minimumDate;
datetime maximumDate;
datetime txtData;

long movestep;
long medianPosMain, vwapPosMain, indexpoc;
long totalCandles = 0;
int precisaoVolume;
int valueAreaBartTo;
datetime valueAreaTimeTo;

string btnHide, btnSim, btnTimeFrom, btnTimeTo, btnIntervals, btnHeatMap, btnRegression, txtAno;
string volumeSuffix;
bool btnHideClicked = true;
bool btnSimClicked = false;
bool btnTimeFromClicked = false;
bool btnTimeToClicked = false;
bool btnIntervalsClicked = true;
bool btnHeatMapClicked = false;
bool btnRegressionClicked = false;
bool firstRun = true;
bool compartilhaDelimitador = false;
bool temPrioridade = true;
bool onlyRedraw = false;
bool agrupar = false;

double regBuffer[];
double stDevBuffer[];
double upChannel1[], upChannel2[], upChannel3[], upChannel4[], upChannel5[], upChannel6[], upChannel7[], upChannel8[];
double upChannel9[], upChannel10[], upChannel11[], upChannel12[], upChannel13[], upChannel14[], upChannel15[], upChannel16[];
double downChannel1[], downChannel2[], downChannel3[], downChannel4[], downChannel5[], downChannel6[], downChannel7[], downChannel8[];
double downChannel9[], downChannel10[], downChannel11[], downChannel12[], downChannel13[], downChannel14[], downChannel15[], downChannel16[];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnInit() {

   _prefix = Id + " m" + IntegerToString(RangeMode) + " ";
   _timeFromLine = Id + "-from";
   _timeToLine = Id + "-to";
   _simLine = Id + "-sim";

   data_inicial = DefaultInitialDate;
   if (KeepRightLineUpdated && ((DefaultFinalDate == -1) || (DefaultFinalDate > iTime(_Symbol, PERIOD_CURRENT, 0))))
      data_final = iTime(_Symbol, PERIOD_CURRENT, 0) + PeriodSeconds(PERIOD_CURRENT) * ShiftCandles;

   if (inputAgrupar && (Symbol() == "IND$" || Symbol() == "WIN$" || Symbol() == "DOL$" || Symbol() == "WDO$" )) {
      agrupar = true;
   } else {
      agrupar = false;
   }

   if (Symbol() == "IND$" || Symbol() == "WIN$") {
      ativo1 = "IND$";
      ativo2 = "WIN$";
   } else if (Symbol() == "DOL$" || Symbol() == "WDO$" ) {
      ativo1 = "DOL$";
      ativo2 = "WDO$";
   }

   if ((Symbol() == "IND$" || Symbol() == "WIN$" || Symbol() == "IBOV")) {
      onetick = 5;
      if (HistogramPointScaleWIN == 0) { // quando o intervalo estiver configurado para automático
         _histogramPoint = _Point * onetick;
         movestep = 1;
      } else { // quando o intervalo estiver configurado para personalizado
         _histogramPoint = _Point * HistogramPointScaleWIN;
         movestep = 1;
         if ((HistogramPointScaleWIN == 1) && (DataSource == VP_SOURCE_TICKS)) movestep = 5;
      }
   } else if ((Symbol() == "DOL$" || Symbol() == "WDO$")) {
      onetick = 0.5;
      if (HistogramPointScaleWDO == 0) { // quando o intervalo estiver configurado para automático
         _histogramPoint = onetick;
         movestep = 1;
      } else { // quando o intervalo estiver configurado para personalizado
         _histogramPoint = HistogramPointScaleWDO;
         movestep = 1;
         if (DataSource == VP_SOURCE_TICKS)
            movestep = 5;
      }
   } else {
      if (HistogramPointScaleStock == 0) { // quando o intervalo estiver configurado para automático
         _histogramPoint = _Point;
         movestep = 1;
      } else { // quando o intervalo estiver configurado para personalizado
         _histogramPoint = HistogramPointScaleStock;
         movestep = 1;
         if (DataSource == VP_SOURCE_TICKS) movestep = 5;
      }
      onetick = 0.01;
   }


   if (VolumeType == Ticks) {
      volumeSuffix = "Negócios";
      precisaoVolume = 3;
   } else if (VolumeType == Real) {
      volumeSuffix = "Contratos";
      precisaoVolume = 3;
   } else if (VolumeType == Financeiro) {
      volumeSuffix = "R$";
      precisaoVolume = 2;
   }

   if (IntervalLineType == Ticks)
      _intervalStep = IntervalStep;
   else
      _intervalStep = (int)iClose(_Symbol, PERIOD_D1, 1) * (IntervalStep);

//_intervalStep=IntervalStep;

   _histogramBarStyle = HistogramBarStyle;
   _histogramPointDigits = GetPointDigits(_histogramPoint);

   _defaultHistogramColor1 = HistogramColor;
   _defaultHistogramColor2 = HistogramColor2;

   _histogramLineWidth = HistogramLineWidth;

   _timeToColor = TimeToColor;
   _timeFromColor = TimeFromColor;
   _timeToWidth = TimeToWidth;
   _timeFromWidth = TimeFromWidth;

   _intervalColor = IntervalColor;
   _maxColor = MaxColor;

   _vwapColor = VwapColor;
   _vwapLineWidth = VwapLineWidth;
   _vwapLineStyle = MedianLineStyle;

   _intervalLineWidth = IntervalLineWidth;

   _medianColor = MedianColor;
   _medianLineWidth = MedianLineWidth;
   _medianLineStyle = MedianLineStyle;

   _intervalLineColor = IntervalColor;
   _intervalLineStyle = IntervalLevelStyle;

   _showHistogram = !(ColorIsNone(_defaultHistogramColor1) && ColorIsNone(_defaultHistogramColor2));
   _showIntervals = !ColorIsNone(_intervalColor);
   _showMax = !ColorIsNone(_maxColor);
   _showMedian = !ColorIsNone(_medianColor);
   _showVwap = !ColorIsNone(_vwapColor);

   _zoom = MathAbs(Zoom);

   _anchor_poc = LabelAnchor;
   _anchor_va = LabelAnchor;

   _updateTimer = new MillisecondTimer(WaitMilliseconds, false);

   _dataPeriod = GetDataPeriod(DataSource);

   if (EnableMiniMode) // para exibir o canal de regressão, é preciso forçar a ativação
      btnRegressionClicked = true;

   btnHide = "btnHide";
   btnTimeFrom = "btnTimeFrom";
   btnTimeTo = "btnTimeTo";
   btnSim = "btnSim";
   btnIntervals = "btnIntervals";
   btnHeatMap = "btnHeatMap";
   btnRegression = "btnRegression";
   txtAno = "txtAno";

   if (!EnableMiniMode) {
      createButton(btnHide, 0, 15, 15, 15, PocColor, "H", ALIGN_CENTER, false, true, false, false, "Esconde os botões");
      ObjectSetString(0, btnHide, OBJPROP_TEXT, "S");
   }

   IndicatorSetString(INDICATOR_SHORTNAME, "VPR-" + Id);

   PrepareRegression();

   firstRun = false;
   UpdateSymbol();

//verifyDates();
   ChartRedraw();
}

void verifyDates() {

   minimumDate = iTime(_Symbol, PERIOD_CURRENT, iBars(_Symbol, PERIOD_CURRENT) - 2);
   maximumDate = iTime(_Symbol, PERIOD_CURRENT, 0);

   timeFrom = GetObjectTime1(_timeFromLine);
   timeTo = GetObjectTime1(_timeToLine);

   if (txtData > 0)
      data_inicial = txtData;
   else
      data_inicial = DefaultInitialDate;

   if (KeepRightLineUpdated && ((DefaultFinalDate == -1) || (DefaultFinalDate > iTime(_Symbol, PERIOD_CURRENT, 0))))
      data_final = iTime(_Symbol, PERIOD_CURRENT, 0) + PeriodSeconds(PERIOD_CURRENT) * ShiftCandles;

   if ((timeFrom == 0) || (timeTo == 0)) {
      timeFrom = data_inicial;
      timeTo = data_final;
      DrawVLine(_timeFromLine, timeFrom, _timeFromColor, _timeFromWidth, TimeFromStyle, true, false, true, 1000);
      DrawVLine(_timeToLine, timeTo, _timeToColor, _timeToWidth, TimeToStyle, true, false, true, 1000);
   }

   if (ObjectGetInteger(0, _timeFromLine, OBJPROP_SELECTED) == false) {
      timeFrom = data_inicial;
   }

   if (ObjectGetInteger(0, _timeToLine, OBJPROP_SELECTED) == false) {
      timeTo = data_final;
   }

   if ((timeFrom < minimumDate) || (timeFrom > maximumDate))
      timeFrom = minimumDate;

   if ((timeTo >= maximumDate) || (timeTo < minimumDate))
      timeTo = maximumDate + PeriodSeconds(PERIOD_CURRENT) * ShiftCandles;



   int u = 0;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdateSymbol() {
   if (ShowSymbol) {
      ObjectCreate(0, "ativo", OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, "ativo", OBJPROP_XDISTANCE, 0);
      ObjectSetInteger(0, "ativo", OBJPROP_YDISTANCE, 0);
      ObjectSetString(0, "ativo", OBJPROP_TEXT, _Symbol + ":" + GetTimeFrame(Period()));
      ObjectSetInteger(0, "ativo", OBJPROP_FONTSIZE, SymbolTextSize);
      ObjectSetInteger(0, "ativo", OBJPROP_COLOR, SymbolTextColor);
      ObjectSetInteger(0, "ativo", OBJPROP_BACK, true);
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdateDate() {
   if (ShowDate) {
      ObjectCreate(0, "data-" + Id, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, "data-" + Id, OBJPROP_TIME, timeLeft);
      ObjectSetInteger(0, "data-" + Id, OBJPROP_YDISTANCE, 10);
      ObjectSetString(0, "data-" + Id, OBJPROP_TEXT, TimeToString (GetObjectTime1(_timeFromLine), TIME_DATE));
      ObjectSetInteger(0, "data-" + Id, OBJPROP_FONTSIZE, SymbolTextSize);
      ObjectSetInteger(0, "data-" + Id, OBJPROP_COLOR, SymbolTextColor);
      ObjectSetInteger(0, "data-" + Id, OBJPROP_BACK, false);
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void createButton(string name, int x, int y, int largura, int altura, color cor, string texto, ENUM_ALIGN_MODE alinhamento, bool back, bool hidden, bool selectable, bool selected, string tooltip) {

   ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_BUTTON, 0, x, 0);
   ObjectSetString(0, name, OBJPROP_NAME, name);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, altura);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, largura);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, cor);
   ObjectSetString(0, name, OBJPROP_TEXT, texto);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, selectable);
   ObjectSetInteger(0, name, OBJPROP_ALIGN, alinhamento);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, ZOrderInteracts);
   ObjectSetInteger(0, name, OBJPROP_SELECTED, selected);
   ObjectSetInteger(0, name, OBJPROP_STATE, 0, selected);
   ObjectSetString(0, name, OBJPROP_TOOLTIP, tooltip);

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void createTxt(string name, int x, int y, int largura, int altura, color cor, string texto, ENUM_ALIGN_MODE alinhamento, bool back, bool hidden, bool selectable, bool selected, string tooltip) {

   ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_EDIT, 0, x, 0);
   ObjectSetString(0, name, OBJPROP_NAME, name);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, altura);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, largura);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, cor);
   ObjectSetString(0, name, OBJPROP_TEXT, texto);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, selectable);
   ObjectSetInteger(0, name, OBJPROP_ALIGN, alinhamento);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, ZOrderInteracts);
   ObjectSetInteger(0, name, OBJPROP_SELECTED, selected);
   ObjectSetInteger(0, name, OBJPROP_STATE, 0, selected);
   ObjectSetString(0, name, OBJPROP_TOOLTIP, tooltip);

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double & price[]) {
//CheckTimer();
   return(1);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   CheckTimer();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {

   ObjectsDeleteAll(0, _prefix);
   ObjectDelete(0, "ativo");

   if(UninitializeReason() == REASON_REMOVE) {
      ObjectDelete(0, _timeFromLine);
      ObjectDelete(0, _timeToLine);
   }

   delete(_updateTimer);
   ChartRedraw();

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckTimer() {
   EventKillTimer();

   if(_updateTimer.Check() || !_lastOK) {
      _lastOK = Update();
      ChartRedraw();
      if (debug) Print("VP-Range ok");

      EventSetMillisecondTimer(WaitMilliseconds);

      _updateTimer.Reset();
   } else {
      EventSetTimer(1);
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Update() {

   ObjectsDeleteAll(0, _prefix);
   verifyDates();

   totalRates = SeriesInfoInteger(_Symbol, PERIOD_CURRENT, SERIES_BARS_COUNT);

   if(RangeMode == VP_RANGE_MODE_BETWEEN_LINES) {

      datetime shiftedTimeTo;

      if (EnableMiniMode) //se o modo minichart estiver ativado, forçamos a linha timeTo para o fim do gráfico, já que o indicador minichart não atualiza as linhas corretamente
         timeTo = iTime(_Symbol, PERIOD_CURRENT, 0) + PeriodSeconds(PERIOD_CURRENT) * ShiftCandles;

      ObjectSetInteger(0, _timeFromLine, OBJPROP_TIME, 0, timeFrom);
      ObjectSetInteger(0, _timeToLine, OBJPROP_TIME, 0, timeTo);

      if(timeFrom > timeTo)
         Swap(timeFrom, timeTo);

   } else if(RangeMode == VP_RANGE_MODE_MINUTES_TO_LINE) {
      timeTo = GetObjectTime1(_timeToLine);
      int bar;

      if(timeTo == 0) {
         int leftBar = WindowFirstVisibleBar();
         int rightBar = WindowFirstVisibleBar() - WindowBarsPerChart();
         int barRange = leftBar - rightBar;

         bar = MathMax(0, leftBar - barRange / 3);
         timeTo = GetBarTime(bar);
      } else {
         bar = iBarShift(_Symbol, _Period, timeTo);
      }

      bar += RangeMinutes / (PeriodSeconds(_Period) / 60);
      timeFrom = GetBarTime(bar);

      DrawVLine(_timeFromLine, timeFrom, _timeFromColor, _timeFromWidth, TimeFromStyle, true, false, true, ZOrderInteracts);

      if(ObjectFind(0, _timeToLine) == -1) {
         DrawVLine(_timeToLine, timeTo, _timeToColor, _timeToWidth, TimeToStyle, true, false, true, ZOrderInteracts);
      }

      ObjectDisable(0, _timeFromLine);
      ObjectEnable(0, _timeToLine);
   } else if(RangeMode == VP_RANGE_MODE_LAST_MINUTES) {
      timeFrom = GetBarTime(RangeMinutes - 1, PERIOD_M1);
      timeTo = GetBarTime(-1, PERIOD_M1);

      ObjectDelete(0, _timeFromLine);
      ObjectDelete(0, _timeToLine);
   } else {
      return(false);
   }

   if(ShowHorizon) {
      datetime horizon = GetHorizon(DataSource, _dataPeriod);
      DrawHorizon(_prefix + "hz", horizon);
   }

   int barFrom, barTo;

   if(!GetRangeBars(timeFrom, timeTo, barFrom, barTo))
      return(false);

   _updateOnTick = barTo < 0;

   long count;

   if(DataSource == VP_SOURCE_TICKS) {
      count = GetHistogramByTicks(timeFrom, timeTo - 1, _histogramPoint, _dataPeriod, VolumeType, arrayVolumesMerged);
      if(count <= 0)
         return(false);
   } else {


      if (!agrupar) {
         count = GetHistogram(_Symbol, true, timeFrom, timeTo - 1, _histogramPoint, _dataPeriod, VolumeType, arrayVolumesMerged);
         if(count <= 0)
            return(false);
         totalEntriesMerged = ArraySize(arrayVolumesMerged);
      } else {
         count = GetHistogram(ativo1, true, timeFrom, timeTo - 1, _histogramPoint, _dataPeriod, VolumeType, arrayVolumesMain);
         if(count <= 0)
            return(false);

         count = GetHistogram(ativo2, false, timeFrom, timeTo - 1, _histogramPoint, _dataPeriod, VolumeType, arrayVolumesSec);
         if(count <= 0)
            return(false);

         totalEntriesMain = ArraySize(arrayVolumesMain);
         totalEntriesSec = ArraySize(arrayVolumesSec);

         double maxPriceMerged, minPriceMerged;

         if (intervalMaxMain >= intervalMaxSec)
            intervalMaxMerged = intervalMaxMain;
         else
            intervalMaxMerged = intervalMaxSec;

         if (intervalMinMain <= intervalMinSec)
            intervalMinMerged = intervalMinMain;
         else
            intervalMinMerged = intervalMinSec;

         totalEntriesMerged = MathAbs(intervalMaxMerged - intervalMinMerged) / _histogramPoint + 1;

         //ArrayReverse(arrayVolumesMain);
         //ArrayReverse(arrayVolumesSec);
         //ArrayReverse(arrayPrices1);
         //ArrayReverse(arrayPrices2);

         int entriesToAddOnMainTop = MathAbs(intervalMaxMerged - intervalMaxMain) / _histogramPoint;
         int entriesToAddOnMainBottom = MathAbs(intervalMinMerged - intervalMinMain) / _histogramPoint;

         int entriesToAddOnSecTop = MathAbs(intervalMaxMerged - intervalMaxSec) / _histogramPoint;
         int entriesToAddOnSecBottom = MathAbs(intervalMinMerged - intervalMinSec) / _histogramPoint;

         int dif = MathAbs(ArraySize(arrayVolumesMain) - ArraySize(arrayVolumesSec));

         double tempMain[], tempSec[];
         ArrayFree(arrayVolumesMerged);
         ArrayResize(tempMain, totalEntriesMain + entriesToAddOnMainTop + entriesToAddOnMainBottom);
         ArrayResize(tempSec, totalEntriesSec + entriesToAddOnSecTop + entriesToAddOnSecBottom);
         ArrayResize(arrayVolumesMerged, totalEntriesMerged);

         ArrayCopy(tempMain, arrayVolumesMain, entriesToAddOnMainTop, 0);
         ArrayCopy(tempSec, arrayVolumesSec, entriesToAddOnSecTop, 0);
         ArrayCopy(arrayVolumesMain, tempMain);
         ArrayCopy(arrayVolumesSec, tempSec);



         //for (long i = totalEntriesMerged - 1; i >= 0 ; i--) {
         for (long i = 0; i <= totalEntriesMerged - 1; i++) {
            arrayVolumesMerged[i] = arrayVolumesMain[i] + arrayVolumesSec[i];
            double price = NormalizeDouble(intervalMaxMerged - i * _histogramPoint, _histogramPointDigits);
            int u = 0;
         }

         //ArrayReverse(arrayVolumesMerged);
         ArrayFree(arrayVolumesMain);
         ArrayFree(arrayVolumesSec);
      }
   }

//totalEntriesMerged = ArraySize(arrayVolumesMerged);




   TopNVolumes = (long)(totalEntriesMerged * 0.1);

   if (ShowNVolumes > 0) { // somente calculamos se quisermos exibir algum volume máximo no histograma
      ArrayResize(indiceVolumesUsuario, ShowNVolumes);
      ArrayResize(sortedMaxUserVolumes, ArraySize(arrayVolumesMerged));
      ArrayCopy(sortedMaxUserVolumes, arrayVolumesMerged);
   }

// precisamos forçar o cálculo da mediana para calcularmos o poc logo mais
   medianPosMain = ArrayMedian(arrayVolumesMerged);
   vwapPosMain = HistogramVwap(arrayVolumesMerged, _histogramPoint);

   long maxPos = -1; ///////////////////// começamos a contar do POC????????????
   if (_showMax && ShowNVolumes > 0) { // somente calculamos se quisermos exibir algum volume máximo no histograma
      if (MaxVolumeMode == VP_MAXVOLUME_POINT_MODE) {
         for (long n = 0; n < ArraySize(indiceVolumesUsuario); n++) {
            maxPos = _showMax ? ArrayMax(sortedMaxUserVolumes) : -1;
            indiceVolumesUsuario[n] = maxPos;
            for (long i = 0; i < ArraySize(sortedMaxUserVolumes); i++) {
               if (i == maxPos)
                  sortedMaxUserVolumes[i] = 0;
            }
         }
      } else if (MaxVolumeMode == VP_MAXVOLUME_ZONE_MODE) {
         for (long n = 0; n < ArraySize(indiceVolumesUsuario); n++) {
            maxPos = _showMax ? ArrayMax(sortedMaxUserVolumes) : -1;
            indiceVolumesUsuario[n] = maxPos;
            for (long i = 0; i < ArraySize(sortedMaxUserVolumes); i++) {
               if ((i >= maxPos - DistanceBetweenMaxVolumes) && (i <= maxPos + DistanceBetweenMaxVolumes))
                  sortedMaxUserVolumes[i] = 0;
            }
         }
      }
   }

   int primeiroCandle = WindowFirstVisibleBar();
   int ultimoCandle = WindowFirstVisibleBar() - WindowBarsPerChart();
   int lineFromPosition = 0, lineToPosition = 0;
   if (FitToLines == true) {
      lineFromPosition = iBarShift(_Symbol, PERIOD_CURRENT, GetObjectTime1(_timeFromLine), 0);
      lineToPosition = iBarShift(_Symbol, PERIOD_CURRENT, GetObjectTime1(_timeToLine), 0);
   }

   string prefix = _prefix + (string)((int)RangeMode) + " ";
//if ((HistogramPosition == VP_histogram_POSITION_LEFT_INSIDE)
//      || (HistogramPosition == VP_histogram_POSITION_RIGHT_INSIDE)) {
//   histogramWidthBars = (barFrom - barTo);
//} else {
   if (FitToLines == true) {
      int posicaoInicial = WindowBarsPerChart() - (WindowBarsPerChart() - primeiroCandle);
      int posicaoFinal;
      if (lineFromPosition < primeiroCandle)  // precisamos escolher qual barra será o ponto de partida para o desenho do hstograma: delimitador inicial ou o primeiro candle visível
         posicaoInicial = lineFromPosition;
      else
         posicaoInicial = primeiroCandle;

      if (lineToPosition < ultimoCandle)
         posicaoFinal = ultimoCandle;
      else
         posicaoFinal = lineToPosition;

      //histogramWidthBars = (int)(MathAbs(lineToPosition - lineFromPosition) *(HistogramWidthPercent/100.0));
      histogramWidthBars = (int)(MathAbs(posicaoFinal - posicaoInicial)) * (HistogramWidthPercent / 100.0);
   } else {
      histogramWidthBars = WindowBarsPerChart() * (HistogramWidthPercent / 100.0);
   }
//}

   indexmaxvolume = ArrayMaximum(arrayVolumesMerged);
//   double escalaMax = ChartGetDouble(0, CHART_PRICE_MAX);
//   double escalaMin = ChartGetDouble(0, CHART_PRICE_MIN);
//   int indexEscalaMax, indexEscalaMin, numeroItens;
//   double arrayVisibleVolumes[];
//   if (escalaMax >= intervalMaxMerged)
//      indexEscalaMax = 0;
//   else
//      indexEscalaMax = 0 + (MathAbs(intervalMaxMerged - escalaMax)  / _histogramPoint);
//
//   if (escalaMin <= intervalMinMerged)
//      indexEscalaMin = ArraySize(arrayVolumesMerged) - 1;
//   else
//      indexEscalaMin = (ArraySize(arrayVolumesMerged) - 1) - (MathAbs(escalaMin - intervalMinMerged) / _histogramPoint);
//
//   numeroItens = indexEscalaMin - indexEscalaMax + 1;
//   ArrayFree(arrayVisibleVolumes);
//   ArrayResize(arrayVisibleVolumes, indexEscalaMin - indexEscalaMax + 1);
//   ArrayCopy(arrayVisibleVolumes, arrayVolumesMerged, 0, indexEscalaMax, numeroItens);
//
   maxVolume = arrayVolumesMerged[indexmaxvolume];
//   //double maxVisibleVolume = arrayVisibleVolumes[ArrayMaximum(arrayVisibleVolumes)]; ajustar
//   double maxVisibleVolume =0;
//   Print("maxVolume: "+ maxVolume);
//
//   Print("maxVolume: "+ maxVisibleVolume);
//   if (ArraySize(arrayVisibleVolumes) > 0){
//      maxVisibleVolume = arrayVisibleVolumes[ArrayMaximum(arrayVisibleVolumes)];
//
//      } else {
//      maxVisibleVolume = maxVolume;
//      }


   if(maxVolume == 0)
      maxVolume = 1;

//double teste =   ObjectGetInteger(0, "+vpr m0 0 4.65 poc", OBJPROP_TIME, 0);

   double zoom = _zoom > 0 ? _zoom : (histogramWidthBars / maxVolume);

   int drawBarFrom = 0, drawBarTo = 0;

   if(HistogramPosition == VP_histogram_POSITION_WINDOW_LEFT) {
      zoom = _zoom > 0 ? _zoom : (histogramWidthBars / maxVolume);
      drawBarFrom = WindowFirstVisibleBar();
      drawBarTo = (int)(drawBarFrom - zoom * maxVolume);
      drawBarTo = 0;
   } else if(HistogramPosition == VP_histogram_POSITION_WINDOW_RIGHT) {

      drawBarFrom = WindowFirstVisibleBar() - WindowBarsPerChart();
      drawBarTo = (int)WindowFirstVisibleBar();
      histogramWidthBars = MathAbs(drawBarFrom - drawBarTo);
      //zoom = _zoom > 0 ? _zoom : (histogramWidthBars / maxVisibleVolume); //ajustar
      zoom = _zoom > 0 ? _zoom : (histogramWidthBars / maxVolume);
      int u = 0;

   } else if(HistogramPosition == VP_histogram_POSITION_LEFT_OUTSIDE) {
      drawBarFrom = barFrom;
      drawBarTo = (int)(drawBarFrom + zoom * maxVolume);
   } else if(HistogramPosition == VP_histogram_POSITION_RIGHT_OUTSIDE) {
      drawBarFrom = barTo;
      drawBarTo = (int)(drawBarFrom - zoom * maxVolume);
   } else if(HistogramPosition == VP_histogram_POSITION_LEFT_INSIDE) {
      drawBarFrom = barFrom;
      drawBarTo = barTo;
   } else if (HistogramPosition == VP_histogram_POSITION_RIGHT_INSIDE) {
      drawBarFrom = barTo;
      drawBarTo = barFrom;

   } else if (HistogramPosition == VP_histogram_POSITION_LEFT_AUTO) {
      if (barFrom <= primeiroCandle)
         drawBarFrom = barFrom;
      else
         drawBarFrom = primeiroCandle;

      if (FitToLines == true) {
         if (lineToPosition < ultimoCandle)
            drawBarTo = ultimoCandle;
         else
            drawBarTo = lineToPosition;

      } else {
         drawBarTo = (int)(drawBarFrom - zoom * maxVolume);
      }
   } else if (HistogramPosition == VP_histogram_POSITION_RIGHT_AUTO) {

      if (barTo >= ultimoCandle)
         drawBarFrom = barTo;
      else
         drawBarFrom = ultimoCandle;

      drawBarTo = (int)(drawBarFrom + zoom * maxVolume);
   }

   if (divisaoPartesTela > 0) {


      int ncandles = MathAbs(ultimoCandle - primeiroCandle);
      int offset = (int)(ChartGetDouble(0, CHART_SHIFT_SIZE) / 100 * ncandles);
      //Print("offset: "+ offset);
      drawBarFrom = ncandles - (ncandles / divisaoPartesTela * (posicaoPartesTela - 1)) - offset;
      drawBarTo = ncandles - (ncandles / divisaoPartesTela * (posicaoPartesTela)) - offset;
      histogramWidthBars = MathAbs(drawBarFrom - drawBarTo);
      timeFrom = iTime(_Symbol, PERIOD_CURRENT, drawBarFrom);
      timeTo = iTime(_Symbol, PERIOD_CURRENT, drawBarTo);
      timeLeft = timeFrom;
      zoom = _zoom > 0 ? _zoom : (histogramWidthBars / maxVolume);
      ObjectSetInteger(0, _timeFromLine, OBJPROP_COLOR, clrNONE);
      ObjectSetInteger(0, _timeToLine, OBJPROP_COLOR, clrNONE);
      UpdateDate();
   } else {
      timeLeft = GetBarTime(WindowFirstVisibleBar());

      if (timeFrom > timeLeft) {
         timeLeft = timeFrom;
      }
   }

   if(LabelSide == VP_LABEL_LEFT) {
      if (HistogramPosition == VP_histogram_POSITION_RIGHT_AUTO || HistogramPosition == VP_histogram_POSITION_WINDOW_RIGHT)
         _labelSide = timeLeft;
      else
         _labelSide = timeLeft;
   } else if(LabelSide == VP_LABEL_CENTER) {
      int barra;
      if (HistogramPosition == VP_histogram_POSITION_RIGHT_AUTO || HistogramPosition == VP_histogram_POSITION_WINDOW_RIGHT)
         barra = drawBarTo - MathAbs(drawBarFrom - drawBarTo) / 2;
      else
         barra = drawBarFrom - MathAbs(drawBarFrom - drawBarTo) / 2;
      //Print("drawBarFrom: " +drawBarFrom);
      //Print("drawBarTo: " +drawBarTo);
      _labelSide = iTime(_Symbol, PERIOD_CURRENT, barra);
   } else if(LabelSide == VP_LABEL_RIGHT) {
      if (HistogramPosition == VP_histogram_POSITION_RIGHT_AUTO || HistogramPosition == VP_histogram_POSITION_WINDOW_RIGHT)
         _labelSide = iTime(_Symbol, PERIOD_CURRENT, drawBarFrom);
      else
         _labelSide = iTime(_Symbol, PERIOD_CURRENT, drawBarTo);
   }

   DrawHistogram(prefix, arrayVolumesMerged, drawBarFrom, drawBarTo, zoom, intervals, indiceVolumesUsuario, medianPosMain, vwapPosMain);

   CalculateEssentialPoints();
   ProcessValueArea();
   CalculateRegression(barFrom, barTo, RegressionSource);

   _lastOK = true;
//ChartRedraw();
   return(true);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalculateEssentialPoints() {

   if(_showVwap == true) {
      vwapprice = NormalizeDouble(intervalMinMerged + vwapPosMain * _histogramPoint, _histogramPointDigits);
      ValuePrintOut(_prefix + "VA_T_VWAP", _labelSide, vwapprice, _anchor_va, VwapColor, "VWAP", FontSize);
   }

   if (_showMedian == true) {
      medianprice = NormalizeDouble(intervalMinMerged + medianPosMain * _histogramPoint, _histogramPointDigits);
      ValuePrintOut(_prefix + "VA_T_Median", _labelSide, medianprice, _anchor_va, MedianColor, "Mediana", FontSize);
   }

//o poc pode ser o ponto de maior volume que esteja mais próximo da mediana ou ponto central do volume profile, ou a própria mediana ou até mesmo a VWAP
   pocprice = NormalizeDouble(intervalMinMerged + (ArraySize(arrayVolumesMerged) -1 - indexmaxvolume) * _histogramPoint, _histogramPointDigits);
   indexpoc = indexmaxvolume;
   if (indexpoc < 0)
      return; // Data not yet ready.

// mecanismo para gerenciar a exibição/ocultação da linha de simulação de poc e definição forçada do poc simulado
   if (!EnableMiniMode && btnSimClicked) {
      datetime simulatorTime = GetObjectTime1(_simLine);
      if (simulatorTime == 0) {
         DrawHLine(_simLine, timeTo + PeriodSeconds(PERIOD_CURRENT), pocprice, PocColor, 1, PocStyle, false, true, true, ZOrderInteracts);
         ObjectSetInteger(0, _simLine, OBJPROP_SELECTED, true);
         ObjectSetString(0, _simLine, OBJPROP_TEXT, pocprice);
      }

      double simPrice = ObjectGetDouble(0, _simLine, OBJPROP_PRICE);
      if ((simPrice <= intervalMaxMerged) && (simPrice >= intervalMinMerged)) { // se a linha de simulação estiver dentro do intervalo entre a máxima e a mínima
         if (_Digits > 0) {
            pocprice = simPrice;
            indexpoc = (pocprice - intervalMinMerged) / _histogramPoint;
         } else {
            pocprice = round((long)simPrice / 5) * 5 ;
            indexpoc = (pocprice - intervalMinMerged) / _histogramPoint;
         }
         ObjectSetString(0, _simLine, OBJPROP_TEXT, pocprice);
      } else if (simPrice == 0) { // se a linha de simulação estiver escondida
         double oldPrice = StringToDouble(ObjectGetString(0, _simLine, OBJPROP_TEXT));
         pocprice = round((int)oldPrice / 5) * 5 ;
         indexpoc = (pocprice - intervalMinMerged) / _histogramPoint;
         ObjectSetDouble(0, _simLine, OBJPROP_PRICE, pocprice);
         ObjectSetString(0, _simLine, OBJPROP_TEXT, pocprice);
      }
   } else {
      ObjectSetDouble(0, _simLine, OBJPROP_PRICE, 0);
      ObjectSetString(0, _simLine, OBJPROP_TEXT, pocprice);
   }

   if (_showIntervals && btnIntervalsClicked) {
      ArrayFree(intervals);
      ArrayResize(intervals, ArraySize(arrayVolumesMerged) / _intervalStep + _intervalStep);
      for (int i = 0; i < ArraySize(intervals); i++) {
         intervals[i] = 0;
      }

      int contador = 0;
      for (int i = indexpoc; i < ArraySize(arrayVolumesMerged); i = i + _intervalStep) {
         intervals[contador] = i;
         contador++;
      }

      for (int i = indexpoc; i >= 0; i = i - _intervalStep) {
         intervals[contador] = i;
         contador++;
      }
   }

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ProcessValueArea() {

   long up_offset = 1;
   long down_offset = 1;
   long index, index2, indexvah, indexval;
   int numeroPorcentagens = 0, numeroPorcentagens1 = 0, numeroPorcentagens2 = 0, numeroPorcentagens3 = 0, numeroPorcentagens4 = 0, numeroProjPorcentagens = 0;
   string tempString[], tempStringProj[];
   double valuePercentageArrayTotal[], valuePercentageArray1[], valuePercentageArray2[], valuePercentageArray3[], valuePercentageArray4[], valuePercentageProjArray[]; // arrays que armazenam e processam os inputs para uso nos procedimentos computacionais

   double vahprice, valprice, volumeAcima, volumeAbaixo, volumeCount;
   double valueControlArray[], up_offsetArray[], down_offsetArray[];
   double projReferencePercentage = ValueAreaPercentageCalculateProj * 0.01;
   double projReferencePriceUp = 0, projReferencePriceDown = 0;

   //Print(arrayVolumesMerged[20]);
   //Print(arrayVolumesMerged[300]);
   if (ValueAreaPercentages1 != "") {
      StringSplit(ValueAreaPercentages1, StringGetCharacter(",", 0), tempString);
      numeroPorcentagens1 = ArraySize(tempString);
      ArrayResize(valuePercentageArray1, numeroPorcentagens1);
      ArrayInitialize(valuePercentageArray1, 0);

      for (int i = 0; i <= numeroPorcentagens1 - 1; i++) {
         double valor = (double)tempString[i];
         if (valor < 0) {
            Print("Erro: verifique o formato dos números inseridos nas porcentagens.");
            return;
         }

         valuePercentageArray1[i] = valor * 0.01;
      }
   }

   if (ValueAreaPercentages2 != "") {
      StringSplit(ValueAreaPercentages2, StringGetCharacter(",", 0), tempString);
      numeroPorcentagens2 = ArraySize(tempString);
      ArrayResize(valuePercentageArray2, numeroPorcentagens2);
      ArrayInitialize(valuePercentageArray2, 0);

      for (int i = 0; i <= numeroPorcentagens2 - 1; i++) {
         double valor = (double)tempString[i];
         if (valor < 0) {
            Print("Erro: verifique o formato dos números inseridos nas porcentagens.");
            return;
         }

         valuePercentageArray2[i] = valor * 0.01;
      }
   }

   if (ValueAreaPercentages3 != "") {
      StringSplit(ValueAreaPercentages3, StringGetCharacter(",", 0), tempString);
      numeroPorcentagens3 = ArraySize(tempString);
      ArrayResize(valuePercentageArray3, numeroPorcentagens3);
      ArrayInitialize(valuePercentageArray3, 0);

      for (int i = 0; i <= numeroPorcentagens3 - 1; i++) {
         double valor = (double)tempString[i];
         if (valor < 0) {
            Print("Erro: verifique o formato dos números inseridos nas porcentagens.");
            return;
         }

         valuePercentageArray3[i] = valor * 0.01;
      }
   }

   if (ValueAreaPercentages4 != "") {
      StringSplit(ValueAreaPercentages4, StringGetCharacter(",", 0), tempString);
      numeroPorcentagens4 = ArraySize(tempString);
      ArrayResize(valuePercentageArray4, numeroPorcentagens4);
      ArrayInitialize(valuePercentageArray4, 0);

      for (int i = 0; i <= numeroPorcentagens4 - 1; i++) {
         double valor = (double)tempString[i];
         if (valor < 0) {
            Print("Erro: verifique o formato dos números inseridos nas porcentagens.");
            return;
         }

         valuePercentageArray4[i] = valor * 0.01;
      }
   }

   int tamanhoTotal = numeroPorcentagens1 + numeroPorcentagens2 + numeroPorcentagens3 + numeroPorcentagens4;

   ArrayResize(valuePercentageArrayTotal, tamanhoTotal);
   ArrayCopy(valuePercentageArrayTotal, valuePercentageArray1, 0, WHOLE_ARRAY);
   ArrayCopy(valuePercentageArrayTotal, valuePercentageArray2, numeroPorcentagens1, WHOLE_ARRAY);
   ArrayCopy(valuePercentageArrayTotal, valuePercentageArray3, numeroPorcentagens1 + numeroPorcentagens2, WHOLE_ARRAY);
   ArrayCopy(valuePercentageArrayTotal, valuePercentageArray4, numeroPorcentagens1 + numeroPorcentagens2 + numeroPorcentagens3, WHOLE_ARRAY);

   ArraySort(valuePercentageArrayTotal);
   MathUnique(valuePercentageArrayTotal, valuePercentageArrayTotal);
   ArraySort(valuePercentageProjArray);
   MathUnique(valuePercentageProjArray, valuePercentageProjArray);

   numeroPorcentagens = ArraySize(valuePercentageArrayTotal);
   numeroProjPorcentagens = ArraySize(valuePercentageProjArray);

   ArrayResize(valueControlArray, numeroPorcentagens);
   ArrayResize(up_offsetArray, numeroPorcentagens);
   ArrayResize(up_offsetArray, numeroPorcentagens);
   ArrayResize(down_offsetArray, numeroPorcentagens);

   ArrayInitialize(valueControlArray, 0);
   ArrayInitialize(down_offsetArray, 0);
   ArrayInitialize(up_offsetArray, 0);
   ArrayInitialize(down_offsetArray, 0);

   double MaxTpoPercent = valuePercentageArrayTotal[ArrayMaximum(valuePercentageArrayTotal)];

   long ValueControlTPOMax = (long)((double)totalVolume * MaxTpoPercent);

   for (int i = 0; i <= numeroPorcentagens - 1; i++) {
      valueControlArray[i] = (long)((double)totalVolume * valuePercentageArrayTotal[i]);
   }

// Go through the price levels above and below median adding the biggest to TPO count until the Max % of TPOs are inside the Value Area.
   up_offset = 1;
   down_offset = 1;
   long lastIndex = totalEntriesMerged - 1;

   double startPoint = 0;
   long startPointIndex = 0;
   if (PocMode == VP_POC_MODE) {
      startPoint = pocprice;
      startPointIndex = indexpoc;
   } else if (PocMode == VP_MEDIAN_MODE) {
      startPoint = medianprice;
      startPointIndex = medianPosMain;
   } else if (PocMode == VP_VWAP_MODE) {
      startPoint = vwapprice;
      startPointIndex = vwapPosMain;
   }

   volumeCount = arrayVolumesMerged[startPointIndex];

   while (volumeCount < ValueControlTPOMax) {
      double abovePrice = startPoint + up_offset * movestep * _histogramPoint;
      double belowPrice = startPoint - down_offset * movestep * _histogramPoint;
      // If belowPrice is out of the session's range then we should add only abovePrice's TPO's, and vice versa.
      index = startPointIndex + up_offset * movestep;
      index2 = startPointIndex - down_offset * movestep;
      volumeAcima = arrayVolumesMerged[index];
      volumeAbaixo = arrayVolumesMerged[index2];

      if (index >= lastIndex) // para evitar um loop infinito em casos raros onde o índice de cima siga subindo por causa do volume de cima ser sempre menor que o de baixo
         volumeAcima = 0;

      if (index2 <= 0) // para evitar um loop infinito em casos raros onde o índice de baixo siga caindo por causa do volume de baixo ser sempre menor que o de cima
         volumeAbaixo = 0;

      if ((index2 == 0) && (index == lastIndex)) {
         int u = 0;
         break;
      }

      if (volumeCount < 0)
         int k = 0;

      if ((volumeAcima == 0) && (volumeAbaixo == 0)) { // para evitar um loop infinito em casos raros onde o índice de baixo siga caindo por causa do volume debaixo ser sempre menor que o de cima
         if (index >= lastIndex) // caso ambos os volumes estejam zerados, verificamos se devemos continuar seguindo para cima ou para baixo, de acordo com os intervalos superior e inferior
            down_offset++;    // se o índice já estiver no topo, temos que ir descendo, até que encontremos um volume válido
         else if (index2 <= 0)
            up_offset++;   // se o índice já estiver no fundo, temos que ir subindo, até que encontremos um volume válido
      }

      if (((belowPrice < intervalMinMerged) || (volumeAcima >= volumeAbaixo)) && (abovePrice <= intervalMaxMerged)) {
         volumeCount += volumeAcima;
         if (index < lastIndex) {
            up_offset++;
            for (int k = 0; k <= numeroPorcentagens - 1; k++) {
               if (volumeCount < valueControlArray[k])
                  up_offsetArray[k]++;
            }
         }
      } else if ((volumeAbaixo > volumeAcima) && (belowPrice >= intervalMinMerged)) {
         volumeCount += volumeAbaixo;
         if (index2 > 0) {
            down_offset++;
            for (int k = 0; k <= numeroPorcentagens - 1; k++) {
               if (volumeCount < valueControlArray[k])
                  down_offsetArray[k]++;
            }
         }
      }
   }




   DrawVA(_prefix + "VA_POC", timeLeft, valueAreaTimeTo, pocprice, PocColor, PocWidth, VP_BAR_STYLE_BAR, PocStyle, true, true, false);
   ValuePrintOut(_prefix + "VA_T_POC", _labelSide, pocprice, _anchor_va, PocColor, "POC", FontSize);

   for (int k = 0; k <= numeroPorcentagens - 1; k++) {
      indexvah = startPointIndex + up_offsetArray[k] * movestep;
      indexval = startPointIndex - down_offsetArray[k] * movestep;
      vahprice = NormalizeDouble(intervalMinMerged + indexvah * _histogramPoint, _histogramPointDigits);
      valprice = NormalizeDouble(intervalMinMerged + indexval * _histogramPoint, _histogramPointDigits);
      DrawVA(_prefix + "VA_Top" + k, timeLeft, valueAreaTimeTo, vahprice, ValueAreaHighColor, ValueAreaHighWidth, VP_BAR_STYLE_LINE, ValueAreaHighStyle, true, true, false);
      DrawVA(_prefix + "VA_Bottom" + k, timeLeft, valueAreaTimeTo, valprice, ValueAreaLowColor, ValueAreaLowWidth, VP_BAR_STYLE_LINE, ValueAreaLowStyle, true, true, false);
      ValuePrintOut(_prefix + "VA_T_VAH" + k, _labelSide, vahprice, _anchor_va, ValueAreaHighColor, (string)NormalizeDouble(valuePercentageArrayTotal[k] * 100, 2), FontSize);
      ValuePrintOut(_prefix + "VA_T_VAL" + k, _labelSide, valprice, _anchor_va, ValueAreaLowColor, (string)NormalizeDouble(valuePercentageArrayTotal[k] * 100, 2), FontSize);

      if (projReferencePercentage == valuePercentageArrayTotal[k]) {
         projReferencePriceUp = vahprice;
         projReferencePriceDown = valprice;
         //Print("projReferencePriceDown: " + projReferencePriceDown);
      }
   }

   double deltaProjUp = MathAbs(projReferencePriceUp - projReferencePriceDown);
   double deltaProjDown = MathAbs(projReferencePriceUp - projReferencePriceDown);

//double deltaProjUp = MathAbs(projReferencePriceUp - pocprice);
//double deltaProjDown = MathAbs(projReferencePriceDown - pocprice);

   for (int n = 0; n <= numeroProjPorcentagens - 1; n++) {
      double valor = valuePercentageProjArray[n];
      double priceProjUp = projReferencePriceUp + deltaProjUp * (valor);
      double priceProjDown = projReferencePriceDown - deltaProjDown * (valor);
      DrawVA(_prefix + "VA_ProjUp" + tempStringProj[n], timeLeft, valueAreaTimeTo, priceProjUp, ValueAreaHighColor, ValueAreaHighWidth, VP_BAR_STYLE_LINE, ValueAreaHighStyle, true, true, false);
      DrawVA(_prefix + "VA_ProjDown"  + tempStringProj[n], timeLeft, valueAreaTimeTo, priceProjDown, ValueAreaLowColor, ValueAreaLowWidth, VP_BAR_STYLE_LINE, ValueAreaLowStyle, true, true, false);
      ValuePrintOut(_prefix + "VA_T_ProjUp" + tempStringProj[n], _labelSide, priceProjUp, _anchor_va, ValueAreaHighColor, (string)NormalizeDouble(tempStringProj[n], 2), FontSize);
      ValuePrintOut(_prefix + "VA_T_ProjDown" + tempStringProj[n], _labelSide, priceProjDown, _anchor_va, ValueAreaLowColor, (string)NormalizeDouble(tempStringProj[n], 2), FontSize);
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawVA(const string name, const datetime time1, const datetime time2, const double price,
            const color lineColor, const int width, const ENUM_VP_BAR_STYLE barStyle, const ENUM_LINE_STYLE lineStyle, const bool back = true, const bool hidden = true, const bool selectable = false) {
   ObjectDelete(0, name);

   if (barStyle == VP_BAR_STYLE_BAR) {
      ObjectCreate(0, name, OBJ_RECTANGLE, 0, time1, price, time2, price);
   } else if((barStyle == VP_BAR_STYLE_FILLED) || (barStyle == VP_BAR_STYLE_COLOR)) {
      ObjectCreate(0, name, OBJ_RECTANGLE, 0, time1, price + _histogramPoint * width, time2, price - _histogramPoint * width);
   } else if(barStyle == VP_BAR_STYLE_OUTLINE) {
      ObjectCreate(0, name, OBJ_TREND, 0, time1, price, time2, price);
   } else {
      ObjectCreate(0, name, OBJ_TREND, 0, time1, price, time2, price);
   }
   ObjectSetInteger(0, name, OBJPROP_ZORDER, -1);
   SetBarStyle(name, lineColor, width, barStyle, lineStyle, back, hidden, selectable);
}

//+------------------------------------------------------------------+
//| Print out VAH, VAL, or POC value on the chart.                   |
//+------------------------------------------------------------------+
void ValuePrintOut(const string obj_name, const datetime time, const double price, const ENUM_ANCHOR_POINT anchor = ANCHOR_RIGHT, const color cor = clrWhite, const string texto = "", const int pFontSize = 9) {

   ObjectDelete(0, obj_name);
   ObjectCreate(0, obj_name, OBJ_TEXT, 0, time, price);

   ObjectSetInteger(0, obj_name, OBJPROP_COLOR, cor);
   ObjectSetInteger(0, obj_name, OBJPROP_FONTSIZE, pFontSize);
   ObjectSetInteger(0, obj_name, OBJPROP_BACK, false);
   ObjectSetInteger(0, obj_name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, obj_name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, obj_name, OBJPROP_ANCHOR, anchor);

   if (ShowPrice && ShowLevel)
      ObjectSetString(0, obj_name, OBJPROP_TEXT, DoubleToString(price, _histogramPointDigits) + " - " + texto);
   else if (ShowPrice)
      ObjectSetString(0, obj_name, OBJPROP_TEXT, DoubleToString(price, _histogramPointDigits));
   else if (ShowLevel)
      ObjectSetString(0, obj_name, OBJPROP_TEXT, texto);
   else if (!ShowPrice && !ShowLevel)
      ObjectDelete(0, obj_name);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime GetObjectTime1(const string name) {
   datetime time;

   if(!ObjectGetInteger(0, name, OBJPROP_TIME, 0, time))
      return(0);

   return(time);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
long ArrayIndexOf(const T & arr[], const T value, const long startingFrom = 0) {
   long size = ArraySize(arr);

   for(long i = startingFrom; i < size; i++) {
      if(arr[i] == value)
         return(i);
   }

   return(-1);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
bool ArrayCheckRange(const T & arr[], int &start, int &count) {
   int size = ArraySize(arr);

   if(size <= 0)
      return(false);

   if(count == 0)
      return(false);

   if((start > size - 1) || (start < 0))
      return(false);

   if(count < 0) {
      count = size - start;
   } else if(count > size - start) {
      count = size - start;
   }

   return(true);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int ArrayMedian(const double & values[]) {
   int size = ArraySize(values);
   double halfVolume = Sum(values) / 2.0;

   double pointvolume = 0;

   for(int i = 0; i < size; i++) {
      pointvolume += values[i];

      if(pointvolume >= halfVolume)
         return(i);
   }

   return(-1);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string TrimRight(string s, const ushort ch) {
   int len = StringLen(s);

   int cut = len;

   for(int i = len - 1; i >= 0; i--) {
      if(StringGetCharacter(s, i) == ch)
         cut--;
      else
         break;
   }

   if(cut != len) {
      if(cut == 0)
         s = "";
      else
         s = StringSubstr(s, 0, cut);
   }

   return(s);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string DoubleToString(const double d, const uint digits, const uchar separator) {
   string s = DoubleToString(d, digits) + ""; //HACK: áåç +"" ôóíêöèÿ ìîæåò âåğíóòü ïóñòîå çíà÷åíèå (áèëä 697)

   if(separator != '.') {
      int p = StringFind(s, ".");

      if(p != -1)
         StringSetCharacter(s, p, separator);
   }

   return(s);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string DoubleToCompactString(const double d, const uint digits = 8, const uchar separator = '.') {
   string s = DoubleToString(d, digits, separator);

   if(StringFind(s, CharToString(separator)) != -1) {
      s = TrimRight(s, '0');
      s = TrimRight(s, '.');
   }

   return(s);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MathRound(const double value, const double error) {
   return(error == 0 ? value : MathRound(value / error) * error);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
void Swap(T & value1, T & value2) {
   T tmp = value1;
   value1 = value2;
   value2 = tmp;

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
T Sum(const T & arr[], int start = 0, int count = -1) {
   if(!ArrayCheckRange(arr, start, count))
      return((T)NULL);

   T sum = (T)NULL;

   for(int i = start, end = start + count; i < end; i++)
      sum += arr[i];

   return(sum);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetPointDigits(const double point) {
   if(point == 0)
      return(_Digits);

   return(GetPointDigits(point, _Digits));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetPointDigits(const double point, const int maxDigits) {
   if(point == 0)
      return(maxDigits);

   string pointString = DoubleToCompactString(point, maxDigits);
   int pointStringLen = StringLen(pointString);
   int dotPos = StringFind(pointString, ".");

// pointString => result:
//   1230   => -1
//   123    =>  0
//   12.3   =>  1
//   1.23   =>  2
//   0.123  =>  3
//   .123   =>  3

   return(dotPos < 0
          ? StringLen(TrimRight(pointString, '0')) - pointStringLen
          : pointStringLen - dotPos - 1);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
int ArrayMax(const T & array[], const int start = 0, const int count = WHOLE_ARRAY) {
   return(ArrayMaximum(array, start, count));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
long HistogramIntervals(const double & values[], const long intervalStep, long & intervals[]) {
   long intervalCount = 0;
   ArrayFree(intervals);

   for(long i = intervalStep, count = ArraySize(values) - intervalStep; i < count; i++) {
      long maxFrom = i - intervalStep;
      long maxRange = 2 * intervalStep + 1;
      long maxTo = maxFrom + maxRange - 1;

      long k = ArrayMax(values, maxFrom, maxRange);

      if(k != i)
         continue;

      for(long j = i - intervalStep; j <= i + intervalStep; j++) {
         if(values[j] != values[k])
            continue;

         intervalCount++;
         ArrayResize(intervals, intervalCount, count);
         intervals[intervalCount - 1] = j;
      }
   }

   return(intervalCount);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int HistogramVwap(const double & pvolumes[], const double step) {
   if(step == 0)
      return(-1);

   double vwap = 0;
   totalVolume = 0;
   int size = ArraySize(pvolumes);

   for(int i = 0; i < size; i++) {
      double price = intervalMinMerged + i * step;
      double volume = pvolumes[i];

      vwap += price * volume;
      totalVolume += volume;
   }

   if(totalVolume == 0)
      return(-1);

   vwap /= totalVolume;
   return((int)((vwap - intervalMinMerged) / step + 0.5));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime miTime(string symbol, ENUM_TIMEFRAMES timeframe, int index) {
   if(index < 0)
      return(-1);

   datetime arr[];

   if(CopyTime(symbol, timeframe, index, 1, arr) <= 0)
      return(-1);

   return(arr[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int WindowBarsPerChart() {
   return((int)ChartGetInteger(0, CHART_WIDTH_IN_BARS));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int WindowFirstVisibleBar() {
   return((int)ChartGetInteger(0, CHART_FIRST_VISIBLE_BAR));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
long GetHistogramByTicks(const datetime ptimeFrom, const datetime ptimeTo, const double point, const ENUM_TIMEFRAMES dataPeriod, const ENUM_VOLUME_TYPE appliedVolume, double & pvolumes[]) {
   long tickVolumes[];
   int tickVolumeCount = CopyTickVolume(_Symbol, dataPeriod, ptimeFrom, ptimeTo, tickVolumes);

   if(tickVolumeCount <= 0)
      return(0);

   long tickVolumesTotal = Sum(tickVolumes);

   MqlTick ticks[];
   int tickCount = CopyTicks(_Symbol, ticks, COPY_TICKS_TRADE, timeFrom * 1000, (uint)tickVolumesTotal);

   if(tickCount <= 0) {
      return(0);
   }

   MqlTick tick = ticks[0];
   double low = NORM_PRICE(tick.last, point);
   double high = low;
   long timeToMs = timeTo * 1000;

   for(int i = 1; i < tickCount; i++) {
      tick = ticks[i];

      if(tick.time_msc > timeToMs) {
         tickCount = i;
         break;
      }

      double tickLast = NORM_PRICE(tick.last, point);

      if(tickLast < low)
         low = tickLast;

      if(tickLast > high)
         high = tickLast;
   }

   long lowIndex = ROUND_PRICE(low, point);
   long highIndex = ROUND_PRICE(high, point);
   intervalMaxMain = high;
   intervalMinMain = low;
   intervalMaxIndexMain = highIndex;
   intervalMinIndexMain = lowIndex;

   intervalMaxMerged = high;
   intervalMinMerged = low;
   intervalMaxIndexMerged = highIndex;
   intervalMinIndexMerged = lowIndex;

   long histogramSize = highIndex - lowIndex + 1; // êîëè÷åñòâî öåí â ãèñòîãğàììå
   ArrayResize(pvolumes, histogramSize);
   ArrayInitialize(pvolumes, 0);

   long pri;

   for(long j = 0; j < tickCount; j++) {
      tick = ticks[j];
      pri = ROUND_PRICE(tick.last, point) - lowIndex;

      pvolumes[pri] += (appliedVolume == Real || appliedVolume == Financeiro) ? (double)tick.volume : 1;
   }

   return(histogramSize);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
long GetHistogram(string ativo, bool primary, const datetime ptimeFrom, const datetime ptimeTo, const double point, const ENUM_TIMEFRAMES dataPeriod, const ENUM_VOLUME_TYPE appliedVolume, double & pvolumes[]) {

   MqlRates rates[];
   int rateCount = CopyRates(ativo, dataPeriod, ptimeFrom, ptimeTo, rates);


   if(rateCount <= 0)
      return(0);

   if (VolumeType == Financeiro) {
      if (ativo == "IND$") {
         fatorVolume = 1;
      } else if (ativo == "WIN$") {
         fatorVolume = 0.2;
      }
   }

   MqlRates rate = rates[0];
   double low = NORM_PRICE(rate.low, point);
   double high = NORM_PRICE(rate.high, point);

   for(long i = 1; i < rateCount; i++) {
      rate = rates[i];

      double rateHigh =  NORM_PRICE(rate.high, point);
      double rateLow = NORM_PRICE(rate.low, point);

      if(rateLow < low)
         low = rateLow;

      if(rateHigh > high)
         high = rateHigh;
   }

   long lowIndex = ROUND_PRICE(low, point);
   long highIndex = ROUND_PRICE(high, point);
   long histogramSize = highIndex - lowIndex + 1;



   ArrayResize(pvolumes, histogramSize);
   ArrayInitialize(pvolumes, 0);



   if (agrupar) {
      if (primary) {
         ArrayResize(arrayPrices1, histogramSize);
         intervalMaxMain = high;
         intervalMinMain = low;
         intervalMaxIndexMain = highIndex;
         intervalMinIndexMain = lowIndex;
//         for(long i = 0; i < histogramSize; i++) {
//            arrayPrices1[i] = intervalMinMain + i * _histogramPoint;
//         }
      } else {
         ArrayResize(arrayPrices2, histogramSize);
         intervalMaxSec = high;
         intervalMinSec = low;
         intervalMaxIndexSec = highIndex;
         intervalMinIndexSec = lowIndex;
         //for(long i = 0; i < histogramSize; i++) {
         //   arrayPrices2[i] = intervalMinSec + i * _histogramPoint;
         //}
      }
   } else {
      intervalMaxMerged = high;
      intervalMinMerged = low;
      intervalMaxIndexMerged = highIndex;
      intervalMinIndexMerged = lowIndex;

   }





   long pri, openindex, highindex, lowindex, closeindex;
   double dv, pointvolume;

   for(long j = 0; j < rateCount; j++) {
      rate = rates[j];

      openindex = ROUND_PRICE(rate.open, point) - lowIndex;
      highindex = ROUND_PRICE(rate.high, point) - lowIndex;
      lowindex = ROUND_PRICE(rate.low, point) - lowIndex;
      closeindex = ROUND_PRICE(rate.close, point) - lowIndex;

      double h = NORM_PRICE(rate.high, point);
      double l = NORM_PRICE(rate.low, point);
      double c = NORM_PRICE(rate.close, point);
      double p = (h + l + c) / 3;

      if (appliedVolume == Ticks) {
         pointvolume = (double)rate.tick_volume;
      } else if (appliedVolume == Real) {
         pointvolume = (double)rate.real_volume;
      } else {
         pointvolume = (double)rate.real_volume * p * fatorVolume;
      }

      if(closeindex >= openindex) {

         dv = pointvolume / (openindex - lowindex + highindex - lowindex + highindex - closeindex + 1.0);

         // open --> low
         for(pri = openindex; pri >= lowindex; pri--)
            pvolumes[pri] += dv;

         // low+1 ++> high
         for(pri = lowindex + 1; pri <= highindex; pri++)
            pvolumes[pri] += dv;

         // high-1 --> close
         for(pri = highindex - 1; pri >= closeindex; pri--)
            pvolumes[pri] += dv;
      } else {

         dv = pointvolume / (highindex - openindex + highindex - lowindex + closeindex - lowindex + 1.0);

         // open ++> high
         for(pri = openindex; pri <= highindex; pri++)
            pvolumes[pri] += dv;

         // high-1 --> low
         for(pri = highindex - 1; pri >= lowindex; pri--)
            pvolumes[pri] += dv;

         // low+1 ++> close
         for(pri = lowindex + 1; pri <= closeindex; pri++)
            pvolumes[pri] += dv;
      }
   }

   ArrayReverse(pvolumes);

   return(histogramSize);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime GetHorizon(ENUM_VP_SOURCE dataSource, ENUM_TIMEFRAMES dataPeriod) {
   if(dataSource == VP_SOURCE_TICKS) {
      MqlTick ticks[];
      long tickCount = CopyTicks(_Symbol, ticks, COPY_TICKS_INFO, 1, 1);

      if(tickCount <= 0)
         return ((datetime)(SymbolInfoInteger(_Symbol, SYMBOL_TIME) + 1));

      return(ticks[0].time);
   }

   return((datetime)(miTime(_Symbol, dataPeriod, Bars(_Symbol, dataPeriod) - 1)));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES GetDataPeriod(ENUM_VP_SOURCE dataSource) {
   switch(dataSource) {
   case VP_SOURCE_TICKS:
      return(PERIOD_M1);

   case VP_SOURCE_M1:
      return(PERIOD_M1);
   case VP_SOURCE_M5:
      return(PERIOD_M5);
   case VP_SOURCE_M15:
      return(PERIOD_M15);
   case VP_SOURCE_M30:
      return(PERIOD_M30);
   default:
      return(PERIOD_M1);
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ColorToRGB(const color c, int &r, int &g, int &b) {
   if(COLOR_IS_NONE(c))
      return(false);

   b = (c & 0xFF0000) >> 16;
   g = (c & 0x00FF00) >> 8;
   r = (c & 0x0000FF);

   return(true);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
color MixColors(const color color1, const color color2, double mix, double step = 16) {
   step = PUT_IN_RANGE(step, 1.0, 255.0);
   mix = PUT_IN_RANGE(mix, 0.0, 1);

   int r1, g1, b1;
   int r2, g2, b2;

   ColorToRGB(color1, r1, g1, b1);
   ColorToRGB(color2, r2, g2, b2);

   int r = PUT_IN_RANGE((int)MathRound(r1 + mix * (r2 - r1), step), 0, 255);
   int g = PUT_IN_RANGE((int)MathRound(g1 + mix * (g2 - g1), step), 0, 255);
   int b = PUT_IN_RANGE((int)MathRound(b1 + mix * (b2 - b1), step), 0, 255);

   return(RGB_TO_COLOR(r, g, b));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ColorIsNone(const color c) {
   return(COLOR_IS_NONE(c));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MillisecondTimer {

 private:
   int               _milliseconds;
 private:
   uint              _lastTick;

 public:
   void              MillisecondTimer(const int milliseconds, const bool reset = true) {
      _milliseconds = milliseconds;

      if(reset)
         Reset();
      else
         _lastTick = 0;
   }

 public:
   bool              Check() {
      uint now = getCurrentTick();
      bool stop = now >= _lastTick + _milliseconds;

      if(stop)
         _lastTick = now;

      return(stop);
   }

 public:
   void              Reset() {
      _lastTick = getCurrentTick();
   }

 private:
   uint              getCurrentTick() const {
      return(GetTickCount());
   }

};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ObjectEnable(const long chartId, const string name) {
   ObjectSetInteger(chartId, name, OBJPROP_HIDDEN, false);
   ObjectSetInteger(chartId, name, OBJPROP_SELECTABLE, true);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ObjectDisable(const long chartId, const string name) {
   ObjectSetInteger(chartId, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(chartId, name, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetTimeBarRight(datetime time, ENUM_TIMEFRAMES period = PERIOD_CURRENT) {
   int bar = iBarShift(_Symbol, period, time);
   datetime t = miTime(_Symbol, period, bar);

   if((t != time) && (bar == 0)) {
      bar = (int)((miTime(_Symbol, period, 0) - time) / PeriodSeconds(period));
   } else {
      if(t < time)
         bar--;
   }

   return(bar);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime GetBarTime(const int shift, ENUM_TIMEFRAMES period = PERIOD_CURRENT) {
   if(shift >= 0)
      return(miTime(_Symbol, period, shift));
   else
      return(miTime(_Symbol, period, 0) - shift * PeriodSeconds(period));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawHorizon(const string lineName, const datetime time) {
   DrawVLine(lineName, time, HorizonColor, 1, STYLE_DOT, true, false, false);
   ObjectDisable(0, lineName);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawHLine(const string name, const datetime time1, const double price1, const color lineColor, const int width, const int style, const bool back = true, const bool hidden = true, const bool selectable = false, const int zorder = 0) {
   if(ObjectFind(0, name) >= 0)
      ObjectDelete(0, name);

   ObjectCreate(0, name, OBJ_HLINE, 0, time1, price1);
   ObjectSetInteger(0, name, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(0, name, OBJPROP_BACK, back);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, hidden);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, selectable);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, zorder);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawVLine(const string name, const datetime time1, const color lineColor, const int width, const int style, const bool back = true, const bool hidden = true, const bool selectable = true, const int zorder = 0) {
   ObjectDelete(0, name);

   ObjectCreate(0, name, OBJ_VLINE, 0, time1, 0);
   ObjectSetInteger(0, name, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(0, name, OBJPROP_BACK, back);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, hidden);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, selectable);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, zorder);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawBar(const string name, const datetime time1, const datetime time2, const double price,
             const color lineColor, const int width, const ENUM_VP_BAR_STYLE barStyle, const ENUM_LINE_STYLE lineStyle, const bool back = true, const bool hidden = true, const bool selectable = false, const int zorder = 0) {
   ObjectDelete(0, name);

   if (barStyle == VP_BAR_STYLE_BAR) {
      ObjectCreate(0, name, OBJ_RECTANGLE, 0, time1, price - _histogramPoint / 2.0, time2, price + _histogramPoint / 2.0);
   }   else if((barStyle == VP_BAR_STYLE_FILLED) || (barStyle == VP_BAR_STYLE_COLOR))     {
      ObjectCreate(0, name, OBJ_RECTANGLE, 0, time1, price - _histogramPoint / 2.0, time2, price + _histogramPoint / 2.0);
   }   else if(barStyle == VP_BAR_STYLE_OUTLINE)     {
      ObjectCreate(0, name, OBJ_TREND, 0, time1, price, time2, price + _histogramPoint);
   }   else     {
      ObjectCreate(0, name, OBJ_TREND, 0, time1, price, time2, price);
   }

   SetBarStyle(name, lineColor, width, barStyle, lineStyle, back, hidden, selectable, zorder);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetBarStyle(const string name, const color lineColor, const int width, const ENUM_VP_BAR_STYLE barStyle, const ENUM_LINE_STYLE lineStyle, bool back, bool hidden = true, bool selectable = false, const int zorder = 0) {

   ObjectSetInteger(0, name, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(0, name, OBJPROP_STYLE, lineStyle);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, lineStyle == STYLE_SOLID ? width : 1);
   ObjectSetInteger(0, name, OBJPROP_BACK, back);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, hidden);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, selectable);
   ObjectSetInteger(0, name, OBJPROP_FILL, (barStyle == VP_BAR_STYLE_FILLED) || (barStyle == VP_BAR_STYLE_COLOR));
   ObjectSetInteger(0, name, OBJPROP_ZORDER, zorder);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawLevel(const string name, const double price) {
   ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_COLOR, _intervalLineColor);
   ObjectSetInteger(0, name, OBJPROP_STYLE, _intervalLineStyle);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, _intervalLineStyle == STYLE_SOLID ? _intervalLevelWidth : 1);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawHistogram(const string prefix, const double & pvolumes[], const int barFrom, const int barTo,
                   double zoom, const long & intervals[], const long & max[], const long median = -1, const long vwap = -1) {
   if(ArraySize(pvolumes) == 0)
      return;

   if(barFrom > barTo)
      zoom = -zoom;


   color cl = _histogramColor1;
   double maxValue;

// se não queremos exibir nenhum volume máximo no histograma, usamos o valor padrão extraído do array pvolumes
   if (ShowNVolumes > 0) {
      long indexMaxValue = max[ArrayMaximum(max)];
      maxValue = pvolumes[indexMaxValue];

      if(maxValue == 0)
         maxValue = 1;
   } else {
      maxValue = pvolumes[ArrayMaximum(pvolumes)];
   }

   double volume;
   double nextVolume = 0;

   bool isOutline = _histogramBarStyle == VP_BAR_STYLE_OUTLINE;

   int bar1 = barFrom;
   int bar2 = barTo;
   int intervalBar2 = barTo;
   double topVolume = pvolumes[ArrayMaximum(pvolumes)];
   int u=0;
   
   for(long i = 0, size = ArraySize(pvolumes); i < size; i++) {
      double price = NormalizeDouble(intervalMaxMerged - i * _histogramPoint, _Digits);
      string priceString = DoubleToString(price, _Digits);
      string name = prefix + priceString;
      volume = pvolumes[i];

      if(isOutline) {
         if(i < size - 1) {
            nextVolume = pvolumes[i + 1];
            bar1 = (int)(barFrom + volume * zoom);
            bar2 = (int)(barFrom + nextVolume * zoom);
            intervalBar2 = bar1;
         }
      } else if(_histogramBarStyle != VP_BAR_STYLE_COLOR) {
         bar2 = (int)(barFrom + volume * zoom);
         intervalBar2 = bar2;
      }

      datetime t1 = GetBarTime(bar1);
      datetime t2 = GetBarTime(bar2);
      datetime mt2 = GetBarTime(intervalBar2);
      valueAreaTimeTo = iTime(_Symbol, PERIOD_CURRENT, (int)(bar2 * HistogramWidthPercent / 100));

      if(_showHistogram) {
         if(_showHistogram && !(isOutline && (i == size - 1))) {
            if ((_histogramColor1 != _histogramColor2) && (btnHeatMapClicked))
               cl = MixColors(_histogramColor1, _histogramColor2, (isOutline ? MathMax(volume, nextVolume) : volume) / (maxValue * FatorDistincao), 8);

            DrawBar(name, t1, t2, price, cl, _histogramLineWidth, _histogramBarStyle, STYLE_SOLID, true, true, false, ZOrderHistogram);
         }

         //if(i == indexpoc)
         //   DrawBar(name + " poc", t1, timeTo, price, PocColor, PocWidth, _histogramBarStyle, PocStyle, true, true, false, ZOrderHistogram);

         if(_showMedian && (i == median)) {
            DrawBar(name + " median", t1, timeTo, price, _medianColor, _medianLineWidth, VP_BAR_STYLE_LINE, _medianLineStyle, true, true, false, ZOrderHistogram);
         } else if(_showVwap && (i == vwap)) {
            DrawBar(name + " vwap", t1, timeTo, price, _vwapColor, _vwapLineWidth, VP_BAR_STYLE_LINE, _vwapLineStyle, true, true, false, ZOrderHistogram);
         } else if(((_showMax) && (ShowNVolumes > 0) && (ArrayIndexOf(max, i) != -1)) || (_showIntervals && btnIntervalsClicked && (ArrayIndexOf(intervals, i) != -1))) {
            color intervalColor = (_showMax && (ArrayIndexOf(max, i) != -1)) ? _maxColor : _intervalColor;
            if(_histogramBarStyle == VP_BAR_STYLE_OUTLINE)
               DrawBar(name + "+", t1, mt2, price, intervalColor, _intervalLineWidth, VP_BAR_STYLE_LINE, STYLE_SOLID, true, true, false, ZOrderHistogram);
            else
               DrawBar(name, t1, mt2, price, intervalColor, _intervalLineWidth, VP_BAR_STYLE_LINE, STYLE_SOLID, true, true, false, ZOrderHistogram);
         }

         if (EnableTooltip == true) {
            ObjectSetString(0, name, OBJPROP_TOOLTIP, "Preço: " + (string)DoubleToString(price, _histogramPointDigits)
                            + "\nVolume (" + volumeSuffix + "): " + DoubleToStrCommaSep(pvolumes[i], precisaoVolume)
                            + " (Total: " + DoubleToStrCommaSep(totalVolume, precisaoVolume) + ")"
                            //+ "\n% of Max: " + (string)DoubleToString(NormalizeDouble(pvolumes[i] / topVolume * 100, _histogramPointDigits), _histogramPointDigits)
                            + "\n% of Total Volume: " + (string)DoubleToString(NormalizeDouble(pvolumes[i] / totalVolume * 100, 2), 2)
                            + "%");
         } else {
            ObjectSetString(0, name, OBJPROP_TOOLTIP, "\n");
         }
      }

   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string DoubleToStrCommaSep(double v, int decimals = 4, string s = "") { // 6,454.23

   string abbr = "";
//Septillion: Y; sextillion: Z; Quintillion: E; Quadrillion: Q; Trillion: T; Billion: B; Million: M;
//if (v > 999999999999999999999999) { v = v/1000000000000000000000000; abbr = "Y"; } else
//if (v > 999999999999999999999) { v = v/1000000000000000000000; abbr = "Z"; } else
//if (v > 999999999999999999) { v = v/1000000000000000000; abbr = "E"; } else
//if (v > 999999999999999) { v = v/1000000000000000; abbr = "Q";} else
   if (v > 999999999999) {
      v = v / 1000000000000;
      abbr = "T";
   } else if (v > 999999999) {
      v = v / 1000000000;
      abbr = "B";
   } else if (v > 999999) {
      v = v / 1000000;
      abbr = "M";
   } else if (v > 999) {
      v = v / 1000;
      abbr = "K";
   }


   v = NormalizeDouble(v, decimals);
   int integer = v;

   if (decimals == 0) {
      return( IntToStrCommaSep(v, s) + abbr);
   } else {
      string fraction = StringSubstr(DoubleToString(v - integer, decimals), 1);
      return(IntToStrCommaSep(integer, s) + fraction + abbr);
   }

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string IntToStrCommaSep(int integer, string s = "") {

   string right;
   if(integer < 0) {
      s = "-";
      integer = -integer;
   }

   for(right = ""; integer >= 1000; integer /= 1000)
      right = "," + RJust(integer % 1000, 3, "0") + right;

   return(s + integer + right);

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string RJust(string s, int size, string fill = "0") {
   while( StringLen(s) < size )
      s = fill + s;
   return(s);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool GetRangeBars(const datetime ptimeFrom, const datetime ptimeTo, int &barFrom, int &barTo) {
   barFrom = GetTimeBarRight(ptimeFrom);
   barTo = GetTimeBarRight(ptimeTo);
   return(true);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool UpdateAutoColors() {
   if(!_showHistogram)
      return(false);

   bool isNone1 = ColorIsNone(_defaultHistogramColor1);
   bool isNone2 = ColorIsNone(_defaultHistogramColor2);

   if(isNone1 && isNone2)
      return(false);

   color newBgColor = (color)ChartGetInteger(0, CHART_COLOR_BACKGROUND);

   if(newBgColor == _prevBackgroundColor)
      return(false);

   _histogramColor1 = isNone1 ? newBgColor : _defaultHistogramColor1;
   _histogramColor2 = isNone2 ? newBgColor : _defaultHistogramColor2;

   _prevBackgroundColor = newBgColor;
   return(true);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#define KEY_RIGHT   68
#define KEY_LEFT  65
//#define KEY_PLUS   107
//#define KEY_MINUS  109

void OnChartEvent(const int id, const long & lparam, const double & dparam, const string & sparam) {

   if(id == CHARTEVENT_OBJECT_DRAG) {
      if((sparam == _timeFromLine) || (sparam == _timeToLine)) {
         //Update();
         _lastOK = false;
         ChartRedraw();
         CheckTimer();
         //ObjectSetInteger(0, _timeToLine, OBJPROP_SELECTED, true);
      }
   }

   if(id == CHARTEVENT_CHART_CHANGE) {
      //if (HistogramPosition == VP_histogram_POSITION_WINDOW_LEFT || HistogramPosition == VP_histogram_POSITION_WINDOW_RIGHT)
      //return;

//      int firstVisibleBar = WindowFirstVisibleBar();
//      int lastVisibleBar = firstVisibleBar - WindowBarsPerChart();
//
//      bool update = (_firstVisibleBar == _lastVisibleBar)
//                    || (((firstVisibleBar != _firstVisibleBar) || (lastVisibleBar != _lastVisibleBar)) && ((HistogramPosition == VP_histogram_POSITION_WINDOW_LEFT) || (HistogramPosition == VP_histogram_POSITION_WINDOW_RIGHT)));
//
//      _firstVisibleBar = firstVisibleBar;
//      _lastVisibleBar = lastVisibleBar;

      _prefix = Id + " m" + IntegerToString(RangeMode) + " ";

      if (!EnableMiniMode)
         createButton(btnHide, 0, 15, 15, 15, PocColor, "H", ALIGN_CENTER, false, true, false, btnHideClicked, "Esconde os botões");

      if (!EnableMiniMode && !btnHideClicked) {
         heightScreen = ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0);
         widthScreen = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0);

         MqlDateTime data;
         TimeToStruct(DefaultInitialDate, data);
         int ano = data.year;

         createTxt(txtAno, 4, heightScreen - 30, 80, 20, PocColor, ano, ALIGN_CENTER, false, true, false, false, "Ano");
//         createButton(btnTimeFrom, 4, heightScreen - 20, 40, 15, TimeFromColor, "From", ALIGN_CENTER, false, true, false, false, "Seleção da linha inicial");
//         createButton(btnTimeTo, 48, heightScreen - 20, 40, 15, TimeToColor, "To", ALIGN_CENTER, false, true, false, false, "Seleção da linha final");
//         createButton(btnSim, 91, heightScreen - 20, 40, 15, PocColor, "Sim", ALIGN_CENTER, false, true, false, false, "Simulador de POC");
//
//         createButton(btnIntervals, 4, heightScreen - 40, 40, 15, clrIndigo, "Intervals", ALIGN_CENTER, false, true, false, btnIntervalsClicked, "Ativa / Desativa a pintura de linhas de níveis");
//         createButton(btnHeatMap, 48, heightScreen - 40, 40, 15, clrIndigo, "Heat", ALIGN_CENTER, false, true, false, btnHeatMapClicked, "Ativa / Desativa a pintura por calor");
//         createButton(btnRegression, 91, heightScreen - 40, 40, 15, clrIndigo, "Reg.", ALIGN_CENTER, false, true, false, btnRegressionClicked, "Ativa / Desativa a curva de regressão");
         ChartRedraw(0);
      }

      //if (divisaoPartesTela <= 0) {
      UpdateAutoColors();
      _lastOK = false;
      CheckTimer();
      //} else
      //   ChartRedraw();

      return;
   }

   if(id == CHARTEVENT_OBJECT_ENDEDIT && sparam == "txtAno") {
      //ObjectSetString(0, "EditTP", OBJPROP_TEXT, ObjectGetString(0,"EditTP",OBJPROP_TEXT));
      _lastOK = false;

      MqlDateTime data;
      TimeToStruct(DefaultInitialDate, data);
      int ano = ObjectGetString(0, "txtAno", OBJPROP_TEXT);

      if (ano > 0 && ano <= 22) {
         data.year = 2000 + ano;
         ObjectSetString(0, "txtAno", OBJPROP_TEXT, 2000 + ano);
      } else {
         data.year = ano;
      }
      txtData = StructToTime(data);
      ChartRedraw();
      Update();
      //txtData = 0;
      Print("Editado: " + ObjectGetString(0, "txtAno", OBJPROP_TEXT)); //Prints OLD VALUE
   }

   static bool keyPressed = false;
   int barraLimite, barraNova, barraFrom, barraTo, primeiraBarraVisivel, ultimaBarraVisivel, ultimaBarraSerie;
   datetime tempoTimeFrom, tempoTimeTo, tempoBarra0, tempoUltimaBarraSerie;

   if(EnableEvents && id == CHARTEVENT_KEYDOWN) {
      if(lparam == KEY_RIGHT || lparam == KEY_LEFT) {
         if(!keyPressed)
            keyPressed = true;
         else
            keyPressed = false;

         // definição das variáveis comuns
         if ((ObjectGetInteger(0, _timeToLine, OBJPROP_SELECTED) == true) || (ObjectGetInteger(0, _timeFromLine, OBJPROP_SELECTED) == true)) {
            totalCandles = Bars(_Symbol, PERIOD_CURRENT);
            ultimaBarraSerie = totalCandles - 1;
            ultimaBarraVisivel = WindowFirstVisibleBar();
            barraFrom = iBarShift(_Symbol, PERIOD_CURRENT, ObjectGetInteger(0, _timeFromLine, OBJPROP_TIME));
            barraTo = iBarShift(_Symbol, PERIOD_CURRENT, ObjectGetInteger(0, _timeToLine, OBJPROP_TIME));
            tempoTimeFrom = GetObjectTime1(_timeFromLine);
            tempoTimeTo = GetObjectTime1(_timeToLine);
            tempoBarra0 = iTime(_Symbol, PERIOD_CURRENT, 0);

            tempoUltimaBarraSerie = iTime(_Symbol, PERIOD_CURRENT, totalCandles - 1);
         }
      }

      switch(int(lparam))  {
      case KEY_RIGHT: {
         if (ObjectGetInteger(0, _timeToLine, OBJPROP_SELECTED) == true) {
            if (barraFrom <= primeiraBarraVisivel)
               barraLimite = barraFrom;
            else
               barraLimite = primeiraBarraVisivel;

            EnableEvents == true ? barraNova = barraTo - 1 : barraNova = barraTo;
            if (barraNova >= 0) {
               datetime tempoNovo = iTime(_Symbol, PERIOD_CURRENT, barraNova);
               ObjectSetInteger(0, _timeToLine, OBJPROP_TIME, 0, tempoNovo);
               timeTo = tempoNovo;
               _lastOK = false;
               CheckTimer();
            } else if (barraNova < 0) {
               datetime tempoNovo = iTime(_Symbol, PERIOD_CURRENT, 0) + PeriodSeconds(PERIOD_CURRENT);
               ObjectSetInteger(0, _timeToLine, OBJPROP_TIME, 0, tempoNovo);
               timeTo = tempoNovo;
               _lastOK = false;
               CheckTimer();
            }
         }

         if (ObjectGetInteger(0, _timeFromLine, OBJPROP_SELECTED) == true) {
            barraLimite = 0;
            if (barraTo >= 0)
               barraLimite = barraTo;

            EnableEvents == true ? barraNova = barraTo - 1 : barraNova = barraTo;
            if (barraNova > barraLimite) {
               datetime tempoNovo = iTime(_Symbol, PERIOD_CURRENT, barraNova);
               ObjectSetInteger(0, _timeFromLine, OBJPROP_TIME, 0, tempoNovo);
               timeFrom = tempoNovo;
               _lastOK = false;
               CheckTimer();
            }
         }


      }
      break;

      case KEY_LEFT:  {
         if (ObjectGetInteger(0, _timeToLine, OBJPROP_SELECTED) == true) {
            barraTo = iBarShift(_Symbol, PERIOD_CURRENT, ObjectGetInteger(0, _timeToLine, OBJPROP_TIME));
            if (tempoTimeTo <= tempoUltimaBarraSerie) {
               barraNova = 0;
            } else {
               if (tempoTimeTo > tempoBarra0) {
                  barraNova = 0;
               } else {
                  EnableEvents == true ? barraNova = barraTo + 1 : barraNova = barraTo;
               }
            }

            datetime tempoNovo = iTime(_Symbol, PERIOD_CURRENT, barraNova);
            ObjectSetInteger(0, _timeToLine, OBJPROP_TIME, 0, tempoNovo);
            timeTo = tempoNovo;
            _lastOK = false;
            CheckTimer();
         }

         if (ObjectGetInteger(0, _timeFromLine, OBJPROP_SELECTED) == true) {
            if (tempoTimeFrom <= tempoUltimaBarraSerie)
               barraNova = barraFrom;
            else
               EnableEvents == true ? barraNova = barraFrom + 1 : barraNova = barraFrom;

            barraLimite = ultimaBarraSerie;

            if (barraNova < barraLimite) {
               datetime tempoNovo = iTime(_Symbol, PERIOD_CURRENT, barraNova);
               ObjectSetInteger(0, _timeFromLine, OBJPROP_TIME, 0, tempoNovo);
               timeFrom = tempoNovo;
               _lastOK = false;
               CheckTimer();
            }
         }
      }
      break;
      }
      return;

   }

   bool status;
   if(!EnableMiniMode && id == CHARTEVENT_OBJECT_CLICK) {
      if (sparam == btnHide) {
         if (btnHideClicked == false) {
            btnHideClicked = true;
            ObjectDelete(0, btnIntervals);
            ObjectDelete(0, btnHeatMap);
            ObjectDelete(0, btnSim);
            ObjectDelete(0, btnTimeFrom);
            ObjectDelete(0, btnTimeTo);
            ObjectDelete(0, btnRegression);
            ObjectDelete(0, txtAno);
            ObjectSetString(0, btnHide, OBJPROP_TEXT, "S");
         } else {
            btnHideClicked = false;
            heightScreen = ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0);
            widthScreen = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0);

            MqlDateTime data;
            TimeToStruct(DefaultInitialDate, data);
            int ano = data.year;
            createTxt(txtAno, 4, heightScreen - 30, 80, 20, PocColor, ano, ALIGN_CENTER, false, true, false, false, "Ano");
//            createButton(btnTimeFrom, 4, heightScreen - 20, 40, 15, TimeFromColor, "From", ALIGN_CENTER, false, true, false, false, "Seleção da linha inicial");
//            createButton(btnTimeTo, 48, heightScreen - 20, 40, 15, TimeToColor, "To", ALIGN_CENTER, false, true, false, false, "Seleção da linha final");
//            createButton(btnSim, 91, heightScreen - 20, 40, 15, PocColor, "Sim", ALIGN_CENTER, false, true, false, false, "Simulador de POC");
//
//            createButton(btnIntervals, 4, heightScreen - 40, 40, 15, clrIndigo, "Intervals", ALIGN_CENTER, false, true, false, btnIntervalsClicked, "Ativa / Desativa a pintura de linhas de níveis");
//            createButton(btnHeatMap, 48, heightScreen - 40, 40, 15, clrIndigo, "Heat", ALIGN_CENTER, false, true, false, btnHeatMapClicked, "Ativa / Desativa a pintura por calor");
//            createButton(btnRegression, 91, heightScreen - 40, 40, 15, clrIndigo, "Reg.", ALIGN_CENTER, false, true, false, btnRegressionClicked, "Ativa / Desativa a curva de regressão");
            ObjectSetString(0, btnHide, OBJPROP_TEXT, "H");
         }

         ChartRedraw(0);
      }

      if (sparam == btnSim) {
         if (btnSimClicked == false) {
            btnSimClicked = true;
         } else {
            btnSimClicked = false;
         }

         _lastOK = false;
         CheckTimer();
      }

      if (sparam == btnIntervals) {
         if (btnIntervalsClicked == false) {
            btnIntervalsClicked = true;
         } else {
            btnIntervalsClicked = false;
         }

         _lastOK = false;
         CheckTimer();
      }

      if (sparam == btnHeatMap) {
         if (btnHeatMapClicked == false) {
            btnHeatMapClicked = true;
         } else {
            btnHeatMapClicked = false;
         }

         _lastOK = false;
         CheckTimer();
      }

      if (sparam == btnRegression) {
         if (btnRegressionClicked == false) {
            btnRegressionClicked = true;
         } else {
            btnRegressionClicked = false;
         }

         _lastOK = false;
         CheckTimer();
         ChartRedraw();
      }

      if (sparam == btnTimeFrom) {
         if (btnTimeFromClicked == false) {
            btnTimeFromClicked = true;
            btnTimeToClicked = false;
            ObjectSetInteger(0, _timeFromLine, OBJPROP_SELECTED, true);
            ObjectSetInteger(0, _timeToLine, OBJPROP_SELECTED, false);
            ObjectSetInteger(0, btnTimeTo, OBJPROP_STATE, 0, false);
         } else {
            btnTimeFromClicked = false;
            btnTimeToClicked = false;
            ObjectSetInteger(0, _timeFromLine, OBJPROP_SELECTED, false);
            ObjectSetInteger(0, _timeToLine, OBJPROP_SELECTED, true);
            ObjectSetInteger(0, btnTimeTo, OBJPROP_STATE, 0, false);
         }
         ChartRedraw(0);
      }

      if (sparam == btnTimeTo) {
         if (btnTimeToClicked == false) {
            btnTimeToClicked = true;
            btnTimeFromClicked = false;
            ObjectSetInteger(0, _timeFromLine, OBJPROP_SELECTED, false);
            ObjectSetInteger(0, _timeToLine, OBJPROP_SELECTED, true);
            ObjectSetInteger(0, btnTimeFrom, OBJPROP_STATE, 0, false);
         } else {
            btnTimeToClicked = false;
            btnTimeFromClicked = false;
            ObjectSetInteger(0, _timeFromLine, OBJPROP_SELECTED, true);
            ObjectSetInteger(0, _timeToLine, OBJPROP_SELECTED, false);
            ObjectSetInteger(0, btnTimeFrom, OBJPROP_STATE, 0, false);
         }
         ChartRedraw(0);
      }
      return;
   }
}

void PrepareRegression() {

   if (EnableRegression) {
      ArrayInitialize(regBuffer, 0);
      ArrayInitialize(upChannel1, 0);
      ArrayInitialize(upChannel2, 0);
      ArrayInitialize(upChannel3, 0);
      ArrayInitialize(upChannel4, 0);
      ArrayInitialize(upChannel5, 0);
      ArrayInitialize(upChannel6, 0);
      ArrayInitialize(upChannel7, 0);
      ArrayInitialize(upChannel8, 0);
      ArrayInitialize(upChannel9, 0);
      ArrayInitialize(upChannel10, 0);
      ArrayInitialize(upChannel11, 0);
      ArrayInitialize(upChannel12, 0);
      ArrayInitialize(upChannel13, 0);
      ArrayInitialize(upChannel14, 0);
      ArrayInitialize(upChannel15, 0);
      ArrayInitialize(upChannel16, 0);
      ArrayInitialize(downChannel1, 0);
      ArrayInitialize(downChannel2, 0);
      ArrayInitialize(downChannel3, 0);
      ArrayInitialize(downChannel4, 0);
      ArrayInitialize(downChannel5, 0);
      ArrayInitialize(downChannel6, 0);
      ArrayInitialize(downChannel7, 0);
      ArrayInitialize(downChannel8, 0);
      ArrayInitialize(downChannel9, 0);
      ArrayInitialize(downChannel10, 0);
      ArrayInitialize(downChannel11, 0);
      ArrayInitialize(downChannel12, 0);
      ArrayInitialize(downChannel13, 0);
      ArrayInitialize(downChannel14, 0);
      ArrayInitialize(downChannel15, 0);
      ArrayInitialize(downChannel16, 0);

      SetIndexBuffer(0, regBuffer, INDICATOR_DATA);
//---- restriction to draw empty values for the indicator
      PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
      PlotIndexSetInteger(0, PLOT_LINE_COLOR, RegColor);
      PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_LINE);
      PlotIndexSetInteger(0, PLOT_LINE_WIDTH, RegWidth);
      PlotIndexSetInteger(0, PLOT_LINE_STYLE, RegStyle);
      PlotIndexSetString(0, PLOT_LABEL, "Curva de regressão linear");

      SetIndexBuffer(1, upChannel1, INDICATOR_DATA);
      SetIndexBuffer(2, upChannel2, INDICATOR_DATA);
      SetIndexBuffer(3, upChannel3, INDICATOR_DATA);
      SetIndexBuffer(4, upChannel4, INDICATOR_DATA);
      SetIndexBuffer(5, upChannel5, INDICATOR_DATA);
      SetIndexBuffer(6, upChannel6, INDICATOR_DATA);
      SetIndexBuffer(7, upChannel7, INDICATOR_DATA);
      SetIndexBuffer(8, upChannel8, INDICATOR_DATA);
      SetIndexBuffer(9, upChannel9, INDICATOR_DATA);
      SetIndexBuffer(10, upChannel10, INDICATOR_DATA);
      SetIndexBuffer(11, upChannel11, INDICATOR_DATA);
      SetIndexBuffer(12, upChannel12, INDICATOR_DATA);
      SetIndexBuffer(13, upChannel13, INDICATOR_DATA);
      SetIndexBuffer(14, upChannel14, INDICATOR_DATA);
      SetIndexBuffer(15, upChannel15, INDICATOR_DATA);
      SetIndexBuffer(16, upChannel16, INDICATOR_DATA);
      SetIndexBuffer(17, downChannel1, INDICATOR_DATA);
      SetIndexBuffer(18, downChannel2, INDICATOR_DATA);
      SetIndexBuffer(19, downChannel3, INDICATOR_DATA);
      SetIndexBuffer(20, downChannel4, INDICATOR_DATA);
      SetIndexBuffer(21, downChannel5, INDICATOR_DATA);
      SetIndexBuffer(22, downChannel6, INDICATOR_DATA);
      SetIndexBuffer(23, downChannel7, INDICATOR_DATA);
      SetIndexBuffer(24, downChannel8, INDICATOR_DATA);
      SetIndexBuffer(25, downChannel9, INDICATOR_DATA);
      SetIndexBuffer(26, downChannel10, INDICATOR_DATA);
      SetIndexBuffer(27, downChannel11, INDICATOR_DATA);
      SetIndexBuffer(28, downChannel12, INDICATOR_DATA);
      SetIndexBuffer(29, downChannel13, INDICATOR_DATA);
      SetIndexBuffer(30, downChannel14, INDICATOR_DATA);
      SetIndexBuffer(31, downChannel15, INDICATOR_DATA);
      SetIndexBuffer(32, downChannel16, INDICATOR_DATA);

      for (int i = 1; i <= 33; i++) {
         PlotIndexSetDouble(i, PLOT_EMPTY_VALUE, 0.0); // restriction to draw empty values for the indicator
         PlotIndexSetInteger(i, PLOT_LINE_COLOR, RegChannelColor);
         PlotIndexSetInteger(i, PLOT_DRAW_TYPE, DRAW_LINE);
         PlotIndexSetInteger(i, PLOT_LINE_WIDTH, RegChannelWidth);
         PlotIndexSetInteger(i, PLOT_LINE_STYLE, RegChannelStyle);
      }

// indexing the elements in buffers as timeseries
      ArraySetAsSeries(regBuffer, true);
      ArraySetAsSeries(upChannel1, true);
      ArraySetAsSeries(upChannel2, true);
      ArraySetAsSeries(upChannel3, true);
      ArraySetAsSeries(upChannel4, true);
      ArraySetAsSeries(upChannel5, true);
      ArraySetAsSeries(upChannel6, true);
      ArraySetAsSeries(upChannel7, true);
      ArraySetAsSeries(upChannel8, true);
      ArraySetAsSeries(upChannel9, true);
      ArraySetAsSeries(upChannel10, true);
      ArraySetAsSeries(upChannel11, true);
      ArraySetAsSeries(upChannel12, true);
      ArraySetAsSeries(upChannel13, true);
      ArraySetAsSeries(upChannel14, true);
      ArraySetAsSeries(upChannel15, true);
      ArraySetAsSeries(upChannel16, true);
      ArraySetAsSeries(downChannel1, true);
      ArraySetAsSeries(downChannel2, true);
      ArraySetAsSeries(downChannel3, true);
      ArraySetAsSeries(downChannel4, true);
      ArraySetAsSeries(downChannel5, true);
      ArraySetAsSeries(downChannel6, true);
      ArraySetAsSeries(downChannel7, true);
      ArraySetAsSeries(downChannel8, true);
      ArraySetAsSeries(downChannel9, true);
      ArraySetAsSeries(downChannel10, true);
      ArraySetAsSeries(downChannel11, true);
      ArraySetAsSeries(downChannel12, true);
      ArraySetAsSeries(downChannel13, true);
      ArraySetAsSeries(downChannel14, true);
      ArraySetAsSeries(downChannel15, true);
      ArraySetAsSeries(downChannel16, true);

   }

}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CalculateRegression(int fromBar, int toBar, ENUM_REG_SOURCE tipo) {

   if (EnableRegression == false && !btnRegressionClicked) {
      ArrayFree(regBuffer);
      ArrayFree(upChannel1);
      ArrayFree(upChannel2);
      ArrayFree(upChannel3);
      ArrayFree(upChannel4);
      ArrayFree(upChannel5);
      ArrayFree(upChannel6);
      ArrayFree(upChannel7);
      ArrayFree(upChannel8);
      ArrayFree(upChannel9);
      ArrayFree(upChannel10);
      ArrayFree(upChannel11);
      ArrayFree(upChannel12);
      ArrayFree(upChannel13);
      ArrayFree(upChannel14);
      ArrayFree(upChannel15);
      ArrayFree(upChannel16);
      ArrayFree(downChannel1);
      ArrayFree(downChannel2);
      ArrayFree(downChannel3);
      ArrayFree(downChannel4);
      ArrayFree(downChannel5);
      ArrayFree(downChannel6);
      ArrayFree(downChannel7);
      ArrayFree(downChannel8);
      ArrayFree(downChannel9);
      ArrayFree(downChannel10);
      ArrayFree(downChannel11);
      ArrayFree(downChannel12);
      ArrayFree(downChannel13);
      ArrayFree(downChannel14);
      ArrayFree(downChannel15);
      ArrayFree(downChannel16);
      ArrayFree(stDevBuffer);
      return 0;
   }

//PrepareRegression();

   double dataArray[];

   if (toBar < 0)
      toBar = 0;
   int CalcBars = MathAbs(fromBar - toBar) + 1;

   if (tipo == Close)
      CopyClose(Symbol(), PERIOD_CURRENT, toBar, CalcBars, dataArray);
   else if (tipo == Open)
      CopyOpen(Symbol(), PERIOD_CURRENT, toBar, CalcBars, dataArray);
   else if (tipo == High)
      CopyHigh(Symbol(), PERIOD_CURRENT, toBar, CalcBars, dataArray);
   else if (tipo == Low)
      CopyLow(Symbol(), PERIOD_CURRENT, toBar, CalcBars, dataArray);
   else if (tipo == Typical) {
      double dataArrayClose[], dataArrayHigh[], dataArrayLow[];
      CopyClose(Symbol(), PERIOD_CURRENT, toBar, CalcBars, dataArrayClose);
      CopyHigh(Symbol(), PERIOD_CURRENT, toBar, CalcBars, dataArrayHigh);
      CopyLow(Symbol(), PERIOD_CURRENT, toBar, CalcBars, dataArrayLow);
      ArrayResize(dataArray, ArraySize(dataArrayClose));
      for(int i = 0; i < ArraySize(dataArrayClose); i++) {
         dataArray[i] = (dataArrayHigh[i] + dataArrayLow[i] + dataArrayClose[i]) / 3;
      }
   }

   ArrayReverse(dataArray);
   int tamanho = ArraySize(dataArray);
   ArrayResize(stDevBuffer, tamanho);
//ArrayResize(regBuffer, tamanho);
//ArrayResize(upChannel1, tamanho);
//ArrayResize(upChannel2, tamanho);
//ArrayResize(upChannel3, tamanho);
//ArrayResize(upChannel4, tamanho);
//ArrayResize(upChannel5, tamanho);
//ArrayResize(upChannel6, tamanho);
//ArrayResize(upChannel7, tamanho);
//ArrayResize(upChannel8, tamanho);
//ArrayResize(upChannel9, tamanho);
//ArrayResize(upChannel10, tamanho);
//ArrayResize(upChannel11, tamanho);
//ArrayResize(upChannel12, tamanho);
//ArrayResize(upChannel13, tamanho);
//ArrayResize(upChannel14, tamanho);
//ArrayResize(upChannel15, tamanho);
//ArrayResize(upChannel16, tamanho);
//ArrayResize(downChannel1, tamanho);
//ArrayResize(downChannel2, tamanho);
//ArrayResize(downChannel3, tamanho);
//ArrayResize(downChannel4, tamanho);
//ArrayResize(downChannel5, tamanho);
//ArrayResize(downChannel6, tamanho);
//ArrayResize(downChannel7, tamanho);
//ArrayResize(downChannel8, tamanho);
//ArrayResize(downChannel9, tamanho);
//ArrayResize(downChannel10, tamanho);
//ArrayResize(downChannel11, tamanho);
//ArrayResize(downChannel12, tamanho);
//ArrayResize(downChannel13, tamanho);
//ArrayResize(downChannel14, tamanho);
//ArrayResize(downChannel15, tamanho);
//ArrayResize(downChannel16, tamanho);

//ArrayInitialize(stDevBuffer, 0);
//ArrayInitialize(regBuffer, 0);
//ArrayInitialize(upChannel1, 0);
//ArrayInitialize(upChannel2, 0);
//ArrayInitialize(upChannel3, 0);
//ArrayInitialize(upChannel4, 0);
//ArrayInitialize(upChannel5, 0);
//ArrayInitialize(upChannel6, 0);
//ArrayInitialize(upChannel7, 0);
//ArrayInitialize(upChannel8, 0);
//ArrayInitialize(upChannel9, 0);
//ArrayInitialize(upChannel10, 0);
//ArrayInitialize(upChannel11, 0);
//ArrayInitialize(upChannel12, 0);
//ArrayInitialize(upChannel13, 0);
//ArrayInitialize(upChannel14, 0);
//ArrayInitialize(upChannel15, 0);
//ArrayInitialize(upChannel16, 0);
//ArrayInitialize(downChannel1, 0);
//ArrayInitialize(downChannel2, 0);
//ArrayInitialize(downChannel3, 0);
//ArrayInitialize(downChannel4, 0);
//ArrayInitialize(downChannel5, 0);
//ArrayInitialize(downChannel6, 0);
//ArrayInitialize(downChannel7, 0);
//ArrayInitialize(downChannel8, 0);
//ArrayInitialize(downChannel9, 0);
//ArrayInitialize(downChannel10, 0);
//ArrayInitialize(downChannel11, 0);
//ArrayInitialize(downChannel12, 0);
//ArrayInitialize(downChannel13, 0);
//ArrayInitialize(downChannel14, 0);
//ArrayInitialize(downChannel15, 0);
//ArrayInitialize(downChannel16, 0);


//for(int n = 0; n < ArraySize(regBuffer) - 1; n++) {
//   regBuffer[n] = 0.0;
//   upChannel1[n] = 0.0;
//   downChannel1[n] = 0.0;
//   upChannel2[n] = 0.0;
//   downChannel2[n] = 0.0;
//   upChannel3[n] = 0.0;
//   downChannel3[n] = 0.0;
//   upChannel4[n] = 0.0;
//   downChannel4[n] = 0.0;
//   upChannel5[n] = 0.0;
//   downChannel5[n] = 0.0;
//   upChannel6[n] = 0.0;
//   downChannel6[n] = 0.0;
//   upChannel7[n] = 0.0;
//   downChannel7[n] = 0.0;
//   upChannel8[n] = 0.0;
//   downChannel8[n] = 0.0;
//   upChannel9[n] = 0.0;
//   downChannel9[n] = 0.0;
//   upChannel10[n] = 0.0;
//   downChannel10[n] = 0.0;
//   upChannel11[n] = 0.0;
//   downChannel11[n] = 0.0;
//   upChannel12[n] = 0.0;
//   downChannel12[n] = 0.0;
//   upChannel13[n] = 0.0;
//   downChannel13[n] = 0.0;
//   upChannel14[n] = 0.0;
//   downChannel14[n] = 0.0;
//   upChannel15[n] = 0.0;
//   downChannel15[n] = 0.0;
//   upChannel16[n] = 0.0;
//   downChannel16[n] = 0.0;
//   stDevBuffer[n] = 0.0;
//}



   double A = 0, B = 0;
   int indiceFinal = CalcBars - 1;
   for(int i = indiceFinal; i >= 0; i--) {
      CalcAB(dataArray, ArraySize(dataArray) - 1, i, A, B);
      double stdev = GetStdDev(dataArray, ArraySize(dataArray) - 1, i); //calculate standand deviation
      int indiceAjustadoAoBuffer = i + toBar;
      stDevBuffer[indiceAjustadoAoBuffer] = stdev;
      regBuffer[indiceAjustadoAoBuffer] = (A * (i) + B);

      if (DeviationsNumber >= 16) {
         upChannel1[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((1 + DeviationsOffset) * ChannelWidth);
         upChannel2[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((2 + DeviationsOffset) * ChannelWidth);
         upChannel3[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((3 + DeviationsOffset) * ChannelWidth);
         upChannel4[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((4 + DeviationsOffset) * ChannelWidth);
         upChannel5[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((5 + DeviationsOffset) * ChannelWidth);
         upChannel6[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((6 + DeviationsOffset) * ChannelWidth);
         upChannel7[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((7 + DeviationsOffset) * ChannelWidth);
         upChannel8[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((8 + DeviationsOffset) * ChannelWidth);
         upChannel9[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((9 + DeviationsOffset) * ChannelWidth);
         upChannel10[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((10 + DeviationsOffset) * ChannelWidth);
         upChannel11[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((11 + DeviationsOffset) * ChannelWidth);
         upChannel12[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((12 + DeviationsOffset) * ChannelWidth);
         upChannel13[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((13 + DeviationsOffset) * ChannelWidth);
         upChannel14[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((14 + DeviationsOffset) * ChannelWidth);
         upChannel15[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((15 + DeviationsOffset) * ChannelWidth);
         upChannel16[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((16 + DeviationsOffset) * ChannelWidth);
         downChannel1[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((1 + DeviationsOffset) * ChannelWidth);
         downChannel2[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((2 + DeviationsOffset) * ChannelWidth);
         downChannel3[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((3 + DeviationsOffset) * ChannelWidth);
         downChannel4[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((4 + DeviationsOffset) * ChannelWidth);
         downChannel5[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((5 + DeviationsOffset) * ChannelWidth);
         downChannel6[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((6 + DeviationsOffset) * ChannelWidth);
         downChannel7[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((7 + DeviationsOffset) * ChannelWidth);
         downChannel8[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((8 + DeviationsOffset) * ChannelWidth);
         downChannel9[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((9 + DeviationsOffset) * ChannelWidth);
         downChannel10[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((10 + DeviationsOffset) * ChannelWidth);
         downChannel11[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((11 + DeviationsOffset) * ChannelWidth);
         downChannel12[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((12 + DeviationsOffset) * ChannelWidth);
         downChannel13[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((13 + DeviationsOffset) * ChannelWidth);
         downChannel14[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((14 + DeviationsOffset) * ChannelWidth);
         downChannel15[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((15 + DeviationsOffset) * ChannelWidth);
         downChannel16[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((16 + DeviationsOffset) * ChannelWidth);
      } else if (DeviationsNumber == 15) {
         upChannel1[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((1 + DeviationsOffset) * ChannelWidth);
         upChannel2[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((2 + DeviationsOffset) * ChannelWidth);
         upChannel3[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((3 + DeviationsOffset) * ChannelWidth);
         upChannel4[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((4 + DeviationsOffset) * ChannelWidth);
         upChannel5[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((5 + DeviationsOffset) * ChannelWidth);
         upChannel6[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((6 + DeviationsOffset) * ChannelWidth);
         upChannel7[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((7 + DeviationsOffset) * ChannelWidth);
         upChannel8[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((8 + DeviationsOffset) * ChannelWidth);
         upChannel9[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((9 + DeviationsOffset) * ChannelWidth);
         upChannel10[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((10 + DeviationsOffset) * ChannelWidth);
         upChannel11[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((11 + DeviationsOffset) * ChannelWidth);
         upChannel12[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((12 + DeviationsOffset) * ChannelWidth);
         upChannel13[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((13 + DeviationsOffset) * ChannelWidth);
         upChannel14[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((14 + DeviationsOffset) * ChannelWidth);
         upChannel15[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((15 + DeviationsOffset) * ChannelWidth);
         downChannel1[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((1 + DeviationsOffset) * ChannelWidth);
         downChannel2[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((2 + DeviationsOffset) * ChannelWidth);
         downChannel3[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((3 + DeviationsOffset) * ChannelWidth);
         downChannel4[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((4 + DeviationsOffset) * ChannelWidth);
         downChannel5[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((5 + DeviationsOffset) * ChannelWidth);
         downChannel6[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((6 + DeviationsOffset) * ChannelWidth);
         downChannel7[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((7 + DeviationsOffset) * ChannelWidth);
         downChannel8[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((8 + DeviationsOffset) * ChannelWidth);
         downChannel9[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((9 + DeviationsOffset) * ChannelWidth);
         downChannel10[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((10 + DeviationsOffset) * ChannelWidth);
         downChannel11[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((11 + DeviationsOffset) * ChannelWidth);
         downChannel12[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((12 + DeviationsOffset) * ChannelWidth);
         downChannel13[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((13 + DeviationsOffset) * ChannelWidth);
         downChannel14[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((14 + DeviationsOffset) * ChannelWidth);
         downChannel15[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((15 + DeviationsOffset) * ChannelWidth);
      } else if (DeviationsNumber == 14) {
         upChannel1[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((1 + DeviationsOffset) * ChannelWidth);
         upChannel2[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((2 + DeviationsOffset) * ChannelWidth);
         upChannel3[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((3 + DeviationsOffset) * ChannelWidth);
         upChannel4[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((4 + DeviationsOffset) * ChannelWidth);
         upChannel5[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((5 + DeviationsOffset) * ChannelWidth);
         upChannel6[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((6 + DeviationsOffset) * ChannelWidth);
         upChannel7[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((7 + DeviationsOffset) * ChannelWidth);
         upChannel8[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((8 + DeviationsOffset) * ChannelWidth);
         upChannel9[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((9 + DeviationsOffset) * ChannelWidth);
         upChannel10[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((10 + DeviationsOffset) * ChannelWidth);
         upChannel11[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((11 + DeviationsOffset) * ChannelWidth);
         upChannel12[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((12 + DeviationsOffset) * ChannelWidth);
         upChannel13[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((13 + DeviationsOffset) * ChannelWidth);
         upChannel14[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((14 + DeviationsOffset) * ChannelWidth);
         downChannel1[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((1 + DeviationsOffset) * ChannelWidth);
         downChannel2[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((2 + DeviationsOffset) * ChannelWidth);
         downChannel3[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((3 + DeviationsOffset) * ChannelWidth);
         downChannel4[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((4 + DeviationsOffset) * ChannelWidth);
         downChannel5[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((5 + DeviationsOffset) * ChannelWidth);
         downChannel6[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((6 + DeviationsOffset) * ChannelWidth);
         downChannel7[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((7 + DeviationsOffset) * ChannelWidth);
         downChannel8[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((8 + DeviationsOffset) * ChannelWidth);
         downChannel9[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((9 + DeviationsOffset) * ChannelWidth);
         downChannel10[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((10 + DeviationsOffset) * ChannelWidth);
         downChannel11[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((11 + DeviationsOffset) * ChannelWidth);
         downChannel12[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((12 + DeviationsOffset) * ChannelWidth);
         downChannel13[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((13 + DeviationsOffset) * ChannelWidth);
         downChannel14[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((14 + DeviationsOffset) * ChannelWidth);
      } else if (DeviationsNumber == 13) {
         upChannel1[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((1 + DeviationsOffset) * ChannelWidth);
         upChannel2[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((2 + DeviationsOffset) * ChannelWidth);
         upChannel3[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((3 + DeviationsOffset) * ChannelWidth);
         upChannel4[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((4 + DeviationsOffset) * ChannelWidth);
         upChannel5[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((5 + DeviationsOffset) * ChannelWidth);
         upChannel6[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((6 + DeviationsOffset) * ChannelWidth);
         upChannel7[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((7 + DeviationsOffset) * ChannelWidth);
         upChannel8[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((8 + DeviationsOffset) * ChannelWidth);
         upChannel9[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((9 + DeviationsOffset) * ChannelWidth);
         upChannel10[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((10 + DeviationsOffset) * ChannelWidth);
         upChannel11[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((11 + DeviationsOffset) * ChannelWidth);
         upChannel12[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((12 + DeviationsOffset) * ChannelWidth);
         upChannel13[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((13 + DeviationsOffset) * ChannelWidth);
         downChannel1[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((1 + DeviationsOffset) * ChannelWidth);
         downChannel2[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((2 + DeviationsOffset) * ChannelWidth);
         downChannel3[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((3 + DeviationsOffset) * ChannelWidth);
         downChannel4[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((4 + DeviationsOffset) * ChannelWidth);
         downChannel5[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((5 + DeviationsOffset) * ChannelWidth);
         downChannel6[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((6 + DeviationsOffset) * ChannelWidth);
         downChannel7[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((7 + DeviationsOffset) * ChannelWidth);
         downChannel8[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((8 + DeviationsOffset) * ChannelWidth);
         downChannel9[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((9 + DeviationsOffset) * ChannelWidth);
         downChannel10[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((10 + DeviationsOffset) * ChannelWidth);
         downChannel11[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((11 + DeviationsOffset) * ChannelWidth);
         downChannel12[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((12 + DeviationsOffset) * ChannelWidth);
         downChannel13[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((13 + DeviationsOffset) * ChannelWidth);
      } else if (DeviationsNumber == 12) {
         upChannel1[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((1 + DeviationsOffset) * ChannelWidth);
         upChannel2[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((2 + DeviationsOffset) * ChannelWidth);
         upChannel3[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((3 + DeviationsOffset) * ChannelWidth);
         upChannel4[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((4 + DeviationsOffset) * ChannelWidth);
         upChannel5[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((5 + DeviationsOffset) * ChannelWidth);
         upChannel6[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((6 + DeviationsOffset) * ChannelWidth);
         upChannel7[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((7 + DeviationsOffset) * ChannelWidth);
         upChannel8[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((8 + DeviationsOffset) * ChannelWidth);
         upChannel9[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((9 + DeviationsOffset) * ChannelWidth);
         upChannel10[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((10 + DeviationsOffset) * ChannelWidth);
         upChannel11[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((11 + DeviationsOffset) * ChannelWidth);
         upChannel12[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((12 + DeviationsOffset) * ChannelWidth);
         downChannel1[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((1 + DeviationsOffset) * ChannelWidth);
         downChannel2[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((2 + DeviationsOffset) * ChannelWidth);
         downChannel3[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((3 + DeviationsOffset) * ChannelWidth);
         downChannel4[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((4 + DeviationsOffset) * ChannelWidth);
         downChannel5[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((5 + DeviationsOffset) * ChannelWidth);
         downChannel6[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((6 + DeviationsOffset) * ChannelWidth);
         downChannel7[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((7 + DeviationsOffset) * ChannelWidth);
         downChannel8[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((8 + DeviationsOffset) * ChannelWidth);
         downChannel9[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((9 + DeviationsOffset) * ChannelWidth);
         downChannel10[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((10 + DeviationsOffset) * ChannelWidth);
         downChannel11[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((11 + DeviationsOffset) * ChannelWidth);
         downChannel12[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((12 + DeviationsOffset) * ChannelWidth);
      } else if (DeviationsNumber == 11) {
         upChannel1[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((1 + DeviationsOffset) * ChannelWidth);
         upChannel2[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((2 + DeviationsOffset) * ChannelWidth);
         upChannel3[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((3 + DeviationsOffset) * ChannelWidth);
         upChannel4[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((4 + DeviationsOffset) * ChannelWidth);
         upChannel5[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((5 + DeviationsOffset) * ChannelWidth);
         upChannel6[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((6 + DeviationsOffset) * ChannelWidth);
         upChannel7[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((7 + DeviationsOffset) * ChannelWidth);
         upChannel8[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((8 + DeviationsOffset) * ChannelWidth);
         upChannel9[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((9 + DeviationsOffset) * ChannelWidth);
         upChannel10[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((10 + DeviationsOffset) * ChannelWidth);
         upChannel11[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((11 + DeviationsOffset) * ChannelWidth);
         downChannel1[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((1 + DeviationsOffset) * ChannelWidth);
         downChannel2[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((2 + DeviationsOffset) * ChannelWidth);
         downChannel3[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((3 + DeviationsOffset) * ChannelWidth);
         downChannel4[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((4 + DeviationsOffset) * ChannelWidth);
         downChannel5[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((5 + DeviationsOffset) * ChannelWidth);
         downChannel6[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((6 + DeviationsOffset) * ChannelWidth);
         downChannel7[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((7 + DeviationsOffset) * ChannelWidth);
         downChannel8[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((8 + DeviationsOffset) * ChannelWidth);
         downChannel9[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((9 + DeviationsOffset) * ChannelWidth);
         downChannel10[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((10 + DeviationsOffset) * ChannelWidth);
         downChannel11[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((11 + DeviationsOffset) * ChannelWidth);
      } else if (DeviationsNumber == 10) {
         upChannel1[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((1 + DeviationsOffset) * ChannelWidth);
         upChannel2[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((2 + DeviationsOffset) * ChannelWidth);
         upChannel3[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((3 + DeviationsOffset) * ChannelWidth);
         upChannel4[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((4 + DeviationsOffset) * ChannelWidth);
         upChannel5[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((5 + DeviationsOffset) * ChannelWidth);
         upChannel6[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((6 + DeviationsOffset) * ChannelWidth);
         upChannel7[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((7 + DeviationsOffset) * ChannelWidth);
         upChannel8[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((8 + DeviationsOffset) * ChannelWidth);
         upChannel9[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((9 + DeviationsOffset) * ChannelWidth);
         upChannel10[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((10 + DeviationsOffset) * ChannelWidth);
         downChannel1[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((1 + DeviationsOffset) * ChannelWidth);
         downChannel2[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((2 + DeviationsOffset) * ChannelWidth);
         downChannel3[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((3 + DeviationsOffset) * ChannelWidth);
         downChannel4[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((4 + DeviationsOffset) * ChannelWidth);
         downChannel5[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((5 + DeviationsOffset) * ChannelWidth);
         downChannel6[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((6 + DeviationsOffset) * ChannelWidth);
         downChannel7[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((7 + DeviationsOffset) * ChannelWidth);
         downChannel8[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((8 + DeviationsOffset) * ChannelWidth);
         downChannel9[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((9 + DeviationsOffset) * ChannelWidth);
         downChannel10[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((10 + DeviationsOffset) * ChannelWidth);
      } else if (DeviationsNumber == 9) {
         upChannel1[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((1 + DeviationsOffset) * ChannelWidth);
         upChannel2[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((2 + DeviationsOffset) * ChannelWidth);
         upChannel3[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((3 + DeviationsOffset) * ChannelWidth);
         upChannel4[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((4 + DeviationsOffset) * ChannelWidth);
         upChannel5[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((5 + DeviationsOffset) * ChannelWidth);
         upChannel6[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((6 + DeviationsOffset) * ChannelWidth);
         upChannel7[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((7 + DeviationsOffset) * ChannelWidth);
         upChannel8[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((8 + DeviationsOffset) * ChannelWidth);
         upChannel9[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((9 + DeviationsOffset) * ChannelWidth);
         downChannel1[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((1 + DeviationsOffset) * ChannelWidth);
         downChannel2[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((2 + DeviationsOffset) * ChannelWidth);
         downChannel3[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((3 + DeviationsOffset) * ChannelWidth);
         downChannel4[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((4 + DeviationsOffset) * ChannelWidth);
         downChannel5[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((5 + DeviationsOffset) * ChannelWidth);
         downChannel6[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((6 + DeviationsOffset) * ChannelWidth);
         downChannel7[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((7 + DeviationsOffset) * ChannelWidth);
         downChannel8[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((8 + DeviationsOffset) * ChannelWidth);
         downChannel9[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((9 + DeviationsOffset) * ChannelWidth);
      } else if (DeviationsNumber == 8) {
         upChannel1[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((1 + DeviationsOffset) * ChannelWidth);
         upChannel2[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((2 + DeviationsOffset) * ChannelWidth);
         upChannel3[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((3 + DeviationsOffset) * ChannelWidth);
         upChannel4[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((4 + DeviationsOffset) * ChannelWidth);
         upChannel5[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((5 + DeviationsOffset) * ChannelWidth);
         upChannel6[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((6 + DeviationsOffset) * ChannelWidth);
         upChannel7[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((7 + DeviationsOffset) * ChannelWidth);
         upChannel8[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((8 + DeviationsOffset) * ChannelWidth);
         downChannel1[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((1 + DeviationsOffset) * ChannelWidth);
         downChannel2[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((2 + DeviationsOffset) * ChannelWidth);
         downChannel3[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((3 + DeviationsOffset) * ChannelWidth);
         downChannel4[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((4 + DeviationsOffset) * ChannelWidth);
         downChannel5[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((5 + DeviationsOffset) * ChannelWidth);
         downChannel6[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((6 + DeviationsOffset) * ChannelWidth);
         downChannel7[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((7 + DeviationsOffset) * ChannelWidth);
         downChannel8[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((8 + DeviationsOffset) * ChannelWidth);
      } else if (DeviationsNumber == 7) {
         upChannel1[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((1 + DeviationsOffset) * ChannelWidth);
         upChannel2[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((2 + DeviationsOffset) * ChannelWidth);
         upChannel3[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((3 + DeviationsOffset) * ChannelWidth);
         upChannel4[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((4 + DeviationsOffset) * ChannelWidth);
         upChannel5[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((5 + DeviationsOffset) * ChannelWidth);
         upChannel6[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((6 + DeviationsOffset) * ChannelWidth);
         upChannel7[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((7 + DeviationsOffset) * ChannelWidth);
         downChannel1[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((1 + DeviationsOffset) * ChannelWidth);
         downChannel2[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((2 + DeviationsOffset) * ChannelWidth);
         downChannel3[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((3 + DeviationsOffset) * ChannelWidth);
         downChannel4[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((4 + DeviationsOffset) * ChannelWidth);
         downChannel5[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((5 + DeviationsOffset) * ChannelWidth);
         downChannel6[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((6 + DeviationsOffset) * ChannelWidth);
         downChannel7[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((7 + DeviationsOffset) * ChannelWidth);
      } else if (DeviationsNumber == 6) {
         upChannel1[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((1 + DeviationsOffset) * ChannelWidth);
         upChannel2[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((2 + DeviationsOffset) * ChannelWidth);
         upChannel3[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((3 + DeviationsOffset) * ChannelWidth);
         upChannel4[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((4 + DeviationsOffset) * ChannelWidth);
         upChannel5[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((5 + DeviationsOffset) * ChannelWidth);
         upChannel6[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((6 + DeviationsOffset) * ChannelWidth);
         downChannel1[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((1 + DeviationsOffset) * ChannelWidth);
         downChannel2[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((2 + DeviationsOffset) * ChannelWidth);
         downChannel3[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((3 + DeviationsOffset) * ChannelWidth);
         downChannel4[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((4 + DeviationsOffset) * ChannelWidth);
         downChannel5[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((5 + DeviationsOffset) * ChannelWidth);
         downChannel6[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((6 + DeviationsOffset) * ChannelWidth);
      } else if (DeviationsNumber == 5) {
         upChannel1[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((1 + DeviationsOffset) * ChannelWidth);
         upChannel2[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((2 + DeviationsOffset) * ChannelWidth);
         upChannel3[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((3 + DeviationsOffset) * ChannelWidth);
         upChannel4[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((4 + DeviationsOffset) * ChannelWidth);
         upChannel5[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((5 + DeviationsOffset) * ChannelWidth);
         downChannel1[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((1 + DeviationsOffset) * ChannelWidth);
         downChannel2[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((2 + DeviationsOffset) * ChannelWidth);
         downChannel3[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((3 + DeviationsOffset) * ChannelWidth);
         downChannel4[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((4 + DeviationsOffset) * ChannelWidth);
         downChannel5[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((5 + DeviationsOffset) * ChannelWidth);
      } else if (DeviationsNumber == 4) {
         upChannel1[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((1 + DeviationsOffset) * ChannelWidth);
         upChannel2[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((2 + DeviationsOffset) * ChannelWidth);
         upChannel3[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((3 + DeviationsOffset) * ChannelWidth);
         upChannel4[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((4 + DeviationsOffset) * ChannelWidth);
         downChannel1[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((1 + DeviationsOffset) * ChannelWidth);
         downChannel2[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((2 + DeviationsOffset) * ChannelWidth);
         downChannel3[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((3 + DeviationsOffset) * ChannelWidth);
         downChannel4[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((4 + DeviationsOffset) * ChannelWidth);
      } else if (DeviationsNumber == 3) {
         upChannel1[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((1 + DeviationsOffset) * ChannelWidth);
         upChannel2[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((2 + DeviationsOffset) * ChannelWidth);
         upChannel3[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((3 + DeviationsOffset) * ChannelWidth);
         downChannel1[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((1 + DeviationsOffset) * ChannelWidth);
         downChannel2[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((2 + DeviationsOffset) * ChannelWidth);
         downChannel3[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((3 + DeviationsOffset) * ChannelWidth);
      } else if (DeviationsNumber == 2) {
         upChannel1[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((1 + DeviationsOffset) * ChannelWidth);
         upChannel2[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((2 + DeviationsOffset) * ChannelWidth);
         downChannel1[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((1 + DeviationsOffset) * ChannelWidth);
         downChannel2[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((2 + DeviationsOffset) * ChannelWidth);
      } else if (DeviationsNumber == 1) {
         upChannel1[indiceAjustadoAoBuffer] = (A * (i) + B) + stdev * ((1 + DeviationsOffset) * ChannelWidth);
         downChannel1[indiceAjustadoAoBuffer] = (A * (i) + B) - stdev * ((1 + DeviationsOffset) * ChannelWidth);
      }
   }

//ChartRedraw();
   return 1;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//Linear Regression Calculation for sample data: arr[]
//line equation  y = f(x)  = ax + b
void CalcAB(const double & arr[], int start, int end, double & a, double & b) {

   a = 0.0;
   b = 0.0;
   int size = MathAbs(start - end) + 1;
   if(size < 2)
      return;

   double sumxy = 0.0, sumx = 0.0, sumy = 0.0, sumx2 = 0.0;
   for(int i = start; i >= end; i--) {
      sumxy += i * arr[i];
      sumy += arr[i];
      sumx += i;
      sumx2 += i * i;
   }

   double M = size * sumx2 - sumx * sumx;
   if(M == 0.0)
      return;

   a = (size * sumxy - sumx * sumy) / M;
   b = (sumy - a * sumx) / size;

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetStdDev(const double & arr[], int start, int end) {
   int size = MathAbs(start - end) + 1;
   if(size < 2)
      return(0.0);

   double sum = 0.0;
   for(int i = start; i >= end; i--) {
      sum = sum + arr[i];
   }

   sum = sum / size;

   double sum2 = 0.0;
   for(int i = start; i >= end; i--) {
      sum2 = sum2 + (arr[i] - sum) * (arr[i] - sum);
   }

   sum2 = sum2 / (size - 1);
   sum2 = MathSqrt(sum2);

   return(sum2);
}

//+---------------------------------------------------------------------+
//| GetTimeFrame function - returns the textual timeframe               |
//+---------------------------------------------------------------------+
string GetTimeFrame(int lPeriod) {
   switch(lPeriod) {
   case PERIOD_M1:
      return("M1");
   case PERIOD_M2:
      return("M2");
   case PERIOD_M3:
      return("M3");
   case PERIOD_M4:
      return("M4");
   case PERIOD_M5:
      return("M5");
   case PERIOD_M6:
      return("M6");
   case PERIOD_M10:
      return("M10");
   case PERIOD_M12:
      return("M12");
   case PERIOD_M15:
      return("M15");
   case PERIOD_M20:
      return("M20");
   case PERIOD_M30:
      return("M30");
   case PERIOD_H1:
      return("H1");
   case PERIOD_H2:
      return("H2");
   case PERIOD_H3:
      return("H3");
   case PERIOD_H4:
      return("H4");
   case PERIOD_H6:
      return("H6");
   case PERIOD_H8:
      return("H8");
   case PERIOD_H12:
      return("H12");
   case PERIOD_D1:
      return("D1");
   case PERIOD_W1:
      return("W1");
   case PERIOD_MN1:
      return("MN1");
   }
   return IntegerToString(lPeriod);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string _prefix;
string _timeFromLine;
string _timeToLine;
string _simLine;

datetime _drawHistory[];
bool _lastOK = false;

long _intervalStep = 0;

color _prevBackgroundColor = clrNONE;

int _rangeCount;

ENUM_VP_BAR_STYLE _histogramBarStyle;
double _histogramPoint;
int _histogramPointDigits;

color _defaultHistogramColor1;
color _defaultHistogramColor2;
color _histogramColor1;
color _histogramColor2;
int _histogramLineWidth;

color _timeToColor;
color _timeFromColor;
int _timeToWidth;
int _timeFromWidth;

color _intervalColor;
color _maxColor;
color _medianColor;
color _vwapColor;
int _intervalLineWidth;
int _medianLineWidth;
int _vwapLineWidth;

ENUM_LINE_STYLE _medianLineStyle;
ENUM_LINE_STYLE _vwapLineStyle;

color _intervalLineColor;
ENUM_LINE_STYLE _intervalLineStyle;
int _intervalLevelWidth;

bool _showHistogram;
bool _showIntervals;
bool _showMax;
bool _showMedian;
bool _showVwap;

double _zoom;

int _firstVisibleBar = 0;
int _lastVisibleBar = 0;


MillisecondTimer * _updateTimer;

bool _isTimeframeEnabled = false;

bool _updateOnTick = true;
ENUM_TIMEFRAMES _dataPeriod;

ENUM_ANCHOR_POINT _anchor_poc;
ENUM_ANCHOR_POINT _anchor_va;
datetime _labelSide;
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
