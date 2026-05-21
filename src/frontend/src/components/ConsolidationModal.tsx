import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { BrainCircuit, Clock, Database, GitMerge, Zap } from "lucide-react";

interface Props {
  open: boolean;
  onClose: () => void;
}

const LAYERS = [
  {
    icon: Database,
    title: "Episodic Memory Store",
    subtitle: "Active now",
    description:
      "All conversations are extracted into nodes and edges stored in the knowledge graph. Entities, concepts, and relationships are persisted across sessions.",
    status: "active",
  },
  {
    icon: GitMerge,
    title: "Salience Scoring",
    subtitle: "Active now",
    description:
      "Edges are ranked by salience and reinforcement count. High-salience edges (> 0.8) reinforced across 3+ sessions are marked for consolidation.",
    status: "active",
  },
  {
    icon: BrainCircuit,
    title: "Pattern Extraction",
    subtitle: "Future layer",
    description:
      "A background job would scan the high-salience subgraph to extract abstract patterns — not raw episodic facts, but generalized beliefs and behavioral tendencies.",
    status: "future",
  },
  {
    icon: Zap,
    title: "Interleaved Fine-Tuning",
    subtitle: "Future layer",
    description:
      "Patterns would be used to fine-tune model weights via interleaved training with a replay buffer of old data. Elastic Weight Consolidation (EWC) prevents catastrophic forgetting.",
    status: "future",
  },
  {
    icon: Clock,
    title: "Post-Consolidation Pruning",
    subtitle: "Future layer",
    description:
      "Successfully consolidated memories are downgraded in the graph retrieval priority — no longer needing injection at session start since the model carries them intrinsically.",
    status: "future",
  },
];

export function ConsolidationModal({ open, onClose }: Props) {
  return (
    <Dialog open={open} onOpenChange={(o) => !o && onClose()}>
      <DialogContent
        className="bg-card border-border max-w-lg max-h-[85vh] overflow-y-auto"
        data-ocid="consolidation.modal"
      >
        <DialogHeader>
          <DialogTitle className="font-display text-xl flex items-center gap-2">
            <Zap className="w-5 h-5 text-primary" />
            Consolidation Layer Architecture
          </DialogTitle>
        </DialogHeader>
        <p className="text-sm text-muted-foreground">
          MemoryGraph AI implements a two-layer memory architecture. The
          retrieval-augmented layer is active now. The consolidation layer is
          designed and ready for integration.
        </p>
        <div className="flex flex-col gap-3 mt-2">
          {LAYERS.map((layer) => {
            const Icon = layer.icon;
            const isActive = layer.status === "active";
            return (
              <div
                key={layer.title}
                className={`rounded-lg border p-4 flex gap-3 ${
                  isActive
                    ? "border-primary/30 bg-primary/5"
                    : "border-border bg-background/50"
                }`}
              >
                <div
                  className={`shrink-0 w-8 h-8 rounded-lg flex items-center justify-center ${
                    isActive
                      ? "bg-primary/20 text-primary"
                      : "bg-muted text-muted-foreground"
                  }`}
                >
                  <Icon className="w-4 h-4" />
                </div>
                <div className="flex flex-col gap-1">
                  <div className="flex items-center gap-2">
                    <span className="font-medium text-sm">{layer.title}</span>
                    <span
                      className={`text-xs px-1.5 py-0.5 rounded ${
                        isActive
                          ? "bg-primary/20 text-primary"
                          : "bg-muted text-muted-foreground"
                      }`}
                    >
                      {layer.subtitle}
                    </span>
                  </div>
                  <p className="text-xs text-muted-foreground leading-relaxed">
                    {layer.description}
                  </p>
                </div>
              </div>
            );
          })}
        </div>
        <p className="text-xs text-muted-foreground mt-2 italic">
          The consolidation layer requires access to model weights and a
          fine-tuning pipeline — a 3–5 year research and engineering effort at
          production scale.
        </p>
      </DialogContent>
    </Dialog>
  );
}
