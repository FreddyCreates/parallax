import { useState } from "react";
import { toast } from "sonner";
import type { ParallaxData } from "../hooks/useParallax";

interface Props {
  data: ParallaxData;
  callWrite: (fn: string, ...args: unknown[]) => Promise<unknown>;
}

export function FounderOverride({ data, callWrite }: Props) {
  const [mintAmt, setMintAmt] = useState("");
  const [burnAmt, setBurnAmt] = useState("");
  const [orgId, setOrgId] = useState("");
  const [dest, setDest] = useState("");
  const [slot, setSlot] = useState("5");
  const [coinName, setCoinName] = useState("");
  const [coinPrice, setCoinPrice] = useState("");
  const [coinYield, setCoinYield] = useState("");
  const [withdrawAmt, setWithdrawAmt] = useState("");
  const [wallet, setWallet] = useState("");

  const run = async (fn: string, label: string, ...args: unknown[]) => {
    try {
      const result = await callWrite(fn, ...args);
      if (result !== false) {
        toast.success(`${label} executed`);
      } else {
        toast.error(`${label} rejected by protocol`);
      }
    } catch {
      toast.error(`${label} failed`);
    }
  };

  const { attribution, mtc, creator } = data;

  return (
    <div className="space-y-4">
      <div className="text-[10px] text-[#D6B36A] tracking-widest uppercase border-b border-[#D6B36A]/30 pb-2">
        FOUNDER OVERRIDE PANEL — UNCONDITIONAL AUTHORITY —{" "}
        {attribution.name.toUpperCase()}
      </div>

      {/* Authority confirmation */}
      <div className="bg-[#1A0D00] border border-[#D6B36A]/30 p-4">
        <div className="flex items-center gap-3">
          <div className="w-2 h-2 rounded-full bg-[#D6B36A] animate-pulse" />
          <div>
            <div className="text-[10px] text-[#D6B36A] tracking-widest">
              CREATOR SUPREMACY LAW ACTIVE
            </div>
            <div className="text-[9px] text-[#9AA0AA] mt-0.5">
              {attribution.name} · {attribution.title} ·{" "}
              {attribution.jurisdiction} · {attribution.year}
            </div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* Redirect yield */}
        <div className="bg-[#15161A] border border-[#2A2C33] p-4">
          <div className="text-[10px] text-[#D6B36A] tracking-widest mb-3">
            REDIRECT ORGANISM YIELD
          </div>
          <div className="space-y-2">
            <input
              value={orgId}
              onChange={(e) => setOrgId(e.target.value)}
              placeholder="Organism ID"
              type="number"
              className="w-full bg-[#1A1B20] border border-[#2A2C33] px-3 py-2 text-xs font-mono text-[#E7E9EE] placeholder-[#6F7580] focus:outline-none focus:border-[#D6B36A]"
            />
            <input
              value={dest}
              onChange={(e) => setDest(e.target.value)}
              placeholder="Destination"
              className="w-full bg-[#1A1B20] border border-[#2A2C33] px-3 py-2 text-xs font-mono text-[#E7E9EE] placeholder-[#6F7580] focus:outline-none focus:border-[#D6B36A]"
            />
            <button
              type="button"
              onClick={() =>
                run(
                  "founderOverrideYield",
                  "Yield redirect",
                  BigInt(orgId || 1),
                  dest,
                )
              }
              className="w-full py-2 bg-[#D6B36A]/10 border border-[#D6B36A]/40 text-[#D6B36A] text-[10px] tracking-widest hover:bg-[#D6B36A]/20 transition-colors"
            >
              REDIRECT NOW — INSTANT • UNCONDITIONAL
            </button>
          </div>
        </div>

        {/* Withdraw */}
        <div className="bg-[#15161A] border border-[#2A2C33] p-4">
          <div className="text-[10px] text-[#44D17B] tracking-widest mb-1">
            WITHDRAW TO EXTERNAL WALLET
          </div>
          <div className="text-[9px] text-[#6F7580] mb-3">
            AVAILABLE: {creator.withdrawableIcp.toFixed(4)} ICP
          </div>
          <div className="space-y-2">
            <input
              value={withdrawAmt}
              onChange={(e) => setWithdrawAmt(e.target.value)}
              placeholder="ICP amount"
              type="number"
              className="w-full bg-[#1A1B20] border border-[#2A2C33] px-3 py-2 text-xs font-mono text-[#E7E9EE] placeholder-[#6F7580] focus:outline-none focus:border-[#44D17B]"
            />
            <input
              value={wallet}
              onChange={(e) => setWallet(e.target.value)}
              placeholder="ICP wallet address"
              className="w-full bg-[#1A1B20] border border-[#2A2C33] px-3 py-2 text-xs font-mono text-[#E7E9EE] placeholder-[#6F7580] focus:outline-none focus:border-[#44D17B]"
            />
            <button
              type="button"
              onClick={() =>
                run(
                  "withdrawToExternalWallet",
                  "Withdrawal",
                  Number.parseFloat(withdrawAmt || "0"),
                  wallet,
                )
              }
              className="w-full py-2 bg-[#44D17B]/10 border border-[#44D17B]/40 text-[#44D17B] text-[10px] tracking-widest hover:bg-[#44D17B]/20 transition-colors"
            >
              EXTRACT TO WALLET
            </button>
          </div>
        </div>

        {/* Mint */}
        <div className="bg-[#15161A] border border-[#2A2C33] p-4">
          <div className="text-[10px] text-[#44D17B] tracking-widest mb-1">
            MINT MTC
          </div>
          <div className="text-[9px] text-[#6F7580] mb-3">
            CIRCULATING:{" "}
            {mtc.circulating.toLocaleString("en-US", {
              maximumFractionDigits: 0,
            })}
          </div>
          <div className="flex gap-2">
            <input
              value={mintAmt}
              onChange={(e) => setMintAmt(e.target.value)}
              placeholder="Amount"
              type="number"
              className="flex-1 bg-[#1A1B20] border border-[#2A2C33] px-3 py-2 text-xs font-mono text-[#E7E9EE] placeholder-[#6F7580] focus:outline-none"
            />
            <button
              type="button"
              onClick={() =>
                run("mintMtc", "MTC mint", Number.parseFloat(mintAmt || "0"))
              }
              className="px-4 py-2 bg-[#44D17B]/10 border border-[#44D17B]/40 text-[#44D17B] text-xs tracking-widest hover:bg-[#44D17B]/20"
            >
              MINT
            </button>
          </div>
        </div>

        {/* Burn */}
        <div className="bg-[#15161A] border border-[#2A2C33] p-4">
          <div className="text-[10px] text-[#B23A3E] tracking-widest mb-1">
            BURN MTC
          </div>
          <div className="text-[9px] text-[#6F7580] mb-3">
            HARD FLOOR:{" "}
            {mtc.hardFloor.toLocaleString("en-US", {
              maximumFractionDigits: 0,
            })}
          </div>
          <div className="flex gap-2">
            <input
              value={burnAmt}
              onChange={(e) => setBurnAmt(e.target.value)}
              placeholder="Amount"
              type="number"
              className="flex-1 bg-[#1A1B20] border border-[#2A2C33] px-3 py-2 text-xs font-mono text-[#E7E9EE] placeholder-[#6F7580] focus:outline-none"
            />
            <button
              type="button"
              onClick={() =>
                run("burnMtc", "MTC burn", Number.parseFloat(burnAmt || "0"))
              }
              className="px-4 py-2 bg-[#B23A3E]/10 border border-[#B23A3E]/40 text-[#B23A3E] text-xs tracking-widest hover:bg-[#B23A3E]/20"
            >
              BURN
            </button>
          </div>
        </div>
      </div>

      {/* Plug-in coin slot */}
      <div className="bg-[#15161A] border border-[#2A2C33] p-4">
        <div className="text-[10px] text-[#9AA0AA] tracking-widest mb-3">
          PLUG IN COIN SLOT (5-7)
        </div>
        <div className="grid grid-cols-2 md:grid-cols-5 gap-2">
          <select
            value={slot}
            onChange={(e) => setSlot(e.target.value)}
            className="bg-[#1A1B20] border border-[#2A2C33] px-2 py-2 text-xs font-mono text-[#E7E9EE] focus:outline-none"
          >
            <option value="5">SLOT 5</option>
            <option value="6">SLOT 6</option>
            <option value="7">SLOT 7</option>
          </select>
          <input
            value={coinName}
            onChange={(e) => setCoinName(e.target.value)}
            placeholder="Symbol"
            className="bg-[#1A1B20] border border-[#2A2C33] px-2 py-2 text-xs font-mono text-[#E7E9EE] placeholder-[#6F7580] focus:outline-none"
          />
          <input
            value={coinPrice}
            onChange={(e) => setCoinPrice(e.target.value)}
            placeholder="Price ($)"
            type="number"
            className="bg-[#1A1B20] border border-[#2A2C33] px-2 py-2 text-xs font-mono text-[#E7E9EE] placeholder-[#6F7580] focus:outline-none"
          />
          <input
            value={coinYield}
            onChange={(e) => setCoinYield(e.target.value)}
            placeholder="Yield %"
            type="number"
            className="bg-[#1A1B20] border border-[#2A2C33] px-2 py-2 text-xs font-mono text-[#E7E9EE] placeholder-[#6F7580] focus:outline-none"
          />
          <button
            type="button"
            onClick={() =>
              run(
                "plugInCoinSlot",
                "Coin slot",
                BigInt(slot),
                coinName,
                Number.parseFloat(coinPrice || "0"),
                Number.parseFloat(coinYield || "0") / 100,
              )
            }
            className="px-4 py-2 bg-[#D6B36A]/10 border border-[#D6B36A]/40 text-[#D6B36A] text-xs tracking-widest hover:bg-[#D6B36A]/20"
          >
            PLUG IN
          </button>
        </div>
      </div>

      {/* Patent log */}
      <div className="bg-[#15161A] border border-[#2A2C33] p-4">
        <div className="text-[10px] text-[#9AA0AA] tracking-widest mb-3">
          IP LOCK — PATENT REGISTRY — {data.patents.length} MECHANISMS LOCKED
        </div>
        <div className="space-y-2">
          {data.patents.map((p) => (
            <div key={p.id} className="border border-[#2A2C33] p-3">
              <div className="text-[10px] text-[#D6B36A] tracking-wider">
                {p.mechanismName}
              </div>
              <div className="text-[9px] text-[#9AA0AA] mt-1">
                {p.description}
              </div>
              <div className="text-[8px] text-[#6F7580] mt-1 font-mono">
                {p.creatorAttribution} ·{" "}
                {p.doctrineHash
                  ? `0x${(p.doctrineHash >>> 0).toString(16).toUpperCase()}`
                  : "PENDING"}
              </div>
            </div>
          ))}
          {data.patents.length === 0 && (
            <div className="text-[9px] text-[#6F7580] tracking-widest">
              LOCKING AT GENESIS BEAT...
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
