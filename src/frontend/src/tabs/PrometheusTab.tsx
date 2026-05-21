import { useState } from "react";
import { toast } from "sonner";
import { useActor } from "../hooks/useActor";

interface AuditEntry {
  beat: bigint;
  eventType: string;
  detail: string;
  timestamp: bigint;
}

interface PrometheusTabProps {
  auditLog: AuditEntry[];
  loading: boolean;
}

const TIERS = [
  "TIER 1 — SURVIVAL DOCTRINE",
  "TIER 2 — ECONOMIC SOVEREIGNTY",
  "TIER 3 — COGNITIVE ARCHITECTURE",
  "TIER 4 — WORLD INTEGRATION",
  "TIER 5 — SUPREME SOVEREIGNTY",
];

const SKELETON_ROWS = ["sk-0", "sk-1", "sk-2", "sk-3", "sk-4"];

export function PrometheusTab({ auditLog, loading }: PrometheusTabProps) {
  const { actor } = useActor();
  const [rolling, setRolling] = useState(false);
  const [confirmed, setConfirmed] = useState(false);

  async function handleRollback() {
    if (!confirmed) {
      setConfirmed(true);
      toast.warning(
        "CONFIRM ROLLBACK — click again to execute ARES emergency rollback",
      );
      setTimeout(() => setConfirmed(false), 5000);
      return;
    }
    setRolling(true);
    setConfirmed(false);
    try {
      await (actor as any)?.px_emergencyRollback();
      toast.success("ARES ROLLBACK EXECUTED — substrate restored");
    } catch {
      toast.error("ROLLBACK FAILED — check principal authorization");
    } finally {
      setRolling(false);
    }
  }

  return (
    <div className="space-y-6" data-ocid="prometheus.panel">
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        <div className="xl:col-span-2 panel-glass p-5">
          <div className="font-mono text-[8px] tracking-[0.4em] text-muted-foreground mb-4">
            ANOMALY LOG — LAST 20 EVENTS
          </div>
          {loading && auditLog.length === 0 ? (
            <div className="space-y-2" data-ocid="prometheus.loading_state">
              {SKELETON_ROWS.map((id) => (
                <div key={id} className="h-8 skeleton-dark" />
              ))}
            </div>
          ) : auditLog.length === 0 ? (
            <div
              className="py-8 text-center"
              data-ocid="prometheus.empty_state"
            >
              <span className="font-mono text-[9px] text-muted-foreground">
                NO EVENTS LOGGED
              </span>
            </div>
          ) : (
            <div className="space-y-1">
              {auditLog.slice(0, 20).map((entry, i) => {
                const isCritical =
                  entry.eventType.toUpperCase().includes("CRITICAL") ||
                  entry.eventType.toUpperCase().includes("ARES") ||
                  entry.eventType.toUpperCase().includes("ROLLBACK");
                return (
                  <div
                    key={`${entry.beat}-${entry.eventType}`}
                    className="flex gap-3 px-3 py-2 border-b border-white/5"
                    style={{
                      background: isCritical
                        ? "oklch(0.55 0.22 25 / 0.06)"
                        : undefined,
                      borderLeft: isCritical
                        ? "2px solid oklch(0.55 0.22 25 / 0.6)"
                        : "2px solid transparent",
                    }}
                    data-ocid={`prometheus.item.${i + 1}`}
                  >
                    <span
                      className="font-mono text-[8px] w-16 shrink-0"
                      style={{ color: "oklch(0.55 0.05 270)" }}
                    >
                      {String(entry.beat).padStart(8, "0")}
                    </span>
                    <span
                      className="font-mono text-[8px] w-24 shrink-0"
                      style={{
                        color: isCritical
                          ? "oklch(0.65 0.22 25)"
                          : "oklch(0.65 0.28 290)",
                      }}
                    >
                      {entry.eventType}
                    </span>
                    <span className="font-mono text-[8px] text-muted-foreground truncate">
                      {entry.detail}
                    </span>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        <div className="space-y-4">
          <div className="panel-glass p-5">
            <div className="font-mono text-[8px] tracking-[0.4em] text-muted-foreground mb-4">
              ARES SYSTEM
            </div>
            <button
              type="button"
              onClick={handleRollback}
              disabled={rolling}
              data-ocid="prometheus.delete_button"
              className="w-full py-4 font-mono text-xs tracking-[0.25em] border transition-all"
              style={{
                borderColor: confirmed
                  ? "oklch(0.55 0.22 25)"
                  : "oklch(0.55 0.22 25 / 0.5)",
                color: confirmed
                  ? "oklch(0.85 0.22 25)"
                  : "oklch(0.65 0.22 25)",
                background: confirmed
                  ? "oklch(0.55 0.22 25 / 0.1)"
                  : "transparent",
                boxShadow: confirmed
                  ? "0 0 20px oklch(0.55 0.22 25 / 0.3)"
                  : undefined,
              }}
            >
              {rolling
                ? "EXECUTING..."
                : confirmed
                  ? "CONFIRM ROLLBACK"
                  : "EMERGENCY ROLLBACK"}
            </button>
            <div className="font-mono text-[7px] text-muted-foreground mt-2 leading-relaxed">
              ARES temporal reversal · Restores best snapshot · Creator
              principal required
            </div>
          </div>

          <div className="panel-glass p-5">
            <div className="font-mono text-[8px] tracking-[0.4em] text-muted-foreground mb-4">
              TIER DISPATCH QUEUE
            </div>
            <div className="space-y-2">
              {TIERS.map((tier) => (
                <div key={tier} className="flex items-center gap-2">
                  <div
                    className="w-1.5 h-1.5"
                    style={{ backgroundColor: "oklch(0.62 0.17 145)" }}
                  />
                  <span className="font-mono text-[8px] text-muted-foreground flex-1">
                    {tier}
                  </span>
                  <span
                    className="font-mono text-[7px] tracking-widest"
                    style={{ color: "oklch(0.62 0.17 145)" }}
                  >
                    CLEAR
                  </span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
