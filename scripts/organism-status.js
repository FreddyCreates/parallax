#!/usr/bin/env node

/**
 * organism-status.js
 * 
 * PARALLAX Sovereign Organism Health Monitor
 * Validates: heartbeat pulse, domain activations, law enforcement
 * Cross-platform compatible (Windows, macOS, Linux)
 * 
 * Usage:
 *   node scripts/organism-status.js
 *   node scripts/organism-status.js --json
 *   node scripts/organism-status.js --heartbeat-only
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ═══════════════════════════════════════════════════════════════════════
// CROSS-PLATFORM PATH RESOLUTION
// ═══════════════════════════════════════════════════════════════════════

const projectRoot = path.resolve(__dirname, '..');
const backendDir = path.resolve(projectRoot, 'src', 'backend');
const mainMoPath = path.resolve(backendDir, 'main.mo');

// ─────────────────────────────────────────────────────────────────────
// CONSTANTS: Golden Ratios and Timings
// ─────────────────────────────────────────────────────────────────────

const PHI = 1.618033988749895;            // Golden ratio
const PHI_INVERSE = 1 / PHI;              // ~0.618033988749895
const HEARTBEAT_MS = 873;                 // 873ms heartbeat (φ⁴ × 1000ms / 7.83Hz)
const COHERENCE_THRESHOLD = 0.618;        // Kuramoto coherence gate (φ⁻¹)

// ─────────────────────────────────────────────────────────────────────
// DOMAIN REGISTRY (25+ domains in SovereignState)
// ─────────────────────────────────────────────────────────────────────

const DOMAINS = {
  0: 'CORE_COORDINATION',
  1: 'SOVEREIGN_DB',
  2: 'GENESIS_ACTIVATION',
  3: 'SCHOOL_REGISTRY',
  4: 'NODUS_COMPOUND',
  5: 'AEGIS_SECURITY',
  6: 'AGI_SCRIPTS',
  7: 'ARTIFACT_FEEDBACK',
  8: 'BEAT_TIME',
  9: 'BIRTH_AI',
  10: 'BUILDER_SDK',
  11: 'CANISTER_REGISTRY',
  12: 'CHARTER',
  13: 'COGNITION_LAYER',
  14: 'DEEP_CRYPTO',
  15: 'DOGON_SUBSTRATE',
  16: 'AI_ENGINES',
  17: 'INTELLIGENCE_ROUTING',
  18: 'ARTIFACT_REGISTRY',
  19: 'PHANTOM_INTELLIGENCE',
  20: 'PHANTOM_EXCHANGE',
  21: 'PHANTOM_CLEARINGHOUSE',
  22: 'PRODUCTION_ENGINES',
  23: 'INTELLIGENCE_CONTRACTS',
  24: 'TOKENOMICS_MEASUREMENT',
  25: 'MODEL_REGISTRY',
  26: 'CONTEXT_ROUTER',
  27: 'NOVA_RUNTIME',
  28: 'AI_NODE',
};

// ─────────────────────────────────────────────────────────────────────
// HEALTH METRICS STRUCTURE
// ─────────────────────────────────────────────────────────────────────

class OrganismStatus {
  constructor() {
    this.timestamp = new Date().toISOString();
    this.status = '🔴 INITIALIZING';
    this.health = 0;
    this.heartbeat = {
      interval_ms: HEARTBEAT_MS,
      phi_coefficient: PHI,
      phi_inverse: PHI_INVERSE,
      coherence_threshold: COHERENCE_THRESHOLD,
    };
    this.domains = {};
    this.laws = [];
    this.errors = [];
  }

  toJSON() {
    return {
      timestamp: this.timestamp,
      status: this.status,
      health_percentage: this.health,
      heartbeat: this.heartbeat,
      domains: this.domains,
      laws: this.laws,
      errors: this.errors,
    };
  }

  report(format = 'human') {
    if (format === 'json') {
      return JSON.stringify(this.toJSON(), null, 2);
    }

    const lines = [];
    lines.push('');
    lines.push('╔═══════════════════════════════════════════════════════════════╗');
    lines.push('║         PARALLAX ORGANISM STATUS MONITOR                      ║');
    lines.push('╚═══════════════════════════════════════════════════════════════╝');
    lines.push('');
    lines.push(`📡 Status:           ${this.status}`);
    lines.push(`❤️  Health:            ${this.health}%`);
    lines.push(`⏱️  Heartbeat:         ${this.heartbeat.interval_ms}ms (φ⁴ derived)`);
    lines.push(`🔗 Coherence Gate:   φ⁻¹ = ${this.heartbeat.coherence_threshold}`);
    lines.push('');
    lines.push('DOMAINS INITIALIZED:');
    let activeCount = 0;
    for (const [id, name] of Object.entries(DOMAINS)) {
      const status = this.domains[id] || '❌';
      if (status === '✅') activeCount++;
      lines.push(`  [${String(id).padStart(2, ' ')}] ${status} ${name}`);
    }
    lines.push('');
    lines.push(`🧠 Active Domains: ${activeCount}/${Object.keys(DOMAINS).length}`);
    lines.push('');

    if (this.laws.length > 0) {
      lines.push('LAWS DETECTED:');
      this.laws.forEach((law, i) => {
        lines.push(`  ${i + 1}. ${law}`);
      });
      lines.push('');
    }

    if (this.errors.length > 0) {
      lines.push('⚠️  ERRORS:');
      this.errors.forEach((err) => {
        lines.push(`  ✗ ${err}`);
      });
      lines.push('');
    }

    return lines.join('\n');
  }
}

// ─────────────────────────────────────────────────────────────────────
// ANALYSIS FUNCTIONS
// ─────────────────────────────────────────────────────────────────────

function analyzeMainMo() {
  const status = new OrganismStatus();

  try {
    if (!fs.existsSync(mainMoPath)) {
      status.errors.push(`main.mo not found at: ${mainMoPath}`);
      status.status = '🔴 OFFLINE';
      return status;
    }

    const content = fs.readFileSync(mainMoPath, 'utf-8');

    // ─ Check heartbeat timer initialization ─
    if (content.includes('873') || content.includes('HEARTBEAT')) {
      status.heartbeat.detected = true;
      status.laws.push('FL-001: 873ms Heartbeat Cycle');
    } else {
      status.errors.push('Heartbeat timer (873ms) not detected');
    }

    // ─ Check φ (golden ratio) constants ─
    if (content.includes('1.618') || content.includes('phi') || content.includes('φ')) {
      status.laws.push('FL-002: φ Ratio Encoding');
    }

    // ─ Check domain initializations ─
    const domainPatterns = [
      { id: 1, pattern: /SovereignDB|sovereign_db/ },
      { id: 2, pattern: /GenesisAct|genesis/ },
      { id: 3, pattern: /SchoolReg|school/ },
      { id: 4, pattern: /Nodus|nodus/ },
      { id: 5, pattern: /Aegis|aegis/ },
      { id: 6, pattern: /AgiScripts|agi/ },
      { id: 7, pattern: /ArtifactFeedback|artifact_feedback/ },
      { id: 8, pattern: /BeatTime|beat_time/ },
      { id: 19, pattern: /PhantomIntel|phantom_intelligence/ },
      { id: 20, pattern: /PhantomExchange|phantom_exchange/ },
      { id: 24, pattern: /TokenomicsMeasurement|tokenomics_measurement/ },
    ];

    domainPatterns.forEach((d) => {
      if (d.pattern.test(content)) {
        status.domains[d.id] = '✅';
      }
    });

    // ─ Check law gates (FORBID, REQUIRE, ESCALATE) ─
    const lawGates = {
      FORBID: (content.match(/FORBID/g) || []).length,
      REQUIRE: (content.match(/REQUIRE/g) || []).length,
      ESCALATE: (content.match(/ESCALATE/g) || []).length,
    };

    if (lawGates.FORBID > 0 || lawGates.REQUIRE > 0 || lawGates.ESCALATE > 0) {
      status.laws.push(`FL-003: Law Gates (${lawGates.FORBID} FORBID, ${lawGates.REQUIRE} REQUIRE, ${lawGates.ESCALATE} ESCALATE)`);
    }

    // ─ Calculate health percentage ─
    const activeDomains = Object.values(status.domains).filter((d) => d === '✅').length;
    const totalDomains = Object.keys(DOMAINS).length;
    status.health = Math.floor((activeDomains / totalDomains) * 100);

    // ─ Determine overall status ─
    if (status.health >= 80) {
      status.status = '🟢 HEALTHY';
    } else if (status.health >= 50) {
      status.status = '🟡 DEGRADED';
    } else {
      status.status = '🔴 CRITICAL';
    }
  } catch (err) {
    status.errors.push(`Analysis failed: ${err.message}`);
    status.status = '🔴 ERROR';
  }

  return status;
}

// ─────────────────────────────────────────────────────────────────────
// CLI MAIN
// ─────────────────────────────────────────────────────────────────────

function main() {
  const args = process.argv.slice(2);
  const format = args.includes('--json') ? 'json' : 'human';

  const status = analyzeMainMo();
  console.log(status.report(format));

  // Exit with error code if not healthy
  if (status.health < 80) {
    process.exit(1);
  }
}

main();
