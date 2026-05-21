import { KalmanChart } from "../components/KalmanChart";

interface Shell3State {
  coherence: number;
  superradiance: number;
  kalmanConf: number;
  nodeCount: number;
}
interface PredictionTabProps {
  kalmanPredictions: number[];
  shell3State: Shell3State | null;
  loading: boolean;
}

export function PredictionTab({
  kalmanPredictions,
  shell3State,
  loading,
}: PredictionTabProps) {
  const meanActivation =
    kalmanPredictions.length > 0
      ? kalmanPredictions.reduce((a, b) => a + b, 0) / kalmanPredictions.length
      : 0;
  const gabaRate = shell3State ? Math.min(shell3State.coherence / 5, 1) : 0;

  return (
    <div className="space-y-6" data-ocid="prediction.panel">
      <div className="panel-glass p-5">
        <div className="font-mono text-[9px] tracking-[0.4em] text-muted-foreground mb-1">
          60-STEP KALMAN FIELD — SHELL 3 SUBSTRATE
        </div>
        <div className="font-mono text-[8px] text-muted-foreground mb-6">
          PREDICTIVE CONFIDENCE CURVE · NODE ACTIVATION TRAJECTORY
        </div>
        {loading && kalmanPredictions.length === 0 ? (
          <div
            className="w-full h-40 skeleton-dark"
            data-ocid="prediction.loading_state"
          />
        ) : (
          <KalmanChart
            predictions={kalmanPredictions}
            label="NODE ACTIVATION PREDICTION · STEPS 0–59"
          />
        )}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="panel-glass p-4">
          <div className="font-mono text-[8px] tracking-[0.3em] text-muted-foreground mb-2">
            KALMAN CONFIDENCE
          </div>
          <div
            className="font-mono text-2xl"
            style={{
              color: "oklch(0.65 0.28 290)",
              textShadow: "0 0 12px oklch(0.65 0.28 290 / 0.4)",
            }}
          >
            {loading
              ? "—"
              : `${((shell3State?.kalmanConf ?? 0) * 100).toFixed(2)}%`}
          </div>
        </div>
        <div className="panel-glass p-4">
          <div className="font-mono text-[8px] tracking-[0.3em] text-muted-foreground mb-2">
            MEAN ACTIVATION
          </div>
          <div
            className="font-mono text-2xl"
            style={{
              color: "oklch(0.72 0.15 200)",
              textShadow: "0 0 12px oklch(0.72 0.15 200 / 0.4)",
            }}
          >
            {loading ? "—" : meanActivation.toFixed(4)}
          </div>
        </div>
        <div className="panel-glass p-4">
          <div className="font-mono text-[8px] tracking-[0.3em] text-muted-foreground mb-2">
            BEE GABA SPARSE RATE
          </div>
          <div
            className="font-mono text-2xl"
            style={{
              color: "oklch(0.62 0.17 145)",
              textShadow: "0 0 12px oklch(0.62 0.17 145 / 0.4)",
            }}
          >
            {loading ? "—" : `${(gabaRate * 100).toFixed(2)}%`}
          </div>
        </div>
      </div>

      <div className="panel-glass p-4">
        <div className="font-mono text-[8px] tracking-[0.3em] text-muted-foreground mb-3">
          PREDICTION FIELD STATUS
        </div>
        <div className="space-y-2">
          {[
            {
              label: "SHELL 3 COHERENCE",
              value: shell3State?.coherence?.toFixed(6) ?? "—",
            },
            {
              label: "NODE COUNT",
              value: String(shell3State?.nodeCount ?? 64),
            },
            { label: "PREDICTION WINDOW", value: "60 STEPS" },
            { label: "ALGORITHM", value: "KALMAN FILTER · SHELL 3" },
            { label: "BEE NEURON MODEL", value: "GABA-SPARSE · ACTIVE" },
          ].map((m) => (
            <div
              key={m.label}
              className="flex justify-between py-1 border-b border-white/5"
            >
              <span className="font-mono text-[9px] text-muted-foreground">
                {m.label}
              </span>
              <span
                className="font-mono text-[9px]"
                style={{ color: "oklch(0.72 0.15 200)" }}
              >
                {m.value}
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
