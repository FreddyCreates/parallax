import type { ParallaxData } from "../hooks/useParallax";

interface Props {
  data: ParallaxData;
}

const EVENT_COLORS: Record<string, string> = {
  GENESIS: "#D6B36A",
  YIELD_DISTRIBUTION: "#44D17B",
  ORGANISM_REGISTER: "#6B7FDB",
  FOUNDER_OVERRIDE: "#D7B24A",
  WITHDRAWAL: "#D6B36A",
  MTC_MINT: "#44D17B",
  MTC_BURN: "#B23A3E",
  COIN_SLOT_PLUGIN: "#6B7FDB",
};

function formatTs(ns: number): string {
  if (!ns) return "--";
  const ms = ns / 1_000_000;
  return new Date(ms).toLocaleString("en-US", { hour12: false });
}

export function AuditLedger({ data }: Props) {
  const { audit, attribution } = data;

  const exportCsv = () => {
    const header =
      "ID,Beat,Timestamp,Type,Description,Amount,Currency,From,To,DoctrineHash";
    const rows = audit.map((e) =>
      [
        e.id,
        e.beat,
        formatTs(e.timestamp),
        e.eventType,
        `"${e.description}"`,
        e.amount.toFixed(6),
        e.currency,
        e.fromEntity,
        e.toEntity,
        e.doctrineHash,
      ].join(","),
    );
    const blob = new Blob([[header, ...rows].join("\n")], { type: "text/csv" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `PARALLAX_AUDIT_${Date.now()}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between border-b border-[#2A2C33] pb-2">
        <span className="text-[10px] text-[#9AA0AA] tracking-widest uppercase">
          AUDIT LEDGER — ATTORNEY-GRADE — PERMANENT — ON-CHAIN
        </span>
        <button
          type="button"
          onClick={exportCsv}
          className="px-3 py-1.5 border border-[#2A2C33] text-[9px] text-[#9AA0AA] tracking-widest hover:border-[#D6B36A] hover:text-[#D6B36A] transition-colors"
        >
          EXPORT CSV
        </button>
      </div>

      {/* Attribution header */}
      <div className="bg-[#15161A] border border-[#D6B36A]/20 p-3">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3 text-[9px]">
          <div>
            <span className="text-[#6F7580] tracking-widest">CREATOR</span>
            <div className="font-mono text-[#D6B36A]">{attribution.name}</div>
          </div>
          <div>
            <span className="text-[#6F7580] tracking-widest">TITLE</span>
            <div className="font-mono text-[#E7E9EE]">{attribution.title}</div>
          </div>
          <div>
            <span className="text-[#6F7580] tracking-widest">JURISDICTION</span>
            <div className="font-mono text-[#E7E9EE]">
              {attribution.jurisdiction}
            </div>
          </div>
          <div>
            <span className="text-[#6F7580] tracking-widest">
              DOCTRINE HASH
            </span>
            <div className="font-mono text-[#D6B36A]">
              {attribution.doctrineHash
                ? `0x${(attribution.doctrineHash >>> 0).toString(16).toUpperCase().padStart(8, "0")}`
                : "PENDING"}
            </div>
          </div>
        </div>
      </div>

      {/* Audit table */}
      <div className="overflow-x-auto">
        <table className="w-full text-[9px] font-mono">
          <thead>
            <tr className="border-b border-[#2A2C33]">
              {[
                "ID",
                "BEAT",
                "TIMESTAMP",
                "TYPE",
                "DESCRIPTION",
                "AMOUNT",
                "FROM",
                "TO",
              ].map((h) => (
                <th
                  key={h}
                  className="text-left px-2 py-2 text-[#6F7580] tracking-widest font-normal whitespace-nowrap"
                >
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {audit.length === 0 ? (
              <tr>
                <td
                  colSpan={8}
                  className="px-2 py-8 text-center text-[#6F7580] tracking-widest"
                >
                  ENGINE INITIALIZING... FIRST AUDIT ENTRIES WILL APPEAR AFTER
                  GENESIS LOCK
                </td>
              </tr>
            ) : (
              audit.map((e) => (
                <tr
                  key={e.id}
                  className="border-b border-[#2A2C33]/40 hover:bg-[#15161A] transition-colors"
                >
                  <td className="px-2 py-2 text-[#6F7580]">{e.id}</td>
                  <td className="px-2 py-2 text-[#9AA0AA]">{e.beat}</td>
                  <td className="px-2 py-2 text-[#9AA0AA] whitespace-nowrap">
                    {formatTs(e.timestamp)}
                  </td>
                  <td className="px-2 py-2 whitespace-nowrap">
                    <span
                      style={{ color: EVENT_COLORS[e.eventType] ?? "#9AA0AA" }}
                    >
                      {e.eventType}
                    </span>
                  </td>
                  <td className="px-2 py-2 text-[#E7E9EE] max-w-xs truncate">
                    {e.description}
                  </td>
                  <td className="px-2 py-2 text-[#44D17B] whitespace-nowrap">
                    {e.amount.toFixed(4)} {e.currency}
                  </td>
                  <td className="px-2 py-2 text-[#9AA0AA] whitespace-nowrap">
                    {e.fromEntity}
                  </td>
                  <td className="px-2 py-2 text-[#9AA0AA] whitespace-nowrap">
                    {e.toEntity}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
