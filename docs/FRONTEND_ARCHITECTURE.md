<div align="center">

# 🖥️ PARALLAX Frontend Architecture

### Deep Technical Reference — React 19 + TypeScript + ICP Integration

**Version:** 1.0.0 | **Framework:** React 19.1 | **Build:** Vite 5.4 | **Lines:** ~8,000 TypeScript

---

</div>

## 1. Overview

The PARALLAX frontend is a sovereign intelligence dashboard built with React 19, TypeScript, and Tailwind CSS. It communicates with the Motoko backend via ICP Candid RPC, rendering 22 domain-specific tabs that visualize the organism's real-time cognitive, financial, and governance state.

### Core Statistics

| Metric | Value |
|--------|-------|
| Framework | React 19.1.0 |
| Language | TypeScript 5.8.3 |
| Build Tool | Vite 5.4.1 |
| Styling | Tailwind CSS 3.4.17 |
| State Management | React Query 5.24 + Zustand 5.0.5 |
| UI Components | Radix-UI (35+ packages) |
| 3D Graphics | Three.js + React Three Fiber 9.1 |
| Animation | Motion 12.34.3 |
| Auth | Internet Identity (ICP) |
| Testing | Vitest 2.1.9 |
| Linting | Biome 1.9 |
| Color Model | OKLCH (perceptually uniform) |

---

## 2. Application Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                         APPLICATION LAYER                             │
│                                                                      │
│  ┌────────────┐    ┌─────────────┐    ┌──────────────────────────┐  │
│  │   App.tsx  │───▶│  Auth Gate  │───▶│     Tab Router           │  │
│  │ (orchestr) │    │ (II login)  │    │  (22 domain tabs)        │  │
│  └────────────┘    └─────────────┘    └──────────────────────────┘  │
│                                                                      │
├──────────────────────────────────────────────────────────────────────┤
│                          HOOKS LAYER                                  │
│                                                                      │
│  useParallax() │ useChat() │ useWallet() │ useForma() │ useBank()   │
│  useSchumannState() │ useAgiStatus() │ useIntelligenceEngine()      │
│                                                                      │
├──────────────────────────────────────────────────────────────────────┤
│                        DATA/STATE LAYER                               │
│                                                                      │
│  ┌─────────────────┐  ┌──────────────┐  ┌───────────────────────┐  │
│  │  React Query    │  │   Zustand    │  │  Local useState       │  │
│  │ (server state)  │  │ (global UI)  │  │ (component state)     │  │
│  │ polling 3-30s   │  │ (minimal)    │  │ (tabs, modals, etc)   │  │
│  └────────┬────────┘  └──────────────┘  └───────────────────────┘  │
│           │                                                          │
├───────────┼──────────────────────────────────────────────────────────┤
│           │            TRANSPORT LAYER                                │
│           ▼                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │              ICP Actor (Candid RPC)                              ││
│  │  @dfinity/agent → @dfinity/candid → Backend Canister            ││
│  │  Signed with Internet Identity delegation                        ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 3. Entry Points

### `main.tsx` — Application Bootstrap
```typescript
// React 19 createRoot
// Internet Identity Provider wrap
// React Query Provider
// Theme Provider (dark mode default)
// App component mount
```

### `App.tsx` — Master Orchestrator

**Responsibilities:**
1. Authentication gate (Internet Identity)
2. Landing page → Main app transition
3. Tab state management (22 tabs)
4. Global data polling (3s heartbeat, 5s AGI, 10s withdrawals, 30s memoria)
5. Creator principal registration (one-time)
6. Loading/error state management

**State Shape:**
```typescript
const [activeTab, setActiveTab] = useState<TabId>("substrate");
const [showLanding, setShowLanding] = useState(true);
const [shell3State, setShell3State] = useState<Shell3State | null>(null);
const [loading, setLoading] = useState(true);
```

**Polling Architecture:**
```typescript
// Parallel data fetching every interval:
useEffect(() => {
  const interval = setInterval(async () => {
    const [s3, fs, qs, bs, al] = await Promise.all([
      actor.getShell3State(),      // 3000ms
      actor.getFullState(),        // 3000ms
      actor.getSchumannState(),    // 3000ms
      actor.getBrainSignals(),     // 5000ms
      actor.getWithdrawalLog(),    // 10000ms
    ]);
    // Update state...
  }, 3000);
  return () => clearInterval(interval);
}, [actor]);
```

