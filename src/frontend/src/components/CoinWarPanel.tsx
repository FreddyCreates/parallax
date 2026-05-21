import { useState } from "react";
import type { ParallaxData } from "../hooks/useParallax";

interface Props {
  data: ParallaxData;
}

const COINS = [
  { slot: 1, symbol: "ICP", color: "#D6B36A", icon: "•" },
  { slot: 2, symbol: "BTC", color: "#D7B24A", icon: "₿" },
  { slot: 3, symbol: "ETH", color: "#6B7FDB", icon: "Ξ" },
  { slot: 4, symbol: "MTC", color: "#44D17B", icon: "M" },
];

export function CoinWarPanel({ data }: Props) {
  const { treasury, feeds, mtc } = data;

  const coinData = [
    {
      ...COINS[0],
      balance: treasury.icpBalance,
      staked: treasury.icpStaked,
      price: treasury.icpPrice,
      internalRate: 15.0,
      externalRate: feeds.icpPrice,
      mechanism: "NNS STAKING",
      status: "EARNING",
      statusColor: "#44D17B",
    },
    {
      ...COINS[1],
      balance: treasury.btcBalance,
      staked: treasury.btcHardFloor,
      price: treasury.btcPrice,
      internalRate: 0.0001,
      externalRate: feeds.btcMempoolFeeRate,
      mechanism: "HARD FLOOR",
      status: "DEFENDING",
      statusColor: "#B23A3E",
    },
    {
      ...COINS[2],
      balance: treasury.ethBalance,
      staked: 0,
      price: treasury.ethPrice,
      internalRate: 4.0,
      externalRate: feeds.ethLidoRate * 100,
      mechanism: "PRODUCTIVE RESERVE",
      status: "SCALING",
      statusColor: "#D6B36A",
    },
    {
      ...COINS[3],
      balance: mtc.circulating,
      staked: mtc.creatorHolding,
      price: mtc.price,
      internalRate: mtc.yieldRate * 100,
      externalRate: mtc.spreadRate * 100,
      mechanism: "SOVEREIGN CLEARING",
      status: "CLEARING",
      statusColor: "#44D17B",
    },
  ];

  const openSlots = [
    { slot: 5, ...data.feeds.slot5 },
    { slot: 6, ...data.feeds.slot6 },
    { slot: 7, ...data.feeds.slot7 },
  ];

  const liveData = feeds.liveDataActive;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between border-b border-[#2A2C33] pb-2">
        <div className="text-[10px] text-[#9AA0AA] tracking-widest uppercase">
          7-COIN WAR PANEL — EXTERNAL BENCHMARKS
        </div>
        {/* Live data badge */}
        <div
          className="flex items-center gap-1.5 border px-2 py-0.5"
          style={{
            borderColor: liveData
              ? "rgba(68,209,123,0.4)"
              : "rgba(214,168,58,0.4)",
          }}
          data-ocid="coins.toggle"
        >
          <div
            className="w-1.5 h-1.5 rounded-full"
            style={{
              backgroundColor: liveData ? "#44D17B" : "#D6A83A",
              boxShadow: liveData
                ? "0 0 5px rgba(68,209,123,0.8)"
                : "0 0 5px rgba(214,168,58,0.6)",
            }}
          />
          <span
            className="font-mono text-[9px] tracking-widest"
            style={{ color: liveData ? "#44D17B" : "#D6A83A" }}
          >
            {liveData ? "LIVE DATA" : "SIMULATED"}
          </span>
          {feeds.lastFetchBeat > 0 && (
            <span className="font-mono text-[8px] text-[#4A4F58]">
              · BEAT {feeds.lastFetchBeat.toLocaleString()}
            </span>
          )}
        </div>
      </div>

      {/* Active coins */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
        {coinData.map((coin) => (
          <div
            key={coin.symbol}
            className="bg-[#15161A] border border-[#2A2C33] p-4 rounded-sm"
          >
            <div className="flex justify-between items-start mb-3">
              <div className="flex items-center gap-2">
                <span
                  className="w-8 h-8 flex items-center justify-center bg-[#1A1B20] border border-[#2A2C33] font-bold text-sm"
                  style={{ color: coin.color }}
                >
                  {coin.icon}
                </span>
                <div>
                  <div
                    className="font-bold text-sm tracking-wider"
                    style={{ color: coin.color }}
                  >
                    {coin.symbol}
                  </div>
                  <div className="text-[9px] text-[#6F7580] tracking-widest">
                    {coin.mechanism}
                  </div>
                </div>
              </div>
              <span
                className="text-[9px] font-mono px-2 py-0.5 border tracking-widest"
                style={{
                  borderColor: `${coin.statusColor}60`,
                  color: coin.statusColor,
                }}
              >
                {coin.status}
              </span>
            </div>

            {/* Price */}
            <div className="mb-3">
              <div className="font-mono text-lg font-bold text-[#E7E9EE]">
                $
                {coin.price.toLocaleString("en-US", {
                  minimumFractionDigits: 2,
                  maximumFractionDigits: 4,
                })}
              </div>
              <div className="text-[9px] text-[#6F7580]">LIVE PRICE SIGNAL</div>
            </div>

            {/* Rates */}
            <div className="grid grid-cols-2 gap-2 mb-3">
              <div className="bg-[#1A1B20] p-2">
                <div className="text-[8px] text-[#6F7580] tracking-widest">
                  INTERNAL RATE
                </div>
                <div className="font-mono text-xs text-[#D6B36A]">
                  {coin.internalRate.toFixed(4)}%
                </div>
              </div>
              <div className="bg-[#1A1B20] p-2">
                <div className="text-[8px] text-[#6F7580] tracking-widest">
                  EXTERNAL FEED
                </div>
                <div className="font-mono text-xs text-[#44D17B]">
                  {coin.externalRate.toFixed(4)}
                  {coin.symbol === "BTC" ? " sat/vB" : "%"}
                </div>
              </div>
            </div>

            {/* Balance */}
            <div className="border-t border-[#2A2C33] pt-2 flex justify-between">
              <div>
                <div className="text-[8px] text-[#6F7580] tracking-widest">
                  BALANCE
                </div>
                <div className="font-mono text-xs text-[#E7E9EE]">
                  {coin.balance.toFixed(4)}
                </div>
              </div>
              {coin.staked > 0 && (
                <div className="text-right">
                  <div className="text-[8px] text-[#6F7580] tracking-widest">
                    {coin.symbol === "MTC" ? "CREATOR" : "STAKED"}
                  </div>
                  <div className="font-mono text-xs text-[#D6B36A]">
                    {coin.staked.toFixed(4)}
                  </div>
                </div>
              )}
            </div>
          </div>
        ))}
      </div>

      {/* Open slots */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
        {openSlots.map((slot) => (
          <OpenSlot key={slot.slot} slot={slot} />
        ))}
      </div>

      {/* External feeds summary */}
      <div className="bg-[#15161A] border border-[#2A2C33] p-4">
        <div className="text-[10px] text-[#9AA0AA] tracking-widest mb-3">
          EXTERNAL ECOSYSTEM FEEDS
        </div>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3 text-xs">
          <FeedRow
            label="BTC MEMPOOL"
            value={`${feeds.btcMempoolFeeRate.toFixed(0)} sat/vB`}
          />
          <FeedRow
            label="BTC CONGESTION"
            value={`${(feeds.btcNetworkCongestion * 100).toFixed(0)}%`}
          />
          <FeedRow
            label="LIDO APY"
            value={`${(feeds.ethLidoRate * 100).toFixed(2)}%`}
          />
          <FeedRow
            label="ROCKET POOL"
            value={`${(feeds.ethRocketPoolRate * 100).toFixed(2)}%`}
          />
          <FeedRow
            label="ETH GAS"
            value={`${feeds.ethGasPrice.toFixed(0)} GWEI`}
          />
          <FeedRow label="ICP PRICE" value={`$${feeds.icpPrice.toFixed(4)}`} />
          <FeedRow
            label="BTC PRICE"
            value={`$${feeds.btcPrice.toLocaleString()}`}
          />
          <FeedRow
            label="ETH PRICE"
            value={`$${feeds.ethPrice.toLocaleString()}`}
          />
        </div>
      </div>
    </div>
  );
}

function FeedRow({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <div className="text-[8px] text-[#6F7580] tracking-widest">{label}</div>
      <div className="font-mono text-[#44D17B]">{value}</div>
    </div>
  );
}

function OpenSlot({
  slot,
}: { slot: { slot: number; name: string; active: boolean; price: number } }) {
  return (
    <div
      className="bg-[#15161A] border border-[#2A2C33] border-dashed p-4 flex flex-col items-center justify-center text-center"
      style={{ minHeight: 120 }}
    >
      <div className="text-[10px] text-[#6F7580] tracking-widest mb-1">
        SLOT {slot.slot}
      </div>
      {slot.active ? (
        <>
          <div className="font-bold text-[#44D17B]">{slot.name}</div>
          <div className="font-mono text-xs text-[#9AA0AA]">
            ${slot.price.toFixed(4)}
          </div>
        </>
      ) : (
        <>
          <div className="text-[10px] text-[#9AA0AA] tracking-widest">
            PLUG-IN READY
          </div>
          <div className="text-[8px] text-[#6F7580] mt-1">
            COIN DETECTED ON ARRIVAL
          </div>
          <div className="text-[8px] text-[#6F7580]">
            ENGINE STARTS EARNING IMMEDIATELY
          </div>
        </>
      )}
    </div>
  );
}
