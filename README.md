# Gaussian Recovery Engine (GRE)

An institutional-grade systematic trading algorithm for **MetaTrader 5**. The **Gaussian Recovery Engine** is designed to identify high-probability price reversals by normalizing non-linear market data into a statistical Gaussian distribution.

## 🧬 Core Methodology

The GRE framework is built on three pillars of quantitative validation:

### 1. Statistical Normalization (Fisher Transform)
Unlike standard oscillators, the engine uses the **Fisher Transform** to convert price action into a normal distribution. This allows for precise detection of market extremes (Overbought/Oversold levels) with reduced lag and higher statistical significance.

### 2. Multi-Dimensional Entry Filter
To minimize "whipsaws" and false signals, the GRE runs a triple-check protocol:
*   **Trend Confirmation:** Uses smoothed **QQE (Quantitative Qualitative Estimation)** logic to ensure trades align with the macro momentum.
*   **Volatility Gating:** Integrated **ADX (Average Directional Index)** filter prevents entries during low-liquidity or non-trending sideways markets.

### 3. Structural Recovery Logic
The engine utilizes a **Structural Grid Model** for risk mitigation:
*   **Dynamic Layering:** Adds institutional Alpha Units at fixed-step intervals to improve the aggregate entry price.
*   **Basket Exit:** Manages all open positions as a single unit, executing a hard close once the **Basket Target Profit (USD)** is achieved.

## ⚙️ Technical Specifications

| Parameter | Default | Function |
|-----------|---------|----------|
| `InpLotSize` | 0.01 | Initial entry volume |
| `InpGridStep` | 200 | Point-based distance for structural layers |
| `InpBasketTP` | 5.0 | Aggregate USD profit target for the entire cycle |
| `InpADX_Min` | 25 | Minimum trend strength requirement |

## 📂 Installation
1. Move the `.mq5` file to your `MQL5/Experts/` folder.
2. Compile the file in MetaEditor.
3. Drag the EA onto a M15 or H1 timeframe chart.

---
**Developed by Vasava vishal m**  
*Precision Trading through Mathematical Logic and Statistical Normalization.*