---

## 4. Authentication Flow

### Internet Identity Integration

```
┌──────────────┐     ┌──────────────────┐     ┌────────────────┐
│   Frontend   │────▶│ Internet Identity │────▶│  ICP Backend   │
│  (React)     │     │   (Passkey/Bio)   │     │  (Canister)    │
└──────────────┘     └──────────────────┘     └────────────────┘
       │                      │                        │
       │  1. login()          │                        │
       │─────────────────────▶│                        │
       │                      │  2. Prove identity     │
       │                      │  (YubiKey/passkey)     │
       │  3. Delegation       │                        │
       │◀─────────────────────│                        │
       │                      │                        │
       │  4. Create Actor with signed identity         │
       │──────────────────────────────────────────────▶│
       │                      │                        │
       │  5. setCreatorPrincipal() (one-time)          │
       │──────────────────────────────────────────────▶│
```

**Security Invariants:**
- Private keys NEVER sent to browser
- All cryptography delegated to II/backend
- Actor calls signed client-side by auth-client
- Anonymous principals rejected at gate
- Creator principal set once, verified on every privileged operation

---

## 5. Tab Architecture (22 Domains)

Each tab represents a view into a specific organism domain:

| Tab | Component | Hook | Backend Query | Purpose |
|-----|-----------|------|---------------|---------|
| Substrate | SubstrateTab | useParallax, useSchumannState | getSchumannState, getFullState | Schumann coupling, phase visualization |
| Forma | FormaTab | useForma, useIntelligenceEngine | getFormaState, getJacobsLadder | Phi compounding, capital growth |
| Treasury | TreasuryTab | useParallax | getTreasuryState | Balances, reserves, profit streams |
| Wallet | ThesaurusParallaxiTab | useWallet | getTokenBalances | 26 tokens, law registry |
| Bank | BankTab | useBank | getBankingState | Accounts, KYC, transactions |
| Chat | ChatPanel | useChat, useGraph | getMessages, getGraph | Sessions, knowledge graph |
| Quantum | QuantumTab | useIntelligenceEngine | getQuantumState | Oscillator math, coherence |
| Admin | AdminTab | useActor | (direct mutations) | Genesis, context router wiring |
| Exchange | ExchangeTab | useExchange | getExchangeState | Order book, trading |
| Clearinghouse | ClearinghouseTab | useClearinghouse | getClearinghouseState | Settlement, netting |
| Intelligence | IntelligenceTab | useIntelligence | getIntelligenceState | AI reasoning activity |
| Production | ProductionTab | useEngines | getEngineStatus | 24 engine monitoring |
| Governance | GovernanceTab | useCharter | getCharterState | Proposals, voting |
| Defense | DefenseTab | useDefense | getDefenseState | ARES alerts, security |
| Memory | MemoryTab | useMemory | getKnowledgeBase | Knowledge base, embeddings |
| Signals | SignalsTab | useSignals | getSignalState | 128 sensory slot monitoring |
| Drives | DrivesTab | useDrives | getDrivesState | 7 emotional drive dashboard |
| Neuro | NeuroTab | useNeuro | getNeurochemState | 21 neurochemical levels |
| Franchise | FranchiseTab | useFranchise | getFranchiseState | Child organism health |
| Protocol | ProtocolTab | useProtocol | getProtocolState | 89+ protocol gates |
| Proof | ProofTab | useProof | getProofChain | Hash chain visualization |
| Nova | NovaTab | useNova | getNovaState | 40 cognitive engine status |

---

## 6. State Management Patterns

### React Query (Primary — Server State)

```typescript
// Query pattern (read)
const { data, isLoading, error } = useQuery({
  queryKey: ["schumannState"],
  queryFn: async () => actor.getSchumannState(),
  enabled: !!actor,
  staleTime: 5000,          // Cache valid for 5s
  refetchInterval: 3000,    // Poll every 3s
});

// Mutation pattern (write)
const { mutate } = useMutation({
  mutationFn: async (payload) => actor.placeOrder(payload),
  onSuccess: () => {
    queryClient.invalidateQueries({ queryKey: ["exchangeState"] });
    toast.success("Order placed");
  },
  onError: () => toast.error("Order failed"),
});
```

