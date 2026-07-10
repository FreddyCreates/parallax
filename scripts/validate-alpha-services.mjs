#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const manifestPath = path.join(root, 'config/services/parallax.alpha.services.json');
const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));

const errors = [];
const requiredTopLevel = ['schema', 'platform', 'mode', 'public_posture', 'service_planes', 'services', 'alpha_gates'];
for (const key of requiredTopLevel) {
  if (!(key in manifest)) errors.push(`missing top-level key: ${key}`);
}

if (manifest.schema !== 'parallax.alpha.services.v1') errors.push('schema must be parallax.alpha.services.v1');
if (manifest.platform !== 'PARALLAX') errors.push('platform must be PARALLAX');
if (manifest.mode !== 'alpha') errors.push('mode must be alpha');
if (manifest.public_posture !== 'paper_testnet_first') errors.push('public_posture must be paper_testnet_first');

const serviceIds = new Set();
const requiredServiceKeys = [
  'id',
  'name',
  'plane',
  'status',
  'owner',
  'purpose',
  'alpha_capabilities',
  'contracts',
  'dependencies',
  'exposes',
  'must_not_do',
];

if (!Array.isArray(manifest.services) || manifest.services.length < 10) {
  errors.push('services must contain at least 10 alpha services');
}

for (const service of manifest.services ?? []) {
  for (const key of requiredServiceKeys) {
    if (!(key in service)) errors.push(`${service.id ?? 'unknown'} missing key: ${key}`);
  }
  if (serviceIds.has(service.id)) errors.push(`duplicate service id: ${service.id}`);
  serviceIds.add(service.id);

  if (!manifest.service_planes.includes(service.plane)) {
    errors.push(`${service.id} plane is not listed in service_planes`);
  }
  if (!['alpha_required', 'alpha_optional', 'planned'].includes(service.status)) {
    errors.push(`${service.id} has invalid status ${service.status}`);
  }
  for (const field of ['alpha_capabilities', 'contracts', 'dependencies', 'exposes', 'must_not_do']) {
    if (!Array.isArray(service[field])) errors.push(`${service.id} ${field} must be an array`);
  }
  if ((service.alpha_capabilities ?? []).length === 0) errors.push(`${service.id} needs at least one alpha capability`);
  if ((service.contracts ?? []).length === 0) errors.push(`${service.id} needs at least one contract`);
  if ((service.exposes ?? []).length === 0) errors.push(`${service.id} needs at least one exposed route or method`);
  if ((service.must_not_do ?? []).length === 0) errors.push(`${service.id} needs at least one alpha boundary`);
}

for (const service of manifest.services ?? []) {
  for (const dependency of service.dependencies ?? []) {
    if (!serviceIds.has(dependency)) errors.push(`${service.id} depends on missing service ${dependency}`);
  }
}

const requiredGates = [
  'no_live_money_movement',
  'no_live_broker_routing',
  'all_commands_pass_risk_policy_gate',
  'all_state_transitions_emit_receipts',
  'operator_halt_available',
  'testnet_and_live_modes_separated',
  'public_claims_match_evidence',
  'receipt_export_available',
  'service_health_visible',
];
for (const gate of requiredGates) {
  if (!manifest.alpha_gates.includes(gate)) errors.push(`missing alpha gate: ${gate}`);
}

if (errors.length > 0) {
  console.error('PARALLAX alpha service validation failed:');
  for (const error of errors) console.error(`- ${error}`);
  process.exit(1);
}

const required = manifest.services.filter((service) => service.status === 'alpha_required').length;
const optional = manifest.services.filter((service) => service.status === 'alpha_optional').length;
console.log(`PARALLAX alpha service manifest valid: ${manifest.services.length} services (${required} required, ${optional} optional), ${manifest.alpha_gates.length} alpha gates.`);
