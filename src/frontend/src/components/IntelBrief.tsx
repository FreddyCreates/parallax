import type { ParallaxData } from "../hooks/useParallax";

interface Props {
  data: ParallaxData;
}

const CAT_COLORS: Record<string, string> = {
  OPPORTUNITY: "#44D17B",
  THREAT: "#B23A3E",
  COMPETITOR: "#D7B24A",
  PLATFORM: "#6B7FDB",
};

const BEHAVIORS = [
  "Scanning BTC network for high-fee windows and optimal timing signals",
  "Monitoring ETH liquid staking protocols for yield rate changes",
  "Tracking ICP ecosystem for new staking and earning opportunities",
  "Pulling competitor platform activity -- weakness detection",
  "Monitoring regulatory signals that could affect any asset slot",
  "Researching platform improvements with specific recommendations",
  "Detecting organism imbalances for arbitrage capture",
  "Scanning DeFi protocols for best available yield rates",
];

export function IntelBrief({ data }: Props) {
  const { intel } = data;

  return (
    <div className="space-y-4">
      <div className="text-[10px] text-[#9AA0AA] tracking-widest uppercase border-b border-[#2A2C33] pb-2">
        WEB INTELLIGENCE BRIEF — AUTONOMOUS HUNTING ENGINE
      </div>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-3 mb-2">
        {["OPPORTUNITY", "THREAT", "COMPETITOR", "PLATFORM"].map((cat) => {
          const count = intel.filter((i) => i.category === cat).length;
          return (
            <div
              key={cat}
              className="bg-[#15161A] border border-[#2A2C33] p-3 flex items-center justify-between"
            >
              <span
                className="text-[9px] tracking-widest"
                style={{ color: CAT_COLORS[cat] }}
              >
                {cat}
              </span>
              <span className="font-mono text-sm font-bold text-[#E7E9EE]">
                {count}
              </span>
            </div>
          );
        })}
      </div>

      <div className="space-y-3">
        {intel.length === 0 ? (
          <div className="text-center py-12 text-[#6F7580] text-[10px] tracking-widest">
            ENGINE HUNTING... INTELLIGENCE GATHERING IN PROGRESS
          </div>
        ) : (
          intel.map((entry) => (
            <div
              key={entry.title}
              className="bg-[#15161A] border border-[#2A2C33] p-4"
            >
              <div className="flex items-start justify-between gap-3 mb-2">
                <div className="flex items-center gap-2">
                  <span
                    className="text-[9px] font-mono px-2 py-0.5 border tracking-widest"
                    style={{
                      borderColor: `${CAT_COLORS[entry.category] ?? "#9AA0AA"}60`,
                      color: CAT_COLORS[entry.category] ?? "#9AA0AA",
                    }}
                  >
                    {entry.category}
                  </span>
                  {entry.actionable && (
                    <span className="text-[8px] px-1.5 py-0.5 bg-[#44D17B]/10 border border-[#44D17B]/30 text-[#44D17B] tracking-widest">
                      ACTIONABLE
                    </span>
                  )}
                </div>
                {entry.yieldImpact > 0 && (
                  <span className="font-mono text-[10px] text-[#44D17B]">
                    +{(entry.yieldImpact * 100).toFixed(3)}% YIELD
                  </span>
                )}
              </div>
              <div className="font-semibold text-xs text-[#E7E9EE] mb-1">
                {entry.title}
              </div>
              <div className="text-[10px] text-[#9AA0AA] leading-relaxed">
                {entry.content}
              </div>
            </div>
          ))
        )}
      </div>

      {/* Engine seeking status */}
      <div className="bg-[#15161A] border border-[#2A2C33] p-4">
        <div className="text-[10px] text-[#9AA0AA] tracking-widest mb-3">
          AUTONOMOUS SEEKING BEHAVIORS — ACTIVE
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
          {BEHAVIORS.map((behavior, i) => (
            <div key={behavior} className="flex items-start gap-2">
              <div
                className="w-1 h-1 rounded-full bg-[#44D17B] mt-1.5 flex-shrink-0 animate-pulse"
                style={{ animationDelay: `${i * 0.3}s` }}
              />
              <span className="text-[9px] text-[#6F7580] leading-relaxed">
                {behavior}
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