**Benefits:**
- Automatic request deduplication
- Stale-while-revalidate caching
- Background refetching
- Built-in retry (3× exponential backoff)
- Optimistic updates where applicable

### Zustand (Minimal — Global UI State)

```typescript
const useAppStore = create((set) => ({
  theme: "dark",
  sidebarOpen: false,
  setTheme: (theme) => set({ theme }),
  toggleSidebar: () => set((s) => ({ sidebarOpen: !s.sidebarOpen })),
}));
```

Used sparingly — React Query handles 90% of state.

### Local useState (Component State)

```typescript
// Tab selection, modal open/close, form values, hover/focus
const [activeTab, setActiveTab] = useState<TabId>("substrate");
const [modalOpen, setModalOpen] = useState(false);
const [inputValue, setInputValue] = useState("");
```

---

## 7. Backend Communication (ICP Actor)

### Actor Creation

```typescript
import { createActor } from "../declarations/backend";
import { HttpAgent } from "@dfinity/agent";

const agent = new HttpAgent({
  identity: authClient.getIdentity(),
  host: DFX_NETWORK === "ic"
    ? "https://icp-api.io"
    : "http://127.0.0.1:4943",
});

const actor = createActor(canisterId, { agent });
```

### Type Generation Pipeline

```
Motoko source (.mo)
    ↓  (mops build)
Candid IDL (.did)
    ↓  (pnpm bindgen)
TypeScript declarations (.d.ts + .js)
    ↓  (import in hooks)
Typed actor methods
```

**Example Type Mapping:**
```
Motoko:     public func getSchumannState() : async SchumannState
Candid:     (func () → (record { ... }) query)
TypeScript: async getSchumannState(): Promise<SchumannState>
```

### Key Backend Types (Frontend View)

```typescript
interface SchumannState {
  fundamentalHz: number;       // 7.83
  harmonics: number[];         // [14.3, 20.8, 27.3, 33.8]
  schumannPhase: number;       // Current phase angle
  silverAnchorHz: number;      // 2.75
  silverAnchorPhase: number;
  couplingStrength: number;
  kuramotoR: number;           // Collective order parameter [0, 1]
}

interface MedinaTimestamp4D {
  beat: number;               // Cardiac beat count
  proofDepth: number;         // Proof chain depth
  phiPower: number;           // φ^proofDepth
  unixMs: number;             // Earth time
}

interface MedinaCoordinate4D {
  x: number; y: number; z: number;
  tau: number;                // τ = beat × φ^depth
}

interface ProfitStreams {
  s1: number; s2: number; /* ... */ s22: number;
  total: number;
}
```

---

## 8. Libraries & Utilities

### `lib/intelligenceEngine.ts` — Math Engine

Pure TypeScript implementation of trading mathematics:
- Kuramoto order parameter calculation
- Coupled oscillator simulation
- Phase coherence measurement
- Harmonic wave analysis
- Golden ratio calculations
- Fibonacci sequence generation

### `lib/phi.ts` — Frontend Phi Library (~29,944 lines)

Complete phi/golden ratio mathematics for frontend use:
- All constants mirrored from backend `phi.mo`
- Fibonacci lookup tables
- Phi-power calculations
- Schumann harmonic computations

### `lib/memoryExtractor.ts` — Memory Processing

Extracts knowledge entities from natural language for the knowledge graph.

### `lib/fieldSubstrate.ts` — Field Operations

Field tensor computations for substrate visualization.

### `lib/aiSimulator.ts` — AI Simulation

Client-side AI simulation for offline/preview modes.

### `utils/extraction.ts` — Entity Extraction

```typescript
interface ExtractedEntity {
  label: string;
  type: NodeType;  // memory | concept | entity
}

function extractEntities(text: string): ExtractedEntity[]
// Pattern matching for beliefs, intentions, concepts
// Returns max 6 entities per extraction
```

### `utils/formatting.ts` — Display Formatting

