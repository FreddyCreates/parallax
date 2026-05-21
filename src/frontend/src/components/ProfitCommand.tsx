import { useState } from "react";
import { toast } from "sonner";
import type { ParallaxData } from "../hooks/useParallax";

interface Props {
  data: ParallaxData;
  callWrite: (fn: string, ...args: unknown[]) => Promise<unknown>;
}

type WithdrawResult = {
  success: boolean;
  blockIndex?: bigint | bigint[];
  error?: string | string[];
} | null;

const STREAM_NAMES = [
  { id: 1, name: "NNS ICP STAKING YIELD", type: "INTERNAL", color: "#D6B36A" },
  { id: 2, name: "ETH PRODUCTIVE RESERVE", type: "INTERNAL", color: "#6B7FDB" },
  {
    id: 3,
    name: "BTC HARD FLOOR APPRECIATION",
    type: "INTERNAL",
    color: "#D7B24A",
  },
  { id: 4, name: "MTC SPREAD (0.5%)", type: "INTERNAL", color: "#44D17B" },
  { id: 5, name: "TIER ACCESS FEES", type: "INTERNAL", color: "#D6B36A" },
  { id: 6, name: "COGNITION TAX", type: "INTERNAL", color: "#9AA0AA" },
  { id: 7, name: "ARBITRAGE CAPTURE", type: "INTERNAL", color: "#44D17B" },
  { id: 8, name: "VELOCITY TOLL", type: "INTERNAL", color: "#D7B24A" },
  { id: 9, name: "PROTECTION PREMIUM", type: "INTERNAL", color: "#B23A3E" },
  { id: 10, name: "COMPOUNDING OVERRIDE", type: "INTERNAL", color: "#D6B36A" },
  {
    id: 11,
    name: "INTELLIGENCE API SUBSCRIPTIONS",
    type: "EXTERNAL",
    color: "#44D17B",
  },
  { id: 12, name: "RESEARCH REPORT SALES", type: "EXTERNAL", color: "#44D17B" },
  {
    id: 13,
    name: "DOCTRINE LICENSING ROYALTIES",
    type: "EXTERNAL",
    color: "#D6B36A",
  },
  {
    id: 14,
    name: "ORGANISM FRANCHISE FEES",
    type: "EXTERNAL",
    color: "#D6B36A",
  },
  { id: 15, name: "KNOWLEDGE NODE SALES", type: "EXTERNAL", color: "#D6B36A" },
  { id: 16, name: "DATA ACCESS TOLL", type: "EXTERNAL", color: "#44D17B" },
  {
    id: 17,
    name: "INTELLIGENCE CONTRACTS",
    type: "EXTERNAL",
    color: "#44D17B",
  },
  {
    id: 18,
    name: "EXTERNAL YIELD DELTA CAPTURE",
    type: "EXTERNAL",
    color: "#6B7FDB",
  },
  {
    id: 19,
    name: "SIGNAL FEED PREMIUM TIER",
    type: "EXTERNAL",
    color: "#44D17B",
  },
  {
    id: 20,
    name: "CREATOR WITHDRAWAL LEDGER",
    type: "CREATOR",
    color: "#D6B36A",
  },
  {
    id: 21,
    name: "QUANTUM COHERENCE RESERVE",
    type: "QUANTUM",
    color: "#D6B36A",
  },
  {
    id: 22,
    name: "MAXWELL'S DEMON OBSERVATION YIELD",
    type: "QUANTUM",
    color: "#44D17B",
  },
];

