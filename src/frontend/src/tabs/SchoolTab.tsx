/**
 * SchoolTab.tsx — SOVEREIGN KNOWLEDGE CANISTER · SCHOOL
 * Public Bronze Tier — No login required for students
 * Teacher/Admin Panel gated by Internet Identity
 * PARALLAX · Texas TEA · TEKS Aligned · Dallas ISD
 * Alfredo Medina Hernandez · Creator · 2026
 */

import { useInternetIdentity } from "@caffeineai/core-infrastructure";
import { motion } from "motion/react";
import { useState } from "react";
import { useActor } from "../hooks/useActor";
import {
  useAddLessonTool,
  useAddSchool,
  useAddTeksStandard,
  useDeploySchoolCanister,
  useGrantsByStatus,
  useLessonToolsBySubject,
  usePublicCurriculum,
  useSchoolRegistry,
  useUpdateGrantStatus,
} from "../hooks/useSchool";

// ── Color palette (PARALLAX dark + cyan 85° accent) ──────────────────────────
const C = {
  // Cyan 85° — school accent (TEKS / education)
  cyan: "oklch(0.85 0.18 195)",
  cyanDim: "oklch(0.72 0.16 195 / 0.7)",
  cyanFaint: "oklch(0.72 0.16 195 / 0.07)",
  cyanBorder: "oklch(0.72 0.16 195 / 0.30)",
  // Emerald — Bronze free tier badge
  emerald: "oklch(0.72 0.18 160)",
  emeraldFaint: "oklch(0.72 0.18 160 / 0.08)",
  emeraldBorder: "oklch(0.72 0.18 160 / 0.35)",
  // Gold — headers
  gold: "oklch(0.78 0.15 85)",
  goldFaint: "oklch(0.78 0.15 85 / 0.06)",
  goldBorder: "oklch(0.78 0.15 85 / 0.25)",
  // Amber — grant deadlines
  amber: "oklch(0.72 0.18 65)",
  amberFaint: "oklch(0.72 0.18 65 / 0.08)",
  amberBorder: "oklch(0.72 0.18 65 / 0.35)",
  // Status
  green: "oklch(0.65 0.18 145)",
  greenFaint: "oklch(0.65 0.18 145 / 0.08)",
  greenBorder: "oklch(0.65 0.18 145 / 0.35)",
  red: "oklch(0.55 0.22 25)",
  redFaint: "oklch(0.55 0.22 25 / 0.08)",
  redBorder: "oklch(0.55 0.22 25 / 0.35)",
  // Base
  text: "oklch(0.92 0.02 270)",
  muted: "oklch(0.48 0.04 270)",
  dim: "oklch(0.30 0.03 270)",
  card: "oklch(0.11 0.02 240)",
  cardBorder: "oklch(0.20 0.02 240)",
  bg: "oklch(0.08 0.01 240)",
};

// ── Shared primitives ─────────────────────────────────────────────────────────

function SectionHeader({ label, sub }: { label: string; sub?: string }) {
  return (
    <div
      className="px-5 py-4 border-b"
      style={{
        borderColor: C.cyanBorder,
        background: C.cyanFaint,
        backgroundImage:
          "linear-gradient(oklch(0.72 0.16 195 / 0.02) 1px, transparent 1px), linear-gradient(90deg, oklch(0.72 0.16 195 / 0.02) 1px, transparent 1px)",
        backgroundSize: "24px 24px",
      }}
    >
      <div
        className="font-mono text-xs tracking-[0.4em]"
        style={{ color: C.cyan }}
      >
        {label}
      </div>
      {sub && (
        <div
          className="font-mono text-[8px] tracking-[0.2em] mt-1"
          style={{ color: C.muted }}
        >
          {sub}
        </div>
      )}
    </div>
  );
}

function BronzeBadge() {
  return (
    <span
      className="inline-flex items-center gap-1 font-mono text-[7px] px-2 py-0.5 border tracking-widest"
      style={{
        color: C.emerald,
        borderColor: C.emeraldBorder,
        backgroundColor: C.emeraldFaint,
      }}
    >
      ◈ BRONZE FREE
    </span>
  );
}

function SubjectBadge({ subject }: { subject: string }) {
  const subjectColors: Record<
    string,
    { color: string; border: string; bg: string }
  > = {
    Math: { color: C.gold, border: C.goldBorder, bg: C.goldFaint },
    Science: { color: C.green, border: C.greenBorder, bg: C.greenFaint },
    English: { color: C.cyan, border: C.cyanBorder, bg: C.cyanFaint },
    "Computer Science": {
      color: C.amber,
      border: C.amberBorder,
      bg: C.amberFaint,
    },
    Biology: { color: C.emerald, border: C.emeraldBorder, bg: C.emeraldFaint },
    Algebra: { color: C.gold, border: C.goldBorder, bg: C.goldFaint },
  };
  const s = subjectColors[subject] ?? {
    color: C.muted,
    border: C.cardBorder,
    bg: "transparent",
  };
  return (
    <span
      className="font-mono text-[7px] px-1.5 py-0.5 border tracking-widest"
      style={{ color: s.color, borderColor: s.border, backgroundColor: s.bg }}
    >
      {subject.toUpperCase()}
    </span>
  );
}

function GradeBadge({ grade }: { grade: string }) {
  return (
    <span
      className="font-mono text-[7px] px-1.5 py-0.5 border tracking-widest"
      style={{
        color: C.cyan,
        borderColor: C.cyanBorder,
        backgroundColor: C.cyanFaint,
      }}
    >
      {grade.toUpperCase()}
    </span>
  );
}

function GrantStatusBadge({ status }: { status: string }) {
  const s =
    status === "active"
      ? { color: C.green, border: C.greenBorder, bg: C.greenFaint }
      : status === "pending"
        ? { color: C.amber, border: C.amberBorder, bg: C.amberFaint }
        : { color: C.muted, border: C.cardBorder, bg: "transparent" };
  return (
    <span
      className="font-mono text-[7px] px-1.5 py-0.5 border tracking-widest uppercase"
      style={{ color: s.color, borderColor: s.border, backgroundColor: s.bg }}
    >
      {status}
    </span>
  );
}

// ── Section 1: Public Hero ────────────────────────────────────────────────────