```typescript
formatRelativeTime(nanoseconds: bigint): string  // "5 min ago"
formatTime(nanoseconds: bigint): string           // "14:32"
truncate(str: string, max: number): string        // "Lorem ip..."
```

Converts ICP nanosecond timestamps to human-readable formats.

---

## 9. Visualization Systems

### Schumann Phase Visualization

```typescript
// No interpolation — position IS the phase
const phaseRad = schumannState?.schumannPhase ?? 0;
const x = Math.cos(phaseRad) * radius;
const y = Math.sin(phaseRad) * radius;
// Render dot at exact angular position on circle
```

### Knowledge Graph (D3/Canvas)

```typescript
enum NodeType { memory, concept, entity }
enum RelationshipType { related, strengthens, contradicts }

// Interactive force-directed graph
// Draggable nodes, labeled edges
// Color-coded by type
// Salience scores on relationships
```

### 3D Visualization (Three.js)

```typescript
// React Three Fiber for WebGL rendering
// @react-three/cannon for physics simulation
// Organism geometry visualization
// Shell layer rendering (11 Fibonacci-proximate shells)
```

### Charts (Recharts)

```typescript
// Profit stream time series
// Neurochemical level bars
// Engine firing frequency graphs
// Token balance distribution
```

---

## 10. Styling Architecture

### Tailwind CSS Configuration

```javascript
// tailwind.config.js
module.exports = {
  content: ["index.html", "src/**/*.{js,ts,jsx,tsx,html,css}"],
  theme: {
    extend: {
      // OKLCH color variables
      colors: {
        primary: "oklch(var(--primary))",
        secondary: "oklch(var(--secondary))",
        accent: "oklch(var(--accent))",
        // ... sovereign palette
      },
      // Phi-derived spacing
      spacing: {
        'phi': '1.618rem',
        'phi-2': '2.618rem',
        'phi-3': '4.236rem',
      },
      // Custom animations
      animation: {
        'beat-pulse': 'beat-pulse 2s ease-in-out infinite',
        'pulse-glow': 'pulse-glow 2s ease-in-out infinite',
        'sovereign-pulse': 'sovereign-pulse 3s ease-in-out infinite',
        'rotate-slow': 'rotate-slow 20s linear infinite',
      },
    },
  },
  plugins: [
    require("@tailwindcss/typography"),
    require("@tailwindcss/container-queries"),
    require("tailwindcss-animate"),
  ],
};
```

### OKLCH Color Model

All colors defined in OKLCH (Lightness, Chroma, Hue) for perceptual uniformity:

```css
:root {
  --primary: 0.78 0.15 85;        /* Gold */
  --secondary: 0.65 0.12 260;     /* Royal blue */
  --accent: 0.72 0.18 145;        /* Emerald */
  --background: 0.12 0.01 260;    /* Deep space */
  --surface: 0.18 0.02 260;       /* Card surface */
  --text: 0.95 0.01 85;           /* Light text */
  --muted: 0.55 0.02 260;         /* Muted text */
}
```

**Why OKLCH?** Same chroma appears equally saturated across all hues. Better accessibility and visual consistency than RGB/HSL.

### Custom Animations

```css
@keyframes beat-pulse    { /* 2s heartbeat scale + opacity */ }
@keyframes pulse-glow    { /* 2s box-shadow glow in/out */ }
@keyframes sovereign-pulse { /* 3s scale + opacity */ }
@keyframes threat-flash  { /* 1.2s border color flash */ }
@keyframes rotate-slow   { /* 20s full rotation */ }
@keyframes shimmer       { /* 1.5s skeleton loader */ }
```

### Design Language

- **Glassmorphism** — Frosted glass cards with backdrop-blur
- **Dark-first** — Deep space backgrounds (OKLCH L: 0.12)
- **Gold accents** — Sovereign/phi-related elements
- **Pulse animations** — Heartbeat-synchronized UI elements
- **Scientific precision** — Data displayed in scientific notation where appropriate

---

## 11. Error Handling

### Graceful Degradation

```typescript
// Pattern: try-catch with silent fallback
try {
  const [s3, fs, qs, bs, al] = await Promise.all([...]);
  // Process results
} catch {
  setLoading(false);  // Keep old state, stop loading indicator
}

// Pattern: optional chaining + nullish coalescing
const coherence = schumannState?.kuramotoR ?? 0;
const phase = schumannState?.schumannPhase ?? 0;
```