export function ProfitCommand({ data, callWrite }: Props) {
  const { streams, creator } = data;
  const [showWithdraw, setShowWithdraw] = useState(false);
  const [withdrawAmount, setWithdrawAmount] = useState("");
  const [walletAddress, setWalletAddress] = useState("");
  const [withdrawalPending, setWithdrawalPending] = useState(false);
  const [withdrawalResult, setWithdrawalResult] =
    useState<WithdrawResult>(null);

  const streamValues: Record<number, number> = {
    1: streams.s1,
    2: streams.s2,
    3: streams.s3,
    4: streams.s4,
    5: streams.s5,
    6: streams.s6,
    7: streams.s7,
    8: streams.s8,
    9: streams.s9,
    10: streams.s10,
    11: streams.s11,
    12: streams.s12,
    13: streams.s13,
    14: streams.s14,
    15: streams.s15,
    16: streams.s16,
    17: streams.s17,
    18: streams.s18,
    19: streams.s19,
    20: streams.s20,
    21: streams.s21,
    22: streams.s22,
  };

  const handleWithdraw = async () => {
    const amount = Number.parseFloat(withdrawAmount);
    if (!amount || !walletAddress) return;
    setWithdrawalPending(true);
    setWithdrawalResult(null);
    try {
      const res = (await callWrite(
        "withdrawToExternalWallet",
        amount,
        walletAddress,
      )) as WithdrawResult;
      const blockIdx = Array.isArray(res?.blockIndex)
        ? res.blockIndex[0]
        : res?.blockIndex;
      const errMsg = Array.isArray(res?.error) ? res.error[0] : res?.error;
      const result: WithdrawResult = {
        success: res?.success ?? false,
        blockIndex: blockIdx,
        error: errMsg,
      };
      setWithdrawalResult(result);
      if (result.success) {
        toast.success(
          `LIBERATOR EXECUTED — Block #${blockIdx?.toString() ?? "confirmed"}`,
        );
        setShowWithdraw(false);
        setWithdrawAmount("");
        setWalletAddress("");
      } else {
        toast.error(errMsg ?? "Insufficient withdrawable ICP");
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : "Withdrawal failed";
      setWithdrawalResult({ success: false, error: msg });
      toast.error(msg);
    } finally {
      setWithdrawalPending(false);
    }
  };

  return (
    <div className="space-y-4">
      <div className="text-[10px] text-[#9AA0AA] tracking-widest uppercase border-b border-[#2A2C33] pb-2">
        PROFIT COMMAND — 22 SIMULTANEOUS STREAMS — ALL ACTIVE FROM BEAT 1
      </div>

      {/* Total */}
      <div className="bg-[#0D1A0F] border border-[#44D17B]/30 p-4">
        <div className="text-[10px] text-[#44D17B]/70 tracking-widest mb-1">
          TOTAL PROFIT ALL STREAMS
        </div>
        <div className="font-mono text-3xl font-bold text-[#44D17B]">
          ${streams.total.toFixed(2)}
        </div>
        <div className="text-[9px] text-[#6F7580] mt-1">
          RUNNING TOTAL — ALL 22 STREAMS COMPOUNDING
        </div>
      </div>

      {/* Creator reserve summary */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        {[
          {
            label: "ICP RESERVE",
            value: `${creator.icpReserve.toFixed(4)} ICP`,
          },
          {
            label: "BTC RESERVE",
            value: `${creator.btcReserve.toFixed(8)} BTC`,
          },
          {
            label: "ETH RESERVE",
            value: `${creator.ethReserve.toFixed(6)} ETH`,
          },
          {
            label: "USD EQUIVALENT",
            value: `$${creator.totalUsdEquivalent.toFixed(2)}`,
          },
        ].map((s) => (
          <div
            key={s.label}
            className="bg-[#15161A] border border-[#2A2C33] p-3"
          >
            <div className="text-[9px] text-[#6F7580] tracking-widest">
              {s.label}
            </div>
            <div className="font-mono text-xs font-bold text-[#D6B36A] mt-1">
              {s.value}
            </div>
          </div>
        ))}
      </div>

      {/* Withdrawal ledger */}
      <div className="bg-[#15161A] border border-[#D6B36A]/30 p-4">
        <div className="flex justify-between items-center">
          <div>
            <div className="text-[10px] text-[#D6B36A] tracking-widest mb-1">
              WITHDRAWABLE ICP
            </div>
            <div className="font-mono text-xl font-bold text-[#D6B36A]">
              {creator.withdrawableIcp.toFixed(4)} ICP
            </div>
            <div className="text-[9px] text-[#6F7580] mt-1">
              TOTAL WITHDRAWN: {creator.totalWithdrawn.toFixed(4)} ICP
            </div>
          </div>
          <button
            type="button"
            onClick={() => setShowWithdraw(!showWithdraw)}
            data-ocid="profit.open_modal_button"
            className="px-4 py-2 bg-[#D6B36A]/10 border border-[#D6B36A]/40 text-[#D6B36A] text-[10px] tracking-widest hover:bg-[#D6B36A]/20 transition-colors"
          >
            EXTRACT TO WALLET
          </button>
        </div>
        {showWithdraw && (
          <div
            className="mt-4 border-t border-[#2A2C33] pt-4 space-y-2"
            data-ocid="profit.modal"
          >
            <div className="grid grid-cols-1 md:grid-cols-3 gap-2">
              <input
                value={withdrawAmount}
                onChange={(e) => setWithdrawAmount(e.target.value)}
                placeholder="ICP Amount"
                type="number"
                data-ocid="profit.input"
                disabled={withdrawalPending}
                className="bg-[#1A1B20] border border-[#2A2C33] px-3 py-2 text-xs font-mono text-[#E7E9EE] placeholder-[#6F7580] focus:outline-none focus:border-[#D6B36A] disabled:opacity-50"
              />
              <input
                value={walletAddress}
                onChange={(e) => setWalletAddress(e.target.value)}
                placeholder="External ICP wallet address"
                data-ocid="profit.textarea"
                disabled={withdrawalPending}
                className="bg-[#1A1B20] border border-[#2A2C33] px-3 py-2 text-xs font-mono text-[#E7E9EE] placeholder-[#6F7580] focus:outline-none focus:border-[#D6B36A] disabled:opacity-50"
              />
              <button
                type="button"
                onClick={handleWithdraw}
                disabled={
                  withdrawalPending || !withdrawAmount || !walletAddress
                }
                data-ocid="profit.confirm_button"
                className="px-4 py-2 bg-[#D6B36A]/20 border border-[#D6B36A] text-[#D6B36A] text-[10px] tracking-widest hover:bg-[#D6B36A]/30 transition-colors disabled:opacity-40"
              >
                {withdrawalPending ? (
                  <span className="flex items-center justify-center gap-2">
                    <span className="animate-pulse">●</span> LIBERATOR
                    EXECUTING...
                  </span>
                ) : (
                  "CONFIRM WITHDRAWAL"
                )}
              </button>
            </div>
            {withdrawalPending && (
              <div
                className="font-mono text-[8px] text-center text-[#D6B36A] animate-pulse"
                data-ocid="profit.loading_state"
              >
                LIBERATOR EXECUTING — ICP TRANSFER IN PROGRESS...
              </div>
            )}
            {withdrawalResult && !withdrawalPending && (
              <div
                className="px-3 py-2 border font-mono text-[9px] space-y-1"
                style={{
                  borderColor: withdrawalResult.success
                    ? "#44D17B55"
                    : "#B23A3E55",
                  background: withdrawalResult.success
                    ? "#44D17B08"
                    : "#B23A3E08",
                  color: withdrawalResult.success ? "#44D17B" : "#B23A3E",
                }}
                data-ocid={
                  withdrawalResult.success
                    ? "profit.success_state"
                    : "profit.error_state"
                }
              >
                {withdrawalResult.success ? (
                  <>
                    <div className="tracking-wider">
                      ✓ LIBERATOR EXECUTED — ICP TRANSFER CONFIRMED
                    </div>
                    {withdrawalResult.blockIndex != null && (
                      <div style={{ color: "#6B7FDB" }}>
                        BLOCK INDEX:{" "}
                        {(withdrawalResult.blockIndex as bigint).toString()}
                      </div>
                    )}
                  </>
                ) : (
                  <div className="tracking-wider">
                    ✗{" "}
                    {(Array.isArray(withdrawalResult.error)
                      ? withdrawalResult.error[0]
                      : withdrawalResult.error) ?? "TRANSFER FAILED"}
                  </div>
                )}
              </div>
            )}
          </div>
        )}
      </div>

      {/* Quantum stream callout */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
        <div className="bg-amber-950/10 border border-amber-900/30 p-3">
          <div className="text-[8px] text-amber-700 tracking-widest mb-1">
            STREAM 21 — QUANTUM
          </div>
          <div
            className="font-mono text-lg font-bold"
            style={{ color: "#D6B36A" }}
          >
            {streams.s21.toFixed(8)}
          </div>
          <div className="text-[8px] text-zinc-600">
            QUANTUM COHERENCE RESERVE · baseRate × C²
          </div>
        </div>
        <div className="bg-emerald-950/10 border border-emerald-900/30 p-3">
          <div className="text-[8px] text-emerald-800 tracking-widest mb-1">
            STREAM 22 — MAXWELL'S DEMON
          </div>
          <div className="font-mono text-lg font-bold text-emerald-400">
            {streams.s22.toFixed(8)}
          </div>
          <div className="text-[8px] text-zinc-600">
            OBSERVATION YIELD · k × ΔH PER OUTCALL
          </div>
        </div>
      </div>

      {/* 22 streams grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
        {STREAM_NAMES.map((s) => {
          const val = streamValues[s.id] ?? 0;
          const isQuantum = s.type === "QUANTUM";
          return (
            <div
              key={s.id}
              className="bg-[#15161A] border p-3 flex items-center justify-between"
              style={{ borderColor: isQuantum ? `${s.color}30` : "#2A2C33" }}
              data-ocid={`profit.item.${s.id}`}
            >
              <div className="flex items-center gap-2">
                <span className="text-[9px] font-mono text-[#6F7580] w-4">
                  {s.id.toString().padStart(2, "0")}
                </span>
                <div>
                  <div className="text-[9px] text-[#E7E9EE] tracking-wide">
                    {s.name}
                  </div>
                  <span
                    className="text-[8px] px-1 border tracking-widest"
                    style={{ borderColor: `${s.color}40`, color: s.color }}
                  >
                    {s.type}
                  </span>
                </div>
              </div>
              <div className="text-right">
                <div
                  className="font-mono text-xs font-bold"
                  style={{ color: s.color }}
                >
                  {val.toFixed(6)}
                </div>
                <div className="text-[8px] text-[#6F7580]">RUNNING TOTAL</div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