function PublicHero() {
  return (
    <motion.div
      initial={{ opacity: 0, y: -10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.55 }}
      className="relative border-b overflow-hidden"
      style={{
        borderColor: C.cyanBorder,
        backgroundColor: "oklch(0.10 0.02 240)",
        backgroundImage: [
          "radial-gradient(ellipse at 60% 0%, oklch(0.72 0.16 195 / 0.12) 0%, transparent 60%)",
          "linear-gradient(oklch(0.72 0.16 195 / 0.02) 1px, transparent 1px)",
          "linear-gradient(90deg, oklch(0.72 0.16 195 / 0.02) 1px, transparent 1px)",
        ].join(", "),
        backgroundSize: "100% 100%, 48px 48px, 48px 48px",
      }}
      data-ocid="school.hero.section"
    >
      <div className="relative z-10 px-6 pt-8 pb-7">
        {/* Live badge row */}
        <div className="flex flex-wrap items-center gap-3 mb-5">
          <div className="flex items-center gap-2">
            <div
              className="w-2 h-2 animate-beat"
              style={{
                backgroundColor: C.emerald,
                boxShadow: `0 0 8px ${C.emerald}`,
              }}
            />
            <span
              className="font-mono text-[8px] tracking-[0.5em]"
              style={{ color: C.emerald }}
            >
              LIVE ON ICP NETWORK
            </span>
          </div>
          <BronzeBadge />
          <span
            className="font-mono text-[7px] px-2 py-0.5 border tracking-widest"
            style={{
              color: C.cyan,
              borderColor: C.cyanBorder,
              backgroundColor: C.cyanFaint,
            }}
          >
            ⬡ WORKS OFFLINE
          </span>
        </div>

        {/* Title */}
        <div
          className="font-display font-bold text-3xl md:text-4xl tracking-[0.25em] mb-2"
          style={{
            color: C.cyan,
            textShadow: "0 0 40px oklch(0.72 0.16 195 / 0.35)",
          }}
        >
          SOVEREIGN KNOWLEDGE CANISTER
        </div>
        <div
          className="font-mono text-sm md:text-base tracking-[0.2em] mb-1"
          style={{ color: "oklch(0.75 0.04 240)" }}
        >
          Free Public Access — No Server, No Data Sold, Works Offline
        </div>
        <div
          className="font-mono text-[9px] tracking-[0.25em] mb-6"
          style={{ color: C.muted }}
        >
          Dallas ISD · Texas TEA · TEKS Aligned
        </div>

        {/* Feature grid */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          {[
            {
              icon: "◈",
              label: "NO SERVER",
              sub: "ICP native — no cloud dependency",
            },
            {
              icon: "⬡",
              label: "OFFLINE PWA",
              sub: "Cached for offline access",
            },
            {
              icon: "✦",
              label: "TEKS ALIGNED",
              sub: "Texas Essential Knowledge & Skills",
            },
            {
              icon: "⊡",
              label: "FREE FOREVER",
              sub: "Bronze tier — zero cost to schools",
            },
          ].map((f) => (
            <div
              key={f.label}
              className="p-3 border"
              style={{
                background: "oklch(0.09 0.01 240)",
                borderColor: C.cardBorder,
              }}
            >
              <div
                className="font-mono text-base mb-1"
                style={{ color: C.cyan }}
              >
                {f.icon}
              </div>
              <div
                className="font-mono text-[8px] tracking-[0.3em] mb-0.5"
                style={{ color: C.text }}
              >
                {f.label}
              </div>
              <div className="font-mono text-[7px]" style={{ color: C.dim }}>
                {f.sub}
              </div>
            </div>
          ))}
        </div>
      </div>
    </motion.div>
  );
}

// ── Section 2: Curriculum Browser ─────────────────────────────────────────────

type SubjectFilter =
  | "All"
  | "Math"
  | "Science"
  | "English"
  | "Computer Science"
  | "Biology"
  | "Algebra";
type GradeFilter = "All" | "K-2" | "3-5" | "6-8" | "High School";

interface LessonTool {
  id: string;
  title: string;
  subject: string;
  teksCodes: string[];
  toolType: string;
  publicAccess: boolean;
  description: string;
}

interface TeksStandard {
  code: string;
  grade: string;
  subject: string;
  title: string;
  description: string;
  lessonTools: LessonTool[];
}

function LessonToolCard({ tool }: { tool: LessonTool }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 4 }}
      animate={{ opacity: 1, y: 0 }}
      className="p-3 border"
      style={{
        background: "oklch(0.09 0.01 240)",
        borderColor: C.emeraldBorder,
      }}
    >
      <div className="flex flex-wrap items-start justify-between gap-2 mb-1">
        <div className="font-mono text-[9px]" style={{ color: C.emerald }}>
          {tool.title}
        </div>
        <div className="flex gap-1.5 flex-wrap">
          <span
            className="font-mono text-[7px] px-1.5 py-0.5 border"
            style={{
              color: C.cyan,
              borderColor: C.cyanBorder,
              backgroundColor: C.cyanFaint,
            }}
          >
            {tool.toolType.toUpperCase()}
          </span>
          {tool.publicAccess && <BronzeBadge />}
        </div>
      </div>
      <div className="font-mono text-[7px] mb-1.5" style={{ color: C.dim }}>
        {tool.description}
      </div>
      <div className="flex flex-wrap gap-1">
        {tool.teksCodes.map((code) => (
          <span
            key={code}
            className="font-mono text-[7px] px-1 py-0.5 border"
            style={{ color: C.gold, borderColor: C.goldBorder }}
          >
            {code}
          </span>
        ))}
      </div>
    </motion.div>
  );
}

function StandardCard({
  std,
  index,
}: {
  std: TeksStandard;
  index: number;
}) {
  const [expanded, setExpanded] = useState(false);

  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.04 }}
      className="border overflow-hidden"
      style={{ background: C.card, borderColor: C.cardBorder }}
      data-ocid={`school.standard.item.${index + 1}`}
    >
      <button
        type="button"
        className="w-full text-left p-4 transition-all"
        style={{ background: expanded ? C.cyanFaint : "transparent" }}
        onClick={() => setExpanded((e) => !e)}
        data-ocid={`school.standard.toggle.${index + 1}`}
      >
        <div className="flex flex-wrap items-start justify-between gap-2 mb-2">
          <div className="flex flex-wrap items-center gap-2">
            <span
              className="font-mono text-[9px] font-bold tracking-widest"
              style={{ color: C.gold }}
            >
              {std.code}
            </span>
            <GradeBadge grade={std.grade} />
            <SubjectBadge subject={std.subject} />
          </div>
          <div className="flex items-center gap-2">
            {std.lessonTools.length > 0 && (
              <span
                className="font-mono text-[7px] px-1.5 py-0.5 border"
                style={{
                  color: C.emerald,
                  borderColor: C.emeraldBorder,
                  backgroundColor: C.emeraldFaint,
                }}
              >
                {std.lessonTools.length} TOOL
                {std.lessonTools.length !== 1 ? "S" : ""}
              </span>
            )}
            <span
              className="font-mono text-[9px] transition-transform duration-200"
              style={{
                color: C.muted,
                transform: expanded ? "rotate(180deg)" : "rotate(0deg)",
              }}
            >
              ▾
            </span>
          </div>
        </div>
        <div
          className="font-mono text-[9px] font-medium mb-1"
          style={{ color: C.text }}
        >
          {std.title}
        </div>
        <div
          className="font-mono text-[8px] leading-relaxed"
          style={{
            color: C.muted,
            display: "-webkit-box",
            WebkitLineClamp: expanded ? undefined : 2,
            WebkitBoxOrient: "vertical",
            overflow: expanded ? "visible" : "hidden",
          }}
        >
          {std.description}
        </div>
      </button>

      {expanded && std.lessonTools.length > 0 && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="px-4 pb-4 pt-1 space-y-2 border-t"
          style={{ borderColor: C.cyanBorder }}
        >
          <div
            className="font-mono text-[7px] tracking-[0.4em] mb-2"
            style={{ color: C.cyan }}
          >
            LESSON TOOLS AVAILABLE
          </div>
          {std.lessonTools.map((tool) => (
            <LessonToolCard key={tool.id} tool={tool} />
          ))}
        </motion.div>
      )}
    </motion.div>
  );
}