### Toast Notifications (Sonner)

```typescript
// Success/error feedback for mutations
try {
  await actor.wireContextRouter(value);
  toast.success("CONTEXT ROUTER WIRED");
} catch {
  toast.error("FAILED TO WIRE CONTEXT ROUTER");
}
```

### React Query Retries
- Default: 3 retries with exponential backoff
- Per-query customizable
- Automatic error state propagation

---

## 12. Performance Optimizations

| Technique | Implementation | Benefit |
|-----------|---------------|---------|
| Request Dedup | React Query same-key merging | Single network request per unique query |
| Stale-While-Revalidate | staleTime: 5000ms | Instant UI, background refresh |
| Code Splitting | Tab-level lazy loading | Only load active tab code |
| CSS Tree-Shaking | Tailwind purge | Only used classes bundled |
| Dependency Dedup | Vite optimizeDeps | Single @dfinity/agent instance |
| Efficient Polling | refetchInterval per-priority | Critical: 3s, Normal: 10s, Low: 30s |
| Canvas Rendering | Three.js for complex viz | GPU-accelerated 3D |
| Memo/Callback | React.memo on expensive components | Prevent unnecessary re-renders |

---

## 13. Testing Infrastructure

### Vitest Configuration

```typescript
// vitest.config.ts
export default defineConfig({
  test: {
    environment: "jsdom",
    globals: true,
    setupFiles: ["./src/test-setup.ts"],
  },
});
```

### Test Files

```
src/utils/__tests__/
├── formatting.test.ts       — Time formatting, truncation
└── extraction.test.ts       — Entity extraction patterns

src/lib/__tests__/
├── intelligenceEngine.test.ts — Kuramoto, oscillators, coherence
├── phi.test.ts              — Golden ratio calculations
├── memoryExtractor.test.ts  — Memory entity extraction
├── fieldSubstrate.test.ts   — Field tensor operations
└── models.test.ts           — Data model validation
```

### Commands

```bash
pnpm test          # Run once
pnpm test:watch    # Watch mode
pnpm typecheck     # TypeScript validation (tsc --noEmit)
pnpm check         # Biome lint check
pnpm fix           # Biome auto-fix
```

---

## 14. Build & Deployment

### Build Process

```bash
pnpm build
  → vite build
    → TypeScript → JavaScript (ES2020 target)
    → Tailwind CSS generation (purged)
    → Tree-shaking & bundling
    → Output to dist/
  → pnpm copy:env
    → Copy env.json to dist/
  → Ready for ICP deployment
```

### Output Structure

```
dist/
├── index.html              (SPA entry point)
├── assets/
│   ├── index-[hash].js     (application code)
│   ├── vendor-[hash].js    (dependencies)
│   └── index-[hash].css    (Tailwind + custom CSS)
├── env.json                (environment config)
└── fonts/                  (WOFF2 web fonts)
```

### Environment Configuration

```javascript
// vite.config.js environment injection
DFX_NETWORK: "local" | "staging" | "ic"

// Derived URLs:
II_URL:
  local → "http://rdmx6-jaaaa-aaaaa-aaadq-cai.localhost:8081/"
  ic    → "https://identity.internetcomputer.org/"

STORAGE_GATEWAY_URL: "https://blob.caffeine.ai"

// Dev server proxy:
"/api" → "http://127.0.0.1:4943"  (local dfx canister)
```

### Path Aliases

```json
{
  "@/*": "./src/*",
  "declarations/*": "./src/declarations/*"
}
```

---

## 15. Component Library (Radix-UI)

35+ Radix-UI packages providing accessible, headless primitives:

