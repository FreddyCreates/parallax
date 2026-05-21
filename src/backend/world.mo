import Float "mo:core/Float";
import Text "mo:core/Text";

// PARALLAX — World Engine: EMA, regime, price deviation utilities
// The existing world/*.mo modules are imported and used directly in main.mo
// This module provides the pure computation helpers
module {

  // Exponential Moving Average
  public func computeEMA(prev : Float, current : Float, period : Nat) : Float {
    let alpha = 2.0 / ((period : Int).toFloat() + 1.0);
    alpha * current + (1.0 - alpha) * prev
  };

  // Market regime classification based on BTC EMAs
  public func classifyRegime(
    ema21  : Float,
    ema55  : Float,
    ema200 : Float,
    price  : Float
  ) : Text {
    if (price < ema200 * 0.8) {
      "CRISIS"
    } else if (price > ema21 and ema21 > ema55 and ema55 > ema200) {
      "BULL"
    } else if (price < ema21 and ema21 < ema55 and ema55 < ema200) {
      "BEAR"
    } else if (price > ema200 and price < ema55) {
      "RECOVERY"
    } else {
      "SIDEWAYS"
    }
  };

  // Price deviation from EMA200 (normalized)
  public func priceDeviation(price : Float, ema200 : Float) : Float {
    Float.abs(price - ema200) / Float.max(0.001, ema200)
  };

  // EMA slope (percent change)
  public func emaSlope(current : Float, prev : Float) : Float {
    (current - prev) / Float.max(0.001, Float.abs(prev))
  };

};
