import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Terminal } from "lucide-react";
import { useState } from "react";
import { useSaveProfile } from "../hooks/useQueries";

interface Props {
  onComplete: () => void;
}

export function SetupModal({ onComplete }: Props) {
  const [name, setName] = useState("");
  const saveMutation = useSaveProfile();

  const handleSubmit = async () => {
    if (!name.trim()) return;
    await saveMutation.mutateAsync(name.trim());
    onComplete();
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-background/95 backdrop-blur-sm"
      data-ocid="setup.modal"
    >
      <div className="w-full max-w-sm border border-border bg-card p-6 space-y-5">
        <div className="flex items-center gap-2">
          <Terminal className="w-4 h-4 text-primary" />
          <span className="font-mono text-xs text-muted-foreground tracking-widest uppercase">
            Initialize Session
          </span>
        </div>
        <div className="space-y-1">
          <h2 className="text-foreground font-semibold text-lg">
            Identify yourself
          </h2>
          <p className="text-muted-foreground text-sm">
            This name will be stored on-chain and used to personalize your
            memory graph.
          </p>
        </div>
        <div className="space-y-2">
          <Input
            placeholder="Your name..."
            value={name}
            onChange={(e) => setName(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && handleSubmit()}
            className="bg-muted border-border font-mono text-sm"
            autoFocus
            data-ocid="setup.input"
          />
        </div>
        <Button
          onClick={handleSubmit}
          disabled={!name.trim() || saveMutation.isPending}
          className="w-full"
          data-ocid="setup.submit_button"
        >
          {saveMutation.isPending ? "Saving..." : "Initialize"}
        </Button>
      </div>
    </div>
  );
}
