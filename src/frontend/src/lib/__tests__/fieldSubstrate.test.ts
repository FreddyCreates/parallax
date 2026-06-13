import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
  computeOrderParameter,
  computePhaseLock,
  getCurrentBeat,
  getGlobalR,
  isBeating,
  isCoherentEnough,
  kuramotoStep,
  phiSpiralRadius,
  setGlobalR,
  startHeartbeat,
  stopHeartbeat,
  subscribe,
  subscriberCount,
} from "../../field-substrate";

describe("field-substrate heartbeat system", () => {
  beforeEach(() => {
    stopHeartbeat();
  });

  afterEach(() => {
    stopHeartbeat();
  });

  it("starts and stops heartbeat", () => {
    expect(isBeating()).toBe(false);
    startHeartbeat();
    expect(isBeating()).toBe(true);
    stopHeartbeat();
    expect(isBeating()).toBe(false);
  });

  it("does not create duplicate intervals", () => {
    startHeartbeat();
    startHeartbeat(); // second call is no-op
    expect(isBeating()).toBe(true);
    stopHeartbeat();
    expect(isBeating()).toBe(false);
  });

  it("stopHeartbeat is idempotent", () => {
    stopHeartbeat();
    stopHeartbeat(); // should not throw
    expect(isBeating()).toBe(false);
  });
});

describe("globalR management", () => {
  it("enforces S0 floor (0.75)", () => {
    setGlobalR(0.5);
    expect(getGlobalR()).toBe(0.75); // floored at S0
  });

  it("accepts values above S0", () => {
    setGlobalR(0.9);
    expect(getGlobalR()).toBe(0.9);
  });

  it("accepts 1.0 (max coherence)", () => {
    setGlobalR(1.0);
    expect(getGlobalR()).toBe(1.0);
  });
});

describe("subscriber management", () => {
  afterEach(() => {
    stopHeartbeat();
  });

  it("registers and unregisters subscribers", () => {
    const initial = subscriberCount();
    const unsubscribe = subscribe({
      id: "test-sub",
      fn: () => {},
      fieldType: 1,
    });
    expect(subscriberCount()).toBe(initial + 1);
    unsubscribe();
    expect(subscriberCount()).toBe(initial);
  });

  it("heartbeat fires subscribers in field type order", () => {
    vi.useFakeTimers();
    const order: string[] = [];

    subscribe({
      id: "type2-sub",
      fn: () => order.push("type2"),
      fieldType: 2,
    });
    subscribe({
      id: "type1-sub",
      fn: () => order.push("type1"),
      fieldType: 1,
    });
    subscribe({
      id: "type3-sub",
      fn: () => order.push("type3"),
      fieldType: 3,
    });

    startHeartbeat();
    vi.advanceTimersByTime(873); // one heartbeat

    // Order: Type 3 → Type 1 → Type 2
    expect(order).toEqual(["type3", "type1", "type2"]);

    stopHeartbeat();
    vi.useRealTimers();
  });

  it("PRIMA_CAUSA fires before all others", () => {
    vi.useFakeTimers();
    const order: string[] = [];

    subscribe({
      id: "type3-sub",
      fn: () => order.push("type3"),
      fieldType: 3,
    });
    subscribe({
      id: "PRIMA_CAUSA",
      fn: () => order.push("prima"),
      fieldType: 1,
    });
    subscribe({
      id: "type1-sub",
      fn: () => order.push("type1"),
      fieldType: 1,
    });

    startHeartbeat();
    vi.advanceTimersByTime(873);

    expect(order[0]).toBe("prima");
    expect(order[1]).toBe("type3");
    expect(order[2]).toBe("type1");

    stopHeartbeat();
    vi.useRealTimers();
  });

  it("beat increments with each tick", () => {
    vi.useFakeTimers();
    const initialBeat = getCurrentBeat();

    startHeartbeat();
    vi.advanceTimersByTime(873);
    expect(getCurrentBeat()).toBe(initialBeat + 1);

    vi.advanceTimersByTime(873);
    expect(getCurrentBeat()).toBe(initialBeat + 2);

    stopHeartbeat();
    vi.useRealTimers();
  });
});

describe("computePhaseLock", () => {
  it("returns 1 for identical phases", () => {
    expect(computePhaseLock(0, 0)).toBeCloseTo(1.0);
  });

  it("returns 0 for phases PI/2 apart", () => {
    expect(computePhaseLock(0, Math.PI / 2)).toBeCloseTo(0, 5);
  });
});

describe("isCoherentEnough", () => {
  it("returns true for identical phases", () => {
    expect(isCoherentEnough(0, 0)).toBe(true);
  });

  it("returns false for orthogonal phases", () => {
    expect(isCoherentEnough(0, Math.PI / 2)).toBe(false);
  });
});

describe("kuramotoStep", () => {
  it("advances phase by omega*dt when no neighbors", () => {
    const theta = 0;
    const omega = 1.0;
    const dt = 0.1;
    const result = kuramotoStep(theta, omega, 1.0, [], dt);
    expect(result).toBeCloseTo(omega * dt, 5);
  });

  it("pulls toward neighbor phase", () => {
    // theta=0, neighbor at PI/2, coupling should pull theta toward PI/2
    const theta = 0;
    const omega = 0; // no natural frequency
    const k = 1.0;
    const neighbors = [Math.PI / 2];
    const dt = 0.1;
    const result = kuramotoStep(theta, omega, k, neighbors, dt);
    // sin(PI/2 - 0) = 1, coupling = k/1 * 1 = 1, new theta = (0 + 1)*0.1 = 0.1
    expect(result).toBeCloseTo(0.1, 5);
  });

  it("coupling averages over multiple neighbors", () => {
    const theta = 0;
    const omega = 0;
    const k = 1.0;
    // Two neighbors at equal and opposite angles
    const neighbors = [Math.PI / 4, -Math.PI / 4];
    const dt = 0.1;
    const result = kuramotoStep(theta, omega, k, neighbors, dt);
    // sin(PI/4) + sin(-PI/4) = 0, so coupling is 0
    expect(result).toBeCloseTo(0, 5);
  });
});

describe("computeOrderParameter", () => {
  it("returns S0 for empty array", () => {
    expect(computeOrderParameter([])).toBe(0.75);
  });

  it("returns 1 for all-identical phases (floored at max(1, S0) = 1)", () => {
    const result = computeOrderParameter([0, 0, 0, 0]);
    expect(result).toBeCloseTo(1.0, 5);
  });

  it("returns S0 floor for uniformly distributed phases", () => {
    // Phases uniformly distributed → R ≈ 0, floored to S0 = 0.75
    const N = 100;
    const phases = Array.from({ length: N }, (_, i) => (2 * Math.PI * i) / N);
    expect(computeOrderParameter(phases)).toBe(0.75);
  });

  it("returns value between S0 and 1 for partially coherent phases", () => {
    // Some coherence
    const phases = [0, 0.1, 0.2, 0.3, 0.4];
    const result = computeOrderParameter(phases);
    expect(result).toBeGreaterThanOrEqual(0.75);
    expect(result).toBeLessThanOrEqual(1.0);
  });
});

describe("phiSpiralRadius", () => {
  it("returns 1 for depth 0", () => {
    expect(phiSpiralRadius(0)).toBeCloseTo(1.0);
  });

  it("grows with depth", () => {
    expect(phiSpiralRadius(5)).toBeGreaterThan(phiSpiralRadius(2));
  });
});
