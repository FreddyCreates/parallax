import { useState } from "react";
import { toast } from "sonner";
import type { ParallaxData } from "../hooks/useParallax";

interface Props {
  data: ParallaxData;
  callWrite: (fn: string, ...args: unknown[]) => Promise<unknown>;
}

export function MtcOperations({ data, callWrite }: Props) {
  const { mtc } = data;
  const [mintAmount, setMintAmount] = useState("");
  const [burnAmount, setBurnAmount] = useState("");
  const [slotNum, setSlotNum] = useState("5");
  const [slotName, setSlotName] = useState("");
  const [slotPrice, setSlotPrice] = useState("");
  const [slotYield, setSlotYield] = useState("");

  const handleMint = async () => {
    const amount = Number.parseFloat(mintAmount);
    if (!amount || amount <= 0) return;
    try {
      await callWrite("mintMtc", amount);
      toast.success(`Minted ${amount.toLocaleString()} MTC`);
      setMintAmount("");
    } catch {
      toast.error("Mint failed");
    }
  };

  const handleBurn = async () => {
    const amount = Number.parseFloat(burnAmount);
    if (!amount || amount <= 0) return;
    try {
      const result = await callWrite("burnMtc", amount);
      if (result) {
        toast.success(`Burned ${amount.toLocaleString()} MTC`);
        setBurnAmount("");
      } else {
        toast.error("Burn rejected -- hard floor protection active");
      }
    } catch {
      toast.error("Burn failed");
    }
  };

  const handlePlugIn = async () => {
    if (!slotName || !slotPrice || !slotYield) return;
    try {
      await callWrite(
        "plugInCoinSlot",
        BigInt(slotNum),
        slotName,
        Number.parseFloat(slotPrice),
        Number.parseFloat(slotYield) / 100,
      );
      toast.success(`${slotName} plugged into slot ${slotNum}`);
      setSlotName("");
      setSlotPrice("");
      setSlotYield("");
    } catch {
      toast.error("Slot plug-in failed");
    }
  };

  const supplyPct = ((mtc.circulating / mtc.genesisSupply) * 100).toFixed(4);
  const burnedPct = ((mtc.burned / mtc.genesisSupply) * 100).toFixed(4);

  return (
    <div className="space-y-4">
      <div className="text-[10px] text-[#9AA0AA] tracking-widest uppercase border-b border-[#2A2C33] pb-2">
        MTC OPERATIONS — MEDINA TECH COIN — CREATOR AUTHORITY ABSOLUTE
      </div>

      {/* MTC Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        {[
          {
            label: "CIRCULATING",
            value: mtc.circulating.toLocaleString("en-US", {
              maximumFractionDigits: 0,
            }),
            color: "#44D17B",
          },
          {
            label: "BURNED",
            value: mtc.burned.toLocaleString("en-US", {
              maximumFractionDigits: 2,
            }),
            color: "#B23A3E",
          },
          {
            label: "HARD FLOOR",
            value: mtc.hardFloor.toLocaleString("en-US", {
              maximumFractionDigits: 0,
            }),
            color: "#D7B24A",
          },
          {
            label: "PRICE",
            value: `$${mtc.price.toFixed(4)}`,
            color: "#D6B36A",
          },
        ].map((s) => (
          <div
            key={s.label}
            className="bg-[#15161A] border border-[#2A2C33] p-3"
          >
            <div className="text-[9px] text-[#6F7580] tracking-widest">
              {s.label}
            </div>
            <div
              className="font-mono text-sm font-bold mt-1"
              style={{ color: s.color }}
            >
              {s.value}
            </div>
          </div>
        ))}
      </div>

      {/* Supply visualization */}
      <div className="bg-[#15161A] border border-[#2A2C33] p-4">
        <div className="text-[10px] text-[#9AA0AA] tracking-widest mb-3">
          SUPPLY DYNAMICS
        </div>
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4 text-xs mb-4">
          <div>
            <div className="text-[9px] text-[#6F7580] tracking-widest">
              GENESIS SUPPLY
            </div>
            <div className="font-mono text-[#E7E9EE]">
              {mtc.genesisSupply.toLocaleString()}
            </div>
          </div>
          <div>
            <div className="text-[9px] text-[#6F7580] tracking-widest">
              CREATOR HOLDING
            </div>
            <div className="font-mono text-[#D6B36A]">
              {mtc.creatorHolding.toLocaleString()}
            </div>
          </div>
          <div>
            <div className="text-[9px] text-[#6F7580] tracking-widest">
              CIRCULATING %
            </div>
            <div className="font-mono text-[#44D17B]">{supplyPct}%</div>
          </div>
        </div>
        <div className="h-2 bg-[#1A1B20] rounded-sm overflow-hidden">
          <div className="h-full flex">
            <div
              className="bg-[#44D17B]/70 transition-all"
              style={{ width: `${Number.parseFloat(supplyPct)}%` }}
            />
            <div
              className="bg-[#B23A3E]/70 transition-all"
              style={{ width: `${Number.parseFloat(burnedPct)}%` }}
            />
          </div>
        </div>
        <div className="flex gap-4 mt-2">
          <span className="text-[8px] text-[#44D17B] tracking-widest">
            CIRCULATING {supplyPct}%
          </span>
          <span className="text-[8px] text-[#B23A3E] tracking-widest">
            BURNED {burnedPct}%
          </span>
        </div>
      </div>

      {/* Rate config */}
      <div className="bg-[#15161A] border border-[#2A2C33] p-4">
        <div className="text-[10px] text-[#9AA0AA] tracking-widest mb-3">
          RATE CONFIGURATION
        </div>
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4 text-xs">
          {[
            {
              label: "SPREAD RATE",
              value: `${(mtc.spreadRate * 100).toFixed(2)}%`,
            },
            {
              label: "BURN RATE",
              value: `${(mtc.burnRate * 100).toFixed(3)}%`,
            },
            {
              label: "YIELD RATE",
              value: `${(mtc.yieldRate * 100).toFixed(2)}%`,
            },
            { label: "TIER LW", value: `${mtc.tierPriceLW.toFixed(0)} MTC` },
            { label: "TIER MW", value: `${mtc.tierPriceMW.toFixed(0)} MTC` },
            { label: "TIER HW", value: `${mtc.tierPriceHW.toFixed(0)} MTC` },
          ].map((r) => (
            <div key={r.label}>
              <div className="text-[8px] text-[#6F7580] tracking-widest">
                {r.label}
              </div>
              <div className="font-mono text-[#D6B36A]">{r.value}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Mint / Burn */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="bg-[#15161A] border border-[#2A2C33] p-4">
          <div className="text-[10px] text-[#44D17B] tracking-widest mb-3">
            MINT MTC — CREATOR AUTHORITY
          </div>
          <div className="flex gap-2">
            <input
              value={mintAmount}
              onChange={(e) => setMintAmount(e.target.value)}
              placeholder="Amount"
              type="number"
              className="flex-1 bg-[#1A1B20] border border-[#2A2C33] px-3 py-2 text-xs font-mono text-[#E7E9EE] placeholder-[#6F7580] focus:outline-none focus:border-[#44D17B]"
            />
            <button
              type="button"
              onClick={handleMint}
              className="px-4 py-2 bg-[#44D17B]/10 border border-[#44D17B]/40 text-[#44D17B] text-xs tracking-widest hover:bg-[#44D17B]/20 transition-colors"
            >
              MINT
            </button>
          </div>
        </div>

        <div className="bg-[#15161A] border border-[#2A2C33] p-4">
          <div className="text-[10px] text-[#B23A3E] tracking-widest mb-3">
            BURN MTC — FLOOR PROTECTED
          </div>
          <div className="flex gap-2">
            <input
              value={burnAmount}
              onChange={(e) => setBurnAmount(e.target.value)}
              placeholder="Amount"
              type="number"
              className="flex-1 bg-[#1A1B20] border border-[#2A2C33] px-3 py-2 text-xs font-mono text-[#E7E9EE] placeholder-[#6F7580] focus:outline-none focus:border-[#B23A3E]"
            />
            <button
              type="button"
              onClick={handleBurn}
              className="px-4 py-2 bg-[#B23A3E]/10 border border-[#B23A3E]/40 text-[#B23A3E] text-xs tracking-widest hover:bg-[#B23A3E]/20 transition-colors"
            >
              BURN
            </button>
          </div>
        </div>
      </div>

      {/* Coin slot plug-in */}
      <div className="bg-[#15161A] border border-[#2A2C33] p-4">
        <div className="text-[10px] text-[#9AA0AA] tracking-widest mb-3">
          PLUG IN COIN SLOT (5-7)
        </div>
        <div className="grid grid-cols-2 md:grid-cols-5 gap-2">
          <select
            value={slotNum}
            onChange={(e) => setSlotNum(e.target.value)}
            className="bg-[#1A1B20] border border-[#2A2C33] px-2 py-2 text-xs font-mono text-[#E7E9EE] focus:outline-none"
          >
            <option value="5">SLOT 5</option>
            <option value="6">SLOT 6</option>
            <option value="7">SLOT 7</option>
          </select>
          <input
            value={slotName}
            onChange={(e) => setSlotName(e.target.value)}
            placeholder="Symbol"
            className="bg-[#1A1B20] border border-[#2A2C33] px-2 py-2 text-xs font-mono text-[#E7E9EE] placeholder-[#6F7580] focus:outline-none"
          />
          <input
            value={slotPrice}
            onChange={(e) => setSlotPrice(e.target.value)}
            placeholder="Price"
            type="number"
            className="bg-[#1A1B20] border border-[#2A2C33] px-2 py-2 text-xs font-mono text-[#E7E9EE] placeholder-[#6F7580] focus:outline-none"
          />
          <input
            value={slotYield}
            onChange={(e) => setSlotYield(e.target.value)}
            placeholder="Yield %"
            type="number"
            className="bg-[#1A1B20] border border-[#2A2C33] px-2 py-2 text-xs font-mono text-[#E7E9EE] placeholder-[#6F7580] focus:outline-none"
          />
          <button
            type="button"
            onClick={handlePlugIn}
            className="px-4 py-2 bg-[#D6B36A]/10 border border-[#D6B36A]/40 text-[#D6B36A] text-xs tracking-widest hover:bg-[#D6B36A]/20 transition-colors"
          >
            PLUG IN
          </button>
        </div>
      </div>
    </div>
  );
}