| Component | Package | Usage |
|-----------|---------|-------|
| Dialog | @radix-ui/react-dialog | Modals, confirmations |
| Dropdown | @radix-ui/react-dropdown-menu | Action menus |
| Tabs | @radix-ui/react-tabs | Tab navigation |
| Tooltip | @radix-ui/react-tooltip | Info tooltips |
| Accordion | @radix-ui/react-accordion | Collapsible sections |
| Select | @radix-ui/react-select | Dropdowns |
| Slider | @radix-ui/react-slider | Range inputs |
| Switch | @radix-ui/react-switch | Toggle controls |
| Progress | @radix-ui/react-progress | Loading bars |
| Avatar | @radix-ui/react-avatar | User avatars |
| Scroll Area | @radix-ui/react-scroll-area | Custom scrollbars |
| Separator | @radix-ui/react-separator | Visual dividers |
| Popover | @radix-ui/react-popover | Floating panels |
| Toast | @radix-ui/react-toast | Notifications |
| Toggle | @radix-ui/react-toggle | Binary switches |
| Checkbox | @radix-ui/react-checkbox | Checkboxes |
| Radio | @radix-ui/react-radio-group | Radio buttons |
| Label | @radix-ui/react-label | Form labels |
| Collapsible | @radix-ui/react-collapsible | Expand/collapse |
| Navigation | @radix-ui/react-navigation-menu | Nav menus |
| Hover Card | @radix-ui/react-hover-card | Hover previews |
| Context Menu | @radix-ui/react-context-menu | Right-click menus |
| Alert Dialog | @radix-ui/react-alert-dialog | Destructive confirmations |
| Aspect Ratio | @radix-ui/react-aspect-ratio | Fixed ratios |

**Styling Pattern:** Radix provides behavior/accessibility; Tailwind provides visual styling. No CSS-in-JS.

---

## 16. Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                          USER INTERACTION                             │
│                                                                     │
│  Click Tab │ Send Message │ Place Order │ Toggle Setting │ Auth     │
└──────────┬──────────┬──────────┬──────────┬──────────┬─────────────┘
           │          │          │          │          │
           ▼          ▼          ▼          ▼          ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         REACT COMPONENTS                             │
│                                                                     │
│  SubstrateTab │ ChatPanel │ ExchangeTab │ AdminTab │ LandingPage   │
└──────────┬──────────┬──────────┬──────────┬──────────┬─────────────┘
           │          │          │          │          │
           ▼          ▼          ▼          ▼          ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         CUSTOM HOOKS                                  │
│                                                                     │
│  useQuery │ useMutation │ useIntelligenceEngine │ useInternetId     │
└──────────┬──────────┬──────────────────────────────────────────────┘
           │          │
     (read)│          │(write)
           ▼          ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      ICP ACTOR (Candid RPC)                          │
│                                                                     │
│  actor.getSchumannState()  │  actor.sendMessage()                   │
│  actor.getFullState()      │  actor.placeOrder()                    │
│  actor.getTreasuryState()  │  actor.wireContextRouter()             │
└──────────┬──────────┬──────────────────────────────────────────────┘
           │          │
           ▼          ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    MOTOKO BACKEND CANISTER                            │
│                                                                     │
│  query (no consensus, fast)  │  update (consensus, finality)        │
│  Stable memory persistence   │  873ms heartbeat processing          │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 17. Extension Guide

### Adding a New Tab

1. Create `src/tabs/NewFeatureTab.tsx`
2. Create `src/hooks/useNewFeature.ts` with React Query hooks
3. Add TabId to type union in App.tsx
4. Add to TABS array with icon and label
5. Add conditional render in tab content section
6. Add corresponding backend queries if needed

### Adding a New Hook

```typescript
// src/hooks/useNewData.ts
import { useQuery, useMutation } from "@tanstack/react-query";
import { useActor } from "./useActor";

export function useNewData() {
  const { actor } = useActor();

  const query = useQuery({
    queryKey: ["newData"],
    queryFn: () => actor.getNewData(),
    enabled: !!actor,
    staleTime: 5000,
    refetchInterval: 10000,
  });

  const mutation = useMutation({
    mutationFn: (payload) => actor.updateNewData(payload),
    onSuccess: () => queryClient.invalidateQueries(["newData"]),
  });

  return { ...query, mutate: mutation.mutate };
}
```

### Adding a Utility

1. Create file in `src/utils/` or `src/lib/`
2. Export pure functions (no React dependencies)
3. Add unit tests in `__tests__/` directory
4. Import where needed

---

<div align="center">

*"The frontend faithfully implements the vision of PARALLAX as a sovereign intelligence organism — all mathematical and governance structures visible, interactive, and real-time."*

</div>
