interface KalmanChartProps {
  predictions: number[];
  label?: string;
}

export function KalmanChart({ predictions, label }: KalmanChartProps) {
  const W = 600;
  const H = 160;
  const PAD = 20;

  if (!predictions || predictions.length < 2) {
    return (
      <div className="w-full h-40 skeleton-dark flex items-center justify-center">
        <span className="font-mono text-xs text-muted-foreground">
          AWAITING SIGNAL...
        </span>
      </div>
    );
  }

  const vals = predictions.slice(0, 60);
  const minV = Math.min(...vals);
  const maxV = Math.max(...vals);
  const range = maxV - minV || 1;
  const plotW = W - PAD * 2;
  const plotH = H - PAD * 2;

  const points = vals.map((v, i) => {
    const x = PAD + (i / (vals.length - 1)) * plotW;
    const y = PAD + plotH - ((v - minV) / range) * plotH;
    return `${x},${y}`;
  });

  const pathD = `M ${points.join(" L ")}`;
  const areaD = `M ${PAD},${H - PAD} L ${points.join(" L ")} L ${PAD + plotW},${H - PAD} Z`;
  const gridLines = [0, 0.25, 0.5, 0.75, 1];

  // Sample every 5th point for dot markers
  const dotPoints = vals
    .map((v, i) => ({ v, i }))
    .filter(({ i }) => i % 5 === 0)
    .map(({ v, i }) => ({
      x: PAD + (i / (vals.length - 1)) * plotW,
      y: PAD + plotH - ((v - minV) / range) * plotH,
      step: i,
    }));

  return (
    <div className="w-full">
      {label && (
        <div className="font-mono text-[9px] tracking-[0.3em] text-muted-foreground mb-2">
          {label}
        </div>
      )}
      <svg
        width="100%"
        viewBox={`0 0 ${W} ${H}`}
        preserveAspectRatio="none"
        className="w-full h-40"
      >
        <title>Kalman prediction field</title>
        <defs>
          <linearGradient id="kalman-fill" x1="0" y1="0" x2="0" y2="1">
            <stop
              offset="0%"
              stopColor="oklch(0.65 0.28 290)"
              stopOpacity="0.2"
            />
            <stop
              offset="100%"
              stopColor="oklch(0.65 0.28 290)"
              stopOpacity="0"
            />
          </linearGradient>
          <filter id="line-glow">
            <feGaussianBlur stdDeviation="1.5" result="blur" />
            <feMerge>
              <feMergeNode in="blur" />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>
        </defs>
        {gridLines.map((t) => (
          <line
            key={t}
            x1={PAD}
            y1={PAD + t * plotH}
            x2={PAD + plotW}
            y2={PAD + t * plotH}
            stroke="rgba(255,255,255,0.04)"
            strokeWidth="1"
          />
        ))}
        <path d={areaD} fill="url(#kalman-fill)" />
        <path
          d={pathD}
          fill="none"
          stroke="oklch(0.65 0.28 290)"
          strokeWidth="1.5"
          filter="url(#line-glow)"
        />
        {dotPoints.map((pt) => (
          <circle
            key={`step-${pt.step}`}
            cx={pt.x}
            cy={pt.y}
            r={2}
            fill="oklch(0.65 0.28 290)"
            opacity={0.8}
          />
        ))}
      </svg>
    </div>
  );
}
