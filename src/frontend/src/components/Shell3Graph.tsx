interface Shell3GraphProps {
  activations: number[];
  coherence: number;
  beat: number;
}

export function Shell3Graph({ activations, coherence }: Shell3GraphProps) {
  const WIDTH = 480;
  const HEIGHT = 480;
  const CX = WIDTH / 2;
  const CY = HEIGHT / 2;
  const RADIUS = 190;
  const NODE_COUNT = Math.min(activations.length || 64, 64);

  const nodes = Array.from({ length: NODE_COUNT }, (_, i) => {
    const angle = (i / NODE_COUNT) * 2 * Math.PI - Math.PI / 2;
    const activation = activations[i] ?? 1.0;
    const r = RADIUS * (0.85 + 0.15 * Math.min(activation / 3, 1));
    return {
      x: CX + r * Math.cos(angle),
      y: CY + r * Math.sin(angle),
      activation,
      index: i,
    };
  });

  function activationColor(a: number): string {
    const norm = Math.min(Math.max((a - 1.0) / 3.0, 0), 1);
    if (norm < 0.33) {
      const t = norm / 0.33;
      const l = 0.35 + t * 0.2;
      const c = 0.15 + t * 0.13;
      return `oklch(${l} ${c} 280)`;
    }
    if (norm < 0.66) {
      const t = (norm - 0.33) / 0.33;
      const l = 0.55 + t * 0.15;
      return `oklch(${l} 0.28 290)`;
    }
    const t = (norm - 0.66) / 0.34;
    const l = 0.7 + t * 0.25;
    const c = 0.28 - t * 0.2;
    return `oklch(${l} ${c} 290)`;
  }

  const edges: {
    x1: number;
    y1: number;
    x2: number;
    y2: number;
    opacity: number;
    key: string;
  }[] = [];
  for (let i = 0; i < NODE_COUNT; i++) {
    for (let j = i + 1; j <= i + 6 && j < NODE_COUNT; j++) {
      const wStrength = (nodes[i].activation + nodes[j].activation) / 10;
      const opacity = Math.min(wStrength * 0.3, 0.25);
      if (opacity > 0.02) {
        edges.push({
          x1: nodes[i].x,
          y1: nodes[i].y,
          x2: nodes[j].x,
          y2: nodes[j].y,
          opacity,
          key: `e-${i}-${j}`,
        });
      }
    }
    if (coherence > 1.5) {
      const j = (i + Math.floor(NODE_COUNT / 2)) % NODE_COUNT;
      const opacity = Math.min((coherence - 1.5) * 0.04, 0.12);
      if (opacity > 0.01) {
        edges.push({
          x1: nodes[i].x,
          y1: nodes[i].y,
          x2: nodes[j].x,
          y2: nodes[j].y,
          opacity,
          key: `opp-${i}`,
        });
      }
    }
  }

  return (
    <svg
      width={WIDTH}
      height={HEIGHT}
      viewBox={`0 0 ${WIDTH} ${HEIGHT}`}
      className="w-full max-w-[480px]"
      style={{ filter: "drop-shadow(0 0 30px oklch(0.65 0.28 290 / 0.15))" }}
    >
      <title>Shell 3 neural substrate visualization</title>
      <defs>
        <radialGradient id="bg-grad" cx="50%" cy="50%" r="50%">
          <stop
            offset="0%"
            stopColor="oklch(0.12 0.05 290)"
            stopOpacity="0.3"
          />
          <stop offset="100%" stopColor="transparent" stopOpacity="0" />
        </radialGradient>
        <filter id="node-glow">
          <feGaussianBlur stdDeviation="2" result="blur" />
          <feMerge>
            <feMergeNode in="blur" />
            <feMergeNode in="SourceGraphic" />
          </feMerge>
        </filter>
      </defs>

      <circle
        cx={CX}
        cy={CY}
        r={RADIUS + 20}
        fill="url(#bg-grad)"
        className="animate-beat"
      />
      <circle
        cx={CX}
        cy={CY}
        r={RADIUS}
        fill="none"
        stroke="oklch(0.65 0.28 290 / 0.08)"
        strokeWidth="1"
      />
      <circle
        cx={CX}
        cy={CY}
        r={RADIUS * 0.6}
        fill="none"
        stroke="oklch(0.72 0.15 200 / 0.05)"
        strokeWidth="0.5"
        strokeDasharray="4 8"
      />

      {edges.map((e) => (
        <line
          key={e.key}
          x1={e.x1}
          y1={e.y1}
          x2={e.x2}
          y2={e.y2}
          stroke="oklch(0.65 0.28 290)"
          strokeWidth="0.5"
          strokeOpacity={e.opacity}
        />
      ))}

      {nodes.map((n) => (
        <g key={`n-${n.index}`} filter="url(#node-glow)">
          <circle
            cx={n.x}
            cy={n.y}
            r={2 + Math.min(n.activation / 4, 2)}
            fill={activationColor(n.activation)}
            opacity={0.7 + Math.min(n.activation / 10, 0.3)}
          />
        </g>
      ))}

      <circle
        cx={CX}
        cy={CY}
        r={6}
        fill="oklch(0.65 0.28 290)"
        opacity={0.8}
        filter="url(#node-glow)"
        className="animate-beat"
      />
      <circle
        cx={CX}
        cy={CY}
        r={12}
        fill="none"
        stroke="oklch(0.65 0.28 290)"
        strokeWidth="1"
        opacity={0.3}
        className="animate-beat"
      />
      <circle
        cx={CX}
        cy={CY}
        r={RADIUS * 0.35}
        fill="none"
        stroke="oklch(0.72 0.15 200)"
        strokeWidth="0.5"
        opacity={Math.min(coherence / 4, 0.4)}
        strokeDasharray={`${coherence * 10} ${100}`}
      />
    </svg>
  );
}