function CurriculumBrowser() {
  const [subject, setSubject] = useState<SubjectFilter>("All");
  const [grade, setGrade] = useState<GradeFilter>("All");

  const { data: allStandards = [], isLoading: stdLoading } =
    usePublicCurriculum();
  const { data: bySubject = [], isLoading: subLoading } =
    useLessonToolsBySubject(subject === "All" ? "" : subject);

  // Merge lesson tools into standards when subject filter is active
  const standards: TeksStandard[] = (allStandards as TeksStandard[]).filter(
    (s) => {
      if (subject !== "All" && s.subject !== subject) return false;
      if (grade !== "All" && s.grade !== grade) return false;
      return true;
    },
  );

  // If subject filter used, attach lesson tools from bySubject query
  const enriched: TeksStandard[] =
    subject !== "All"
      ? standards.map((s) => ({
          ...s,
          lessonTools:
            s.lessonTools.length > 0
              ? s.lessonTools
              : (bySubject as LessonTool[]).filter((t) =>
                  t.teksCodes.includes(s.code),
                ),
        }))
      : standards;

  const subjects: SubjectFilter[] = [
    "All",
    "Math",
    "Science",
    "English",
    "Computer Science",
    "Biology",
    "Algebra",
  ];
  const grades: GradeFilter[] = ["All", "K-2", "3-5", "6-8", "High School"];
  const isLoading = stdLoading || subLoading;

  return (
    <div data-ocid="school.curriculum.section">
      <SectionHeader
        label="■ TEKS CURRICULUM BROWSER"
        sub="Public access · No login required · Texas Essential Knowledge and Skills"
      />
      <div className="p-5 space-y-4">
        {/* Subject filters */}
        <div>
          <div
            className="font-mono text-[7px] tracking-[0.4em] mb-2"
            style={{ color: C.muted }}
          >
            SUBJECT
          </div>
          <div
            className="flex flex-wrap gap-2"
            data-ocid="school.subject.filter"
          >
            {subjects.map((s) => (
              <button
                key={s}
                type="button"
                onClick={() => setSubject(s)}
                data-ocid={`school.subject.${s.toLowerCase().replace(/ /g, "_")}.tab`}
                className="px-3 py-1.5 border font-mono text-[8px] tracking-[0.2em] transition-all duration-200"
                style={{
                  borderColor: subject === s ? C.cyanBorder : C.cardBorder,
                  color: subject === s ? C.cyan : C.muted,
                  backgroundColor: subject === s ? C.cyanFaint : "transparent",
                }}
              >
                {s.toUpperCase()}
              </button>
            ))}
          </div>
        </div>

        {/* Grade filters */}
        <div>
          <div
            className="font-mono text-[7px] tracking-[0.4em] mb-2"
            style={{ color: C.muted }}
          >
            GRADE BAND
          </div>
          <div className="flex flex-wrap gap-2" data-ocid="school.grade.filter">
            {grades.map((g) => (
              <button
                key={g}
                type="button"
                onClick={() => setGrade(g)}
                data-ocid={`school.grade.${g.toLowerCase().replace(/ /g, "_")}.tab`}
                className="px-3 py-1.5 border font-mono text-[8px] tracking-[0.2em] transition-all duration-200"
                style={{
                  borderColor: grade === g ? C.goldBorder : C.cardBorder,
                  color: grade === g ? C.gold : C.muted,
                  backgroundColor: grade === g ? C.goldFaint : "transparent",
                }}
              >
                {g.toUpperCase()}
              </button>
            ))}
          </div>
        </div>

        {/* Results count */}
        <div className="font-mono text-[8px]" style={{ color: C.muted }}>
          {isLoading
            ? "LOADING STANDARDS..."
            : `${enriched.length} STANDARD${enriched.length !== 1 ? "S" : ""} FOUND`}
        </div>

        {/* Standard cards grid */}
        {isLoading ? (
          <div
            className="py-10 text-center font-mono text-[9px]"
            style={{ color: C.muted }}
            data-ocid="school.curriculum.loading_state"
          >
            <div
              className="inline-block w-5 h-5 border-t border-l animate-spin mb-3"
              style={{ borderColor: C.cyan }}
            />
            <div>LOADING TEKS STANDARDS...</div>
          </div>
        ) : enriched.length === 0 ? (
          <div
            className="py-12 text-center border"
            style={{ background: C.card, borderColor: C.cardBorder }}
            data-ocid="school.curriculum.empty_state"
          >
            <div className="font-mono text-3xl mb-3" style={{ color: C.dim }}>
              ◈
            </div>
            <div
              className="font-mono text-[9px] tracking-[0.3em] mb-1"
              style={{ color: C.muted }}
            >
              NO STANDARDS MATCH
            </div>
            <div className="font-mono text-[8px]" style={{ color: C.dim }}>
              Try a different subject or grade filter
            </div>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
            {enriched.map((std, i) => (
              <StandardCard key={std.code} std={std} index={i} />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

// ── Section 3: About / Sovereign Canister Explainer ───────────────────────────

function AboutSection() {
  return (
    <div data-ocid="school.about.section">
      <SectionHeader
        label="■ WHAT IS A SOVEREIGN CANISTER?"
        sub="Plain language — no jargon. Here's what this means for your school."
      />
      <div className="p-5">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {[
            {
              icon: "◈",
              title: "No Server",
              body: "This tool doesn't live on a company's server. It runs directly on the ICP network — a global public computer. Nobody can take it down by pulling a plug.",
              color: C.cyan,
              border: C.cyanBorder,
              bg: C.cyanFaint,
            },
            {
              icon: "⊡",
              title: "No Data Sold",
              body: "We don't collect student data. There are no ads, no analytics sold to third parties. The canister stores curriculum — nothing else.",
              color: C.emerald,
              border: C.emeraldBorder,
              bg: C.emeraldFaint,
            },
            {
              icon: "⬡",
              title: "Your School Owns It",
              body: "Bronze tier schools can request their own deployed canister on the ICP network. That canister belongs to your school — not to us. You control it.",
              color: C.gold,
              border: C.goldBorder,
              bg: C.goldFaint,
            },
          ].map((card, i) => (
            <motion.div
              key={card.title}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.08 }}
              className="p-5 border"
              style={{ background: C.card, borderColor: card.border }}
            >
              <div
                className="font-mono text-2xl mb-3"
                style={{ color: card.color }}
              >
                {card.icon}
              </div>
              <div
                className="font-mono text-xs font-bold tracking-[0.2em] mb-2"
                style={{ color: card.color }}
              >
                {card.title.toUpperCase()}
              </div>
              <div
                className="font-mono text-[8px] leading-relaxed"
                style={{ color: C.muted }}
              >
                {card.body}
              </div>
            </motion.div>
          ))}
        </div>

        {/* Works offline note */}
        <div
          className="mt-4 px-4 py-3 border font-mono text-[8px] flex flex-wrap items-center gap-3"
          style={{
            borderColor: C.emeraldBorder,
            backgroundColor: C.emeraldFaint,
            color: C.emerald,
          }}
        >
          <span>⬡ WORKS OFFLINE</span>
          <span style={{ color: C.dim }}>·</span>
          <span style={{ color: C.muted }}>
            This app is cached as a Progressive Web App (PWA). Students can load
            curriculum standards on any school device — even without internet
            after the first visit.
          </span>
        </div>
      </div>
    </div>
  );
}

// ── Section 4: Grant Funding ──────────────────────────────────────────────────

const GRANT_FALLBACK = [
  {
    name: "E-Rate Program",
    program: "FCC Universal Service Fund",
    amountUsd: 3_000_000,
    deadlineMs: new Date("2026-12-01").getTime(),
    status: "active",
    notes:
      "Covers broadband, infrastructure. Sovereign canister qualifies as educational technology infrastructure.",
  },
  {
    name: "Title IV-A SSAE",
    program: "U.S. Dept. of Education",
    amountUsd: 500_000,
    deadlineMs: new Date("2026-09-15").getTime(),
    status: "active",
    notes:
      "Student Support and Academic Enrichment. AI education tools qualify. Well-being, academic achievement, digital literacy.",
  },
  {
    name: "TEA Innovation Grant",
    program: "Texas Education Agency",
    amountUsd: 250_000,
    deadlineMs: new Date("2026-08-01").getTime(),
    status: "pending",
    notes:
      "Texas-specific education innovation. Sovereign canister per school model is novel enough for infrastructure classification.",
  },
  {
    name: "NSF AI Education",
    program: "National Science Foundation",
    amountUsd: 750_000,
    deadlineMs: new Date("2027-01-15").getTime(),
    status: "active",
    notes:
      "Agentic AI for education research grants. University of Nebraska and Kansas partnerships strengthen eligibility.",
  },
];

function GrantSection() {
  const { data: grantsRaw = [], isLoading } = useGrantsByStatus("active");

  const grants =
    (
      grantsRaw as Array<{
        name: string;
        program: string;
        amountUsd: number;
        deadlineMs: number;
        status: string;
        notes: string;
      }>
    ).length > 0
      ? (grantsRaw as typeof GRANT_FALLBACK)
      : GRANT_FALLBACK;

  const totalAvailable = grants.reduce((s, g) => s + g.amountUsd, 0);

  function formatUsd(n: number) {
    if (n >= 1_000_000) return `$${(n / 1_000_000).toFixed(1)}M`;
    if (n >= 1_000) return `$${(n / 1_000).toFixed(0)}K`;
    return `$${n.toLocaleString()}`;
  }

  function formatDeadline(ms: number) {
    return new Date(ms).toLocaleDateString("en-US", {
      month: "short",
      day: "numeric",
      year: "numeric",
    });
  }

  return (
    <div data-ocid="school.grants.section">
      <SectionHeader
        label="■ GRANT FUNDING ELIGIBILITY"
        sub="E-Rate · Title IV · TEA Innovation · NSF AI Education — school canister model qualifies"
      />
      <div className="p-5 space-y-4">
        {/* Total available */}
        <div
          className="px-5 py-4 border flex flex-wrap items-center justify-between gap-3"
          style={{ background: C.cyanFaint, borderColor: C.cyanBorder }}
        >
          <div>
            <div
              className="font-mono text-[7px] tracking-[0.4em] mb-1"
              style={{ color: C.muted }}
            >
              TOTAL AVAILABLE FUNDING
            </div>
            <div
              className="font-mono text-2xl font-bold tabular-nums"
              style={{
                color: C.cyan,
                textShadow: "0 0 20px oklch(0.72 0.16 195 / 0.4)",
              }}
            >
              {formatUsd(totalAvailable)}
            </div>
          </div>
          <div className="font-mono text-[8px]" style={{ color: C.muted }}>
            {grants.length} GRANT PROGRAMS · SCHOOL CANISTER QUALIFIES
          </div>
        </div>

        {/* Grant cards 2×2 */}
        {isLoading ? (
          <div
            className="py-8 text-center font-mono text-[9px]"
            style={{ color: C.muted }}
            data-ocid="school.grants.loading_state"
          >
            LOADING GRANTS...
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {grants.map((grant, i) => (
              <motion.div
                key={grant.name}
                initial={{ opacity: 0, y: 8 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: i * 0.06 }}
                className="p-4 border"
                style={{ background: C.card, borderColor: C.cardBorder }}
                data-ocid={`school.grant.item.${i + 1}`}
              >
                <div className="flex items-start justify-between gap-2 mb-2">
                  <div>
                    <div
                      className="font-mono text-[9px] font-bold"
                      style={{ color: C.text }}
                    >
                      {grant.name}
                    </div>
                    <div
                      className="font-mono text-[7px] mt-0.5"
                      style={{ color: C.muted }}
                    >
                      {grant.program}
                    </div>
                  </div>
                  <GrantStatusBadge status={grant.status} />
                </div>

                <div
                  className="font-mono text-xl font-bold tabular-nums mb-2"
                  style={{ color: C.gold }}
                >
                  {formatUsd(grant.amountUsd)}
                </div>

                <div
                  className="flex items-center gap-2 mb-2 font-mono text-[7px]"
                  style={{ color: C.amber }}
                >
                  <span>⏱</span>
                  <span>DEADLINE: {formatDeadline(grant.deadlineMs)}</span>
                </div>

                <div
                  className="font-mono text-[7px] leading-relaxed"
                  style={{ color: C.dim }}
                >
                  {grant.notes}
                </div>
              </motion.div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

// ── Section 5: Teacher/Admin Panel (gated) ────────────────────────────────────

function TeacherPanelGated() {
  const { identity, login } = useInternetIdentity();
  const { actor } = useActor();
  const isAuthenticated =
    identity != null && !identity.getPrincipal().isAnonymous();

  if (!isAuthenticated) {
    return (
      <div data-ocid="school.teacher_panel.section">
        <SectionHeader
          label="■ TEACHER & ADMIN TOOLS"
          sub="Authenticate with Internet Identity to access TEKS editor, school registry, and grant tools"
        />
        <div className="p-5">
          <motion.div
            initial={{ opacity: 0, y: 6 }}
            animate={{ opacity: 1, y: 0 }}
            className="border p-8 text-center"
            style={{ background: C.card, borderColor: C.cyanBorder }}
            data-ocid="school.teacher_panel.auth_gate"
          >
            <div className="font-mono text-3xl mb-4" style={{ color: C.cyan }}>
              ◈
            </div>
            <div
              className="font-mono text-xs tracking-[0.3em] mb-2"
              style={{ color: C.text }}
            >
              TEACHER TOOLS
            </div>
            <div
              className="font-mono text-[8px] mb-6"
              style={{ color: C.muted }}
            >
              Authenticate to access TEKS standards editor, school registry,
              canister deployment, and grant status management.
            </div>
            <motion.button
              type="button"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              onClick={login}
              className="px-6 py-3 border font-mono text-[9px] tracking-[0.3em] transition-all"
              style={{
                borderColor: C.cyanBorder,
                color: C.cyan,
                backgroundColor: C.cyanFaint,
              }}
              data-ocid="school.teacher_panel.login_button"
            >
              AUTHENTICATE WITH INTERNET IDENTITY
            </motion.button>
          </motion.div>
        </div>
      </div>
    );
  }

  return <TeacherPanelInner actor={actor} />;
}

function TeacherPanelInner({ actor: _actor }: { actor: unknown }) {
  return (
    <div data-ocid="school.teacher_panel.section">
      <SectionHeader
        label="■ TEACHER & ADMIN TOOLS"
        sub="Creator-only — TEKS editor · School registry · Grant tracker · Canister deployment"
      />
      <div className="p-5 space-y-6">
        <TeksEditor />
        <SchoolRegistryTable />
        <GrantStatusUpdater />
      </div>
    </div>
  );
}

// ── TEKS Editor ───────────────────────────────────────────────────────────────

function TeksEditor() {
  const { data: standards = [], isLoading } = usePublicCurriculum();
  const addStd = useAddTeksStandard();
  const addTool = useAddLessonTool();
  const [showAddStd, setShowAddStd] = useState(false);
  const [showAddTool, setShowAddTool] = useState(false);

  // Add standard form state
  const [stdCode, setStdCode] = useState("");
  const [stdGrade, setStdGrade] = useState("");
  const [stdSubject, setStdSubject] = useState("");
  const [stdTitle, setStdTitle] = useState("");
  const [stdDesc, setStdDesc] = useState("");

  // Add tool form state
  const [toolTeksCode, setToolTeksCode] = useState("");
  const [toolId, setToolId] = useState("");
  const [toolTitle, setToolTitle] = useState("");
  const [toolSubject, setToolSubject] = useState("");
  const [toolType, setToolType] = useState("");
  const [toolDesc, setToolDesc] = useState("");

  const inputStyle = {
    background: "oklch(0.09 0.01 240)",
    border: `1px solid ${C.cardBorder}`,
    color: C.text,
  };

  function handleAddStd() {
    if (!stdCode.trim() || !stdTitle.trim()) return;
    addStd.mutate(
      {
        code: stdCode.trim(),
        grade: stdGrade.trim(),
        subject: stdSubject.trim(),
        title: stdTitle.trim(),
        description: stdDesc.trim(),
        lessonTools: [],
      },
      {
        onSuccess: () => {
          setStdCode("");
          setStdGrade("");
          setStdSubject("");
          setStdTitle("");
          setStdDesc("");
          setShowAddStd(false);
        },
      },
    );
  }

  function handleAddTool() {
    if (!toolTeksCode.trim() || !toolTitle.trim()) return;
    addTool.mutate(
      {
        teksCode: toolTeksCode.trim(),
        tool: {
          id: toolId.trim() || `tool-${Date.now()}`,
          title: toolTitle.trim(),
          subject: toolSubject.trim(),
          teksCodes: [toolTeksCode.trim()],
          toolType: toolType.trim(),
          publicAccess: true,
          description: toolDesc.trim(),
        },
      },
      {
        onSuccess: () => {
          setToolTeksCode("");
          setToolId("");
          setToolTitle("");
          setToolSubject("");
          setToolType("");
          setToolDesc("");
          setShowAddTool(false);
        },
      },
    );
  }

  const stdList = standards as TeksStandard[];

  return (
    <div className="border" style={{ borderColor: C.cardBorder }}>
      <div
        className="px-4 py-3 border-b flex items-center justify-between"
        style={{
          borderColor: C.cardBorder,
          background: "oklch(0.10 0.02 240)",
        }}
      >
        <div
          className="font-mono text-[8px] tracking-[0.4em]"
          style={{ color: C.cyan }}
        >
          TEKS STANDARDS MANAGEMENT
        </div>
        <div className="flex gap-2">
          <button
            type="button"
            onClick={() => {
              setShowAddTool(false);
              setShowAddStd((v) => !v);
            }}
            className="px-3 py-1 border font-mono text-[7px] tracking-[0.2em] transition-all"
            style={{
              borderColor: C.goldBorder,
              color: C.gold,
              backgroundColor: C.goldFaint,
            }}
            data-ocid="school.add_standard.open_modal_button"
          >
            + ADD STANDARD
          </button>
          <button
            type="button"
            onClick={() => {
              setShowAddStd(false);
              setShowAddTool((v) => !v);
            }}
            className="px-3 py-1 border font-mono text-[7px] tracking-[0.2em] transition-all"
            style={{
              borderColor: C.cyanBorder,
              color: C.cyan,
              backgroundColor: C.cyanFaint,
            }}
            data-ocid="school.add_tool.open_modal_button"
          >
            + ADD TOOL
          </button>
        </div>
      </div>

      {/* Add standard form */}
      {showAddStd && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="p-4 border-b space-y-3"
          style={{
            borderColor: C.cardBorder,
            background: "oklch(0.09 0.01 240)",
          }}
          data-ocid="school.add_standard.dialog"
        >
          <div
            className="font-mono text-[8px] tracking-[0.3em]"
            style={{ color: C.gold }}
          >
            NEW TEKS STANDARD
          </div>
          <div className="grid grid-cols-2 md:grid-cols-3 gap-2">
            {[
              {
                label: "CODE",
                value: stdCode,
                set: setStdCode,
                ph: "e.g. MATH.5.3B",
                ocid: "school.std_code.input",
              },
              {
                label: "GRADE",
                value: stdGrade,
                set: setStdGrade,
                ph: "e.g. 5",
                ocid: "school.std_grade.input",
              },
              {
                label: "SUBJECT",
                value: stdSubject,
                set: setStdSubject,
                ph: "e.g. Math",
                ocid: "school.std_subject.input",
              },
            ].map((f) => (
              <div key={f.label}>
                <label
                  htmlFor={f.ocid}
                  className="font-mono text-[7px] tracking-[0.3em] block mb-1"
                  style={{ color: C.muted }}
                >
                  {f.label}
                </label>
                <input
                  id={f.ocid}
                  type="text"
                  value={f.value}
                  onChange={(e) => f.set(e.target.value)}
                  placeholder={f.ph}
                  className="w-full px-2 py-1.5 font-mono text-[9px] outline-none"
                  style={inputStyle}
                  data-ocid={f.ocid}
                />
              </div>
            ))}
          </div>
          <div>
            <label
              htmlFor="school.std_title.input"
              className="font-mono text-[7px] tracking-[0.3em] block mb-1"
              style={{ color: C.muted }}
            >
              TITLE
            </label>
            <input
              id="school.std_title.input"
              type="text"
              value={stdTitle}
              onChange={(e) => setStdTitle(e.target.value)}
              placeholder="Standard title"
              className="w-full px-2 py-1.5 font-mono text-[9px] outline-none"
              style={inputStyle}
              data-ocid="school.std_title.input"
            />
          </div>
          <div>
            <label
              htmlFor="school.std_desc.textarea"
              className="font-mono text-[7px] tracking-[0.3em] block mb-1"
              style={{ color: C.muted }}
            >
              DESCRIPTION
            </label>
            <textarea
              id="school.std_desc.textarea"
              value={stdDesc}
              onChange={(e) => setStdDesc(e.target.value)}
              placeholder="Standard description"
              rows={2}
              className="w-full px-2 py-1.5 font-mono text-[9px] outline-none resize-none"
              style={inputStyle}
              data-ocid="school.std_desc.textarea"
            />
          </div>
          <div className="flex gap-2">
            <button
              type="button"
              onClick={handleAddStd}
              disabled={addStd.isPending || !stdCode.trim() || !stdTitle.trim()}
              className="px-4 py-2 border font-mono text-[7px] tracking-[0.2em] transition-all disabled:opacity-40"
              style={{
                borderColor: C.goldBorder,
                color: C.gold,
                backgroundColor: C.goldFaint,
              }}
              data-ocid="school.add_standard.submit_button"
            >
              {addStd.isPending ? "SAVING..." : "SAVE STANDARD"}
            </button>
            <button
              type="button"
              onClick={() => setShowAddStd(false)}
              className="px-3 py-2 border font-mono text-[7px] tracking-[0.2em] transition-all"
              style={{ borderColor: C.cardBorder, color: C.muted }}
              data-ocid="school.add_standard.cancel_button"
            >
              CANCEL
            </button>
          </div>
          {addStd.isError && (
            <div
              className="font-mono text-[7px]"
              style={{ color: C.red }}
              data-ocid="school.add_standard.error_state"
            >
              ✗{" "}
              {addStd.error instanceof Error
                ? addStd.error.message
                : "Error saving standard"}
            </div>
          )}
        </motion.div>
      )}

      {/* Add tool form */}
      {showAddTool && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="p-4 border-b space-y-3"
          style={{
            borderColor: C.cardBorder,
            background: "oklch(0.09 0.01 240)",
          }}
          data-ocid="school.add_tool.dialog"
        >
          <div
            className="font-mono text-[8px] tracking-[0.3em]"
            style={{ color: C.cyan }}
          >
            NEW LESSON TOOL
          </div>
          <div className="grid grid-cols-2 gap-2">
            {[
              {
                label: "TEKS CODE",
                value: toolTeksCode,
                set: setToolTeksCode,
                ph: "e.g. MATH.5.3B",
                ocid: "school.tool_teks.input",
              },
              {
                label: "TOOL TITLE",
                value: toolTitle,
                set: setToolTitle,
                ph: "Tool name",
                ocid: "school.tool_title.input",
              },
              {
                label: "SUBJECT",
                value: toolSubject,
                set: setToolSubject,
                ph: "e.g. Math",
                ocid: "school.tool_subject.input",
              },
              {
                label: "TOOL TYPE",
                value: toolType,
                set: setToolType,
                ph: "e.g. interactive, video",
                ocid: "school.tool_type.input",
              },
            ].map((f) => (
              <div key={f.label}>
                <label
                  htmlFor={f.ocid}
                  className="font-mono text-[7px] tracking-[0.3em] block mb-1"
                  style={{ color: C.muted }}
                >
                  {f.label}
                </label>
                <input
                  id={f.ocid}
                  type="text"
                  value={f.value}
                  onChange={(e) => f.set(e.target.value)}
                  placeholder={f.ph}
                  className="w-full px-2 py-1.5 font-mono text-[9px] outline-none"
                  style={inputStyle}
                  data-ocid={f.ocid}
                />
              </div>
            ))}
          </div>
          <div>
            <label
              htmlFor="school.tool_desc.textarea"
              className="font-mono text-[7px] tracking-[0.3em] block mb-1"
              style={{ color: C.muted }}
            >
              DESCRIPTION
            </label>
            <textarea
              id="school.tool_desc.textarea"
              value={toolDesc}
              onChange={(e) => setToolDesc(e.target.value)}
              placeholder="Tool description"
              rows={2}
              className="w-full px-2 py-1.5 font-mono text-[9px] outline-none resize-none"
              style={inputStyle}
              data-ocid="school.tool_desc.textarea"
            />
          </div>
          <div className="flex gap-2">
            <button
              type="button"
              onClick={handleAddTool}
              disabled={
                addTool.isPending || !toolTeksCode.trim() || !toolTitle.trim()
              }
              className="px-4 py-2 border font-mono text-[7px] tracking-[0.2em] transition-all disabled:opacity-40"
              style={{
                borderColor: C.cyanBorder,
                color: C.cyan,
                backgroundColor: C.cyanFaint,
              }}
              data-ocid="school.add_tool.submit_button"
            >
              {addTool.isPending ? "SAVING..." : "SAVE TOOL"}
            </button>
            <button
              type="button"
              onClick={() => setShowAddTool(false)}
              className="px-3 py-2 border font-mono text-[7px] tracking-[0.2em] transition-all"
              style={{ borderColor: C.cardBorder, color: C.muted }}
              data-ocid="school.add_tool.cancel_button"
            >
              CANCEL
            </button>
          </div>
        </motion.div>
      )}

      {/* Standards list */}
      <div className="p-4 space-y-2">
        {isLoading ? (
          <div
            className="py-4 font-mono text-[8px]"
            style={{ color: C.muted }}
            data-ocid="school.teks_editor.loading_state"
          >
            LOADING STANDARDS...
          </div>
        ) : stdList.length === 0 ? (
          <div
            className="py-6 text-center font-mono text-[8px]"
            style={{ color: C.dim }}
            data-ocid="school.teks_editor.empty_state"
          >
            No standards yet. Add the first TEKS standard above.
          </div>
        ) : (
          stdList.slice(0, 20).map((s, i) => (
            <div
              key={s.code}
              className="flex flex-wrap items-center justify-between gap-2 px-3 py-2 border"
              style={{
                borderColor: C.cardBorder,
                background: "oklch(0.09 0.01 240)",
              }}
              data-ocid={`school.teks_std.item.${i + 1}`}
            >
              <div className="flex flex-wrap items-center gap-2 min-w-0">
                <span
                  className="font-mono text-[9px] font-bold"
                  style={{ color: C.gold }}
                >
                  {s.code}
                </span>
                <GradeBadge grade={s.grade} />
                <SubjectBadge subject={s.subject} />
                <span
                  className="font-mono text-[8px] truncate"
                  style={{ color: C.muted }}
                >
                  {s.title}
                </span>
              </div>
              <span className="font-mono text-[7px]" style={{ color: C.dim }}>
                {s.lessonTools.length} tool
                {s.lessonTools.length !== 1 ? "s" : ""}
              </span>
            </div>
          ))
        )}
      </div>
    </div>
  );
}

// ── School Registry Table ─────────────────────────────────────────────────────

interface SchoolRecord {
  id: string;
  name: string;
  district: string;
  teksStandardsCodes: string[];
  canisterId: string | null | undefined;
  tier: string;
  deployed: boolean;
  grantStatus: string;
  contactEmail: string;
}

function SchoolRegistryTable() {
  const { data: registry, isLoading } = useSchoolRegistry();
  const deployCanister = useDeploySchoolCanister();
  const addSchool = useAddSchool();

  const [showAdd, setShowAdd] = useState(false);
  const [schoolName, setSchoolName] = useState("");
  const [district, setDistrict] = useState("");
  const [email, setEmail] = useState("");
  const [deployingId, setDeployingId] = useState("");

  const inputStyle = {
    background: "oklch(0.09 0.01 240)",
    border: `1px solid ${C.cardBorder}`,
    color: C.text,
  };

  function handleDeploy(school: SchoolRecord) {
    const cid = `sch-${school.id}-${Date.now().toString(36)}`;
    setDeployingId(school.id);
    deployCanister.mutate(
      { schoolId: school.id, canisterId: cid },
      { onSettled: () => setDeployingId("") },
    );
  }

  function handleAddSchool() {
    if (!schoolName.trim() || !district.trim()) return;
    addSchool.mutate(
      {
        id: `school-${Date.now().toString(36)}`,
        name: schoolName.trim(),
        district: district.trim(),
        teksStandardsCodes: [],
        canisterId: null,
        tier: "Bronze",
        deployed: false,
        grantStatus: "pending",
        contactEmail: email.trim(),
      },
      {
        onSuccess: () => {
          setSchoolName("");
          setDistrict("");
          setEmail("");
          setShowAdd(false);
        },
      },
    );
  }

  const schools = (registry as SchoolRecord[] | undefined) ?? [];

  return (
    <div className="border" style={{ borderColor: C.cardBorder }}>
      <div
        className="px-4 py-3 border-b flex items-center justify-between"
        style={{
          borderColor: C.cardBorder,
          background: "oklch(0.10 0.02 240)",
        }}
      >
        <div
          className="font-mono text-[8px] tracking-[0.4em]"
          style={{ color: C.cyan }}
        >
          SCHOOL CANISTER REGISTRY
        </div>
        <button
          type="button"
          onClick={() => setShowAdd((v) => !v)}
          className="px-3 py-1 border font-mono text-[7px] tracking-[0.2em] transition-all"
          style={{
            borderColor: C.emeraldBorder,
            color: C.emerald,
            backgroundColor: C.emeraldFaint,
          }}
          data-ocid="school.add_school.open_modal_button"
        >
          + ADD SCHOOL
        </button>
      </div>

      {showAdd && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="p-4 border-b space-y-3"
          style={{
            borderColor: C.cardBorder,
            background: "oklch(0.09 0.01 240)",
          }}
          data-ocid="school.add_school.dialog"
        >
          <div
            className="font-mono text-[8px] tracking-[0.3em]"
            style={{ color: C.emerald }}
          >
            REGISTER NEW SCHOOL
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-2">
            {[
              {
                label: "SCHOOL NAME",
                value: schoolName,
                set: setSchoolName,
                ph: "e.g. Lincoln High School",
                ocid: "school.school_name.input",
              },
              {
                label: "DISTRICT",
                value: district,
                set: setDistrict,
                ph: "e.g. Dallas ISD",
                ocid: "school.district.input",
              },
              {
                label: "CONTACT EMAIL",
                value: email,
                set: setEmail,
                ph: "admin@school.edu",
                ocid: "school.contact_email.input",
              },
            ].map((f) => (
              <div key={f.label}>
                <label
                  htmlFor={f.ocid}
                  className="font-mono text-[7px] tracking-[0.3em] block mb-1"
                  style={{ color: C.muted }}
                >
                  {f.label}
                </label>
                <input
                  id={f.ocid}
                  type="text"
                  value={f.value}
                  onChange={(e) => f.set(e.target.value)}
                  placeholder={f.ph}
                  className="w-full px-2 py-1.5 font-mono text-[9px] outline-none"
                  style={inputStyle}
                  data-ocid={f.ocid}
                />
              </div>
            ))}
          </div>
          <div className="flex gap-2">
            <button
              type="button"
              onClick={handleAddSchool}
              disabled={
                addSchool.isPending || !schoolName.trim() || !district.trim()
              }
              className="px-4 py-2 border font-mono text-[7px] tracking-[0.2em] transition-all disabled:opacity-40"
              style={{
                borderColor: C.emeraldBorder,
                color: C.emerald,
                backgroundColor: C.emeraldFaint,
              }}
              data-ocid="school.add_school.submit_button"
            >
              {addSchool.isPending ? "SAVING..." : "REGISTER SCHOOL"}
            </button>
            <button
              type="button"
              onClick={() => setShowAdd(false)}
              className="px-3 py-2 border font-mono text-[7px] transition-all"
              style={{ borderColor: C.cardBorder, color: C.muted }}
              data-ocid="school.add_school.cancel_button"
            >
              CANCEL
            </button>
          </div>
        </motion.div>
      )}

      {/* Table */}
      {isLoading ? (
        <div
          className="py-6 text-center font-mono text-[8px]"
          style={{ color: C.muted }}
          data-ocid="school.registry.loading_state"
        >
          LOADING REGISTRY...
        </div>
      ) : schools.length === 0 ? (
        <div
          className="py-8 text-center font-mono text-[8px]"
          style={{ color: C.dim }}
          data-ocid="school.registry.empty_state"
        >
          No schools registered. Add the first school above.
        </div>
      ) : (
        <div className="overflow-x-auto" data-ocid="school.registry.table">
          <table
            className="w-full font-mono text-[8px]"
            style={{ borderCollapse: "collapse" }}
          >
            <thead>
              <tr style={{ borderBottom: `1px solid ${C.cardBorder}` }}>
                {[
                  "NAME",
                  "DISTRICT",
                  "TIER",
                  "DEPLOYED",
                  "CANISTER ID",
                  "GRANT STATUS",
                  "ACTION",
                ].map((h) => (
                  <th
                    key={h}
                    className="text-left px-3 py-2.5 tracking-[0.2em] whitespace-nowrap"
                    style={{ color: C.muted }}
                  >
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {schools.map((school, i) => (
                <tr
                  key={school.id}
                  style={{
                    borderBottom: "1px solid oklch(0.20 0.02 240 / 0.5)",
                  }}
                  data-ocid={`school.registry.item.${i + 1}`}
                >
                  <td className="px-3 py-2.5" style={{ color: C.text }}>
                    {school.name}
                  </td>
                  <td className="px-3 py-2.5" style={{ color: C.muted }}>
                    {school.district}
                  </td>
                  <td className="px-3 py-2.5">
                    <span
                      className="font-mono text-[7px] px-1.5 py-0.5 border"
                      style={{
                        color: C.emerald,
                        borderColor: C.emeraldBorder,
                        backgroundColor: C.emeraldFaint,
                      }}
                    >
                      {school.tier.toUpperCase()}
                    </span>
                  </td>
                  <td className="px-3 py-2.5 text-center">
                    <span style={{ color: school.deployed ? C.green : C.dim }}>
                      {school.deployed ? "✓" : "—"}
                    </span>
                  </td>
                  <td className="px-3 py-2.5 max-w-[140px]">
                    <span
                      className="font-mono text-[7px] truncate block"
                      style={{ color: C.cyanDim }}
                    >
                      {school.canisterId
                        ? `${String(school.canisterId).slice(0, 16)}…`
                        : "NOT DEPLOYED"}
                    </span>
                  </td>
                  <td className="px-3 py-2.5">
                    <GrantStatusBadge status={school.grantStatus} />
                  </td>
                  <td className="px-3 py-2.5">
                    {!school.deployed && (
                      <button
                        type="button"
                        onClick={() => handleDeploy(school)}
                        disabled={
                          deployCanister.isPending && deployingId === school.id
                        }
                        className="px-2 py-1 border font-mono text-[7px] tracking-widest transition-all disabled:opacity-40"
                        style={{
                          color: C.cyan,
                          borderColor: C.cyanBorder,
                          backgroundColor: C.cyanFaint,
                        }}
                        data-ocid={`school.deploy_canister.button.${i + 1}`}
                      >
                        {deployCanister.isPending && deployingId === school.id
                          ? "DEPLOYING…"
                          : "DEPLOY"}
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

// ── Grant Status Updater ──────────────────────────────────────────────────────

function GrantStatusUpdater() {
  const updateStatus = useUpdateGrantStatus();
  const [grantName, setGrantName] = useState("");
  const [status, setStatus] = useState("active");

  const inputStyle = {
    background: "oklch(0.09 0.01 240)",
    border: `1px solid ${C.cardBorder}`,
    color: C.text,
  };

  return (
    <div className="border p-4 space-y-3" style={{ borderColor: C.cardBorder }}>
      <div
        className="font-mono text-[8px] tracking-[0.4em]"
        style={{ color: C.gold }}
      >
        GRANT STATUS UPDATER
      </div>
      <div className="flex flex-wrap gap-3 items-end">
        <div className="flex-1 min-w-[150px]">
          <label
            htmlFor="school.grant_name.input"
            className="font-mono text-[7px] tracking-[0.3em] block mb-1"
            style={{ color: C.muted }}
          >
            GRANT NAME
          </label>
          <input
            id="school.grant_name.input"
            type="text"
            value={grantName}
            onChange={(e) => setGrantName(e.target.value)}
            placeholder="e.g. E-Rate Program"
            className="w-full px-2 py-1.5 font-mono text-[9px] outline-none"
            style={inputStyle}
            data-ocid="school.grant_name.input"
          />
        </div>
        <div>
          <label
            htmlFor="school.grant_status.select"
            className="font-mono text-[7px] tracking-[0.3em] block mb-1"
            style={{ color: C.muted }}
          >
            STATUS
          </label>
          <select
            id="school.grant_status.select"
            value={status}
            onChange={(e) => setStatus(e.target.value)}
            className="px-2 py-1.5 font-mono text-[9px] outline-none"
            style={inputStyle}
            data-ocid="school.grant_status.select"
          >
            <option value="active">ACTIVE</option>
            <option value="pending">PENDING</option>
            <option value="awarded">AWARDED</option>
            <option value="declined">DECLINED</option>
          </select>
        </div>
        <button
          type="button"
          onClick={() => {
            if (grantName.trim()) {
              updateStatus.mutate({ grantName: grantName.trim(), status });
            }
          }}
          disabled={updateStatus.isPending || !grantName.trim()}
          className="px-4 py-2 border font-mono text-[7px] tracking-[0.25em] transition-all disabled:opacity-40"
          style={{
            borderColor: C.goldBorder,
            color: C.gold,
            backgroundColor: C.goldFaint,
          }}
          data-ocid="school.update_grant.submit_button"
        >
          {updateStatus.isPending ? "UPDATING..." : "UPDATE"}
        </button>
      </div>
      {updateStatus.isSuccess && (
        <div
          className="font-mono text-[7px]"
          style={{ color: C.green }}
          data-ocid="school.update_grant.success_state"
        >
          ✓ Grant status updated
        </div>
      )}
      {updateStatus.isError && (
        <div
          className="font-mono text-[7px]"
          style={{ color: C.red }}
          data-ocid="school.update_grant.error_state"
        >
          ✗{" "}
          {updateStatus.error instanceof Error
            ? updateStatus.error.message
            : "Error updating status"}
        </div>
      )}
    </div>
  );
}

// ── Main SchoolTab ─────────────────────────────────────────────────────────────

export function SchoolTab() {
  return (
    <div className="space-y-0 pb-10" data-ocid="school.page">
      <PublicHero />
      <CurriculumBrowser />
      <AboutSection />
      <GrantSection />
      <TeacherPanelGated />
    </div>
  );
}
