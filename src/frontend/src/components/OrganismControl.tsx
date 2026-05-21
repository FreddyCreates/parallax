import { useState } from "react";
import { toast } from "sonner";
import type { ParallaxData } from "../hooks/useParallax";

interface Props {
  data: ParallaxData;
  callWrite: (fn: string, ...args: unknown[]) => Promise<unknown>;
}

const TIER_COLORS: Record<string, string> = {
  CHAMPION: "#D6B36A",
  HEAVYWEIGHT: "#B23A3E",
  MIDDLEWEIGHT: "#D7B24A",
  LIGHTWEIGHT: "#6F7580",
};

export function OrganismControl({ data, callWrite }: Props) {
  const { organisms } = data;
  const [expandedId, setExpandedId] = useState<number | null>(null);
  const [newName, setNewName] = useState("");
  const [newTier, setNewTier] = useState("LIGHTWEIGHT");
  const [overrideOrgId, setOverrideOrgId] = useState("");
  const [overrideDest, setOverrideDest] = useState("");

  const totalFranchise = organisms.reduce(
    (acc, o) => acc + o.franchiseCutPaid,
    0,
  );

  const handleRegister = async () => {
    if (!newName) return;
    try {
      const id = await callWrite("registerOrganism", newName, newTier);
      toast.success(`Organism #${id} registered: ${newName}`);
      setNewName("");
    } catch {
      toast.error("Registration failed");
    }
  };

  const handleOverride = async () => {
    if (!overrideOrgId || !overrideDest) return;
    try {
      await callWrite(
        "founderOverrideYield",
        BigInt(overrideOrgId),
        overrideDest,
      );
      toast.success(`Yield stream redirected for organism #${overrideOrgId}`);
      setOverrideOrgId("");
      setOverrideDest("");
    } catch {
      toast.error("Override failed");
    }
  };

  return (
    <div className="space-y-4">
      <div className="text-[10px] text-[#9AA0AA] tracking-widest uppercase border-b border-[#2A2C33] pb-2">
        ORGANISM REGISTRY — DARREN WORLD FRANCHISE — CREATOR OWNS ALL
      </div>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        {[
          { label: "TOTAL ORGANISMS", value: organisms.length },
          {
            label: "EARNING",
            value: organisms.filter((o) => o.status === "EARNING").length,
          },
          {
            label: "CHAMPION",
            value: organisms.filter((o) => o.tier === "CHAMPION").length,
          },
          {
            label: "FRANCHISE CUT PAID",
            value: `${totalFranchise.toFixed(4)} ICP`,
          },
        ].map((s) => (
          <div
            key={s.label}
            className="bg-[#15161A] border border-[#2A2C33] p-3"
          >
            <div className="text-[9px] text-[#6F7580] tracking-widest">
              {s.label}
            </div>
            <div className="font-mono text-sm font-bold text-[#D6B36A] mt-1">
              {s.value}
            </div>
          </div>
        ))}
      </div>

      <div className="space-y-2">
        {organisms.map((o) => (
          <div key={o.id} className="bg-[#15161A] border border-[#2A2C33]">
            <button
              type="button"
              onClick={() => setExpandedId(expandedId === o.id ? null : o.id)}
              className="w-full p-4 flex items-center justify-between text-left"
            >
              <div className="flex items-center gap-3">
                <div
                  className="w-2 h-2 rounded-full"
                  style={{ backgroundColor: TIER_COLORS[o.tier] ?? "#6F7580" }}
                />
                <div>
                  <div className="font-semibold text-xs text-[#E7E9EE] tracking-wider">
                    {o.name}
                  </div>
                  <div className="text-[8px] text-[#6F7580]">
                    ID #{o.id} · {o.creatorSignature}
                  </div>
                </div>
              </div>
              <div className="flex items-center gap-3">
                <span
                  className="text-[9px] px-2 py-0.5 border tracking-widest"
                  style={{
                    borderColor: `${TIER_COLORS[o.tier] ?? "#6F7580"}60`,
                    color: TIER_COLORS[o.tier] ?? "#6F7580",
                  }}
                >
                  {o.tier}
                </span>
                <span
                  className={`text-[9px] tracking-widest ${o.status === "EARNING" ? "text-[#44D17B]" : "text-[#9AA0AA]"}`}
                >
                  {o.status}
                </span>
                <span className="text-[#6F7580] text-xs">
                  {expandedId === o.id ? "▲" : "▼"}
                </span>
              </div>
            </button>

            {expandedId === o.id && (
              <div className="border-t border-[#2A2C33] p-4 grid grid-cols-2 md:grid-cols-4 gap-3">
                {[
                  {
                    label: "ICP BALANCE",
                    value: `${o.icpBalance.toFixed(4)} ICP`,
                  },
                  {
                    label: "BTC BALANCE",
                    value: `${o.btcBalance.toFixed(8)} BTC`,
                  },
                  {
                    label: "ETH BALANCE",
                    value: `${o.ethBalance.toFixed(6)} ETH`,
                  },
                  {
                    label: "MTC BALANCE",
                    value: `${o.mtcBalance.toFixed(2)} MTC`,
                  },
                  {
                    label: "TOTAL EARNED",
                    value: `${o.totalEarned.toFixed(6)} ICP`,
                  },
                  {
                    label: "FRANCHISE CUT PAID",
                    value: `${o.franchiseCutPaid.toFixed(6)} ICP`,
                  },
                  { label: "YIELD MULTIPLIER", value: `${o.yieldMultiplier}x` },
                  {
                    label: "DOCTRINE HASH",
                    value: o.doctrineHash
                      ? `0x${(o.doctrineHash >>> 0).toString(16).toUpperCase().padStart(8, "0")}`
                      : "PENDING",
                  },
                ].map((r) => (
                  <div key={r.label}>
                    <div className="text-[8px] text-[#6F7580] tracking-widest">
                      {r.label}
                    </div>
                    <div className="font-mono text-[10px] text-[#E7E9EE]">
                      {r.value}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        ))}
      </div>

      <div className="bg-[#15161A] border border-[#2A2C33] p-4">
        <div className="text-[10px] text-[#9AA0AA] tracking-widest mb-3">
          REGISTER NEW ORGANISM
        </div>
        <div className="flex gap-2">
          <input
            value={newName}
            onChange={(e) => setNewName(e.target.value)}
            placeholder="Organism name"
            className="flex-1 bg-[#1A1B20] border border-[#2A2C33] px-3 py-2 text-xs font-mono text-[#E7E9EE] placeholder-[#6F7580] focus:outline-none focus:border-[#44D17B]"
          />
          <select
            value={newTier}
            onChange={(e) => setNewTier(e.target.value)}
            className="bg-[#1A1B20] border border-[#2A2C33] px-2 py-2 text-xs font-mono text-[#E7E9EE] focus:outline-none"
          >
            <option value="LIGHTWEIGHT">LIGHTWEIGHT</option>
            <option value="MIDDLEWEIGHT">MIDDLEWEIGHT</option>
            <option value="HEAVYWEIGHT">HEAVYWEIGHT</option>
            <option value="CHAMPION">CHAMPION</option>
          </select>
          <button
            type="button"
            onClick={handleRegister}
            className="px-4 py-2 bg-[#44D17B]/10 border border-[#44D17B]/40 text-[#44D17B] text-xs tracking-widest hover:bg-[#44D17B]/20 transition-colors"
          >
            REGISTER
          </button>
        </div>
      </div>

      <div className="bg-[#15161A] border border-[#D6B36A]/20 p-4">
        <div className="text-[10px] text-[#D6B36A] tracking-widest mb-3">
          FOUNDER OVERRIDE — REDIRECT ORGANISM YIELD
        </div>
        <div className="flex gap-2">
          <input
            value={overrideOrgId}
            onChange={(e) => setOverrideOrgId(e.target.value)}
            placeholder="Organism ID"
            type="number"
            className="w-28 bg-[#1A1B20] border border-[#2A2C33] px-3 py-2 text-xs font-mono text-[#E7E9EE] placeholder-[#6F7580] focus:outline-none focus:border-[#D6B36A]"
          />
          <input
            value={overrideDest}
            onChange={(e) => setOverrideDest(e.target.value)}
            placeholder="Destination principal / address"
            className="flex-1 bg-[#1A1B20] border border-[#2A2C33] px-3 py-2 text-xs font-mono text-[#E7E9EE] placeholder-[#6F7580] focus:outline-none focus:border-[#D6B36A]"
          />
          <button
            type="button"
            onClick={handleOverride}
            className="px-4 py-2 bg-[#D6B36A]/10 border border-[#D6B36A]/40 text-[#D6B36A] text-xs tracking-widest hover:bg-[#D6B36A]/20 transition-colors"
          >
            OVERRIDE
          </button>
        </div>
      </div>
    </div>
  );
}
