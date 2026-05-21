import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Slider } from "@/components/ui/slider";
import { Loader2 } from "lucide-react";
import { useState } from "react";
import { RelationshipType } from "../hooks/useGraph";
import type { GraphNode } from "../hooks/useGraph";

interface Props {
  open: boolean;
  onClose: () => void;
  nodes: GraphNode[];
  onAdd: (
    fromNodeId: string,
    toNodeId: string,
    type: RelationshipType,
    confidence: number,
    salience: number,
  ) => Promise<void>;
}

export function AddEdgeDialog({ open, onClose, nodes, onAdd }: Props) {
  const [fromNodeId, setFromNodeId] = useState("");
  const [toNodeId, setToNodeId] = useState("");
  const [relType, setRelType] = useState<RelationshipType>(
    RelationshipType.association,
  );
  const [confidence, setConfidence] = useState([0.7]);
  const [salience, setSalience] = useState([0.5]);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!fromNodeId || !toNodeId || fromNodeId === toNodeId) return;
    setLoading(true);
    try {
      await onAdd(fromNodeId, toNodeId, relType, confidence[0], salience[0]);
      setFromNodeId("");
      setToNodeId("");
      setRelType(RelationshipType.association);
      setConfidence([0.7]);
      setSalience([0.5]);
      onClose();
    } finally {
      setLoading(false);
    }
  }

  const isValid = fromNodeId && toNodeId && fromNodeId !== toNodeId;

  return (
    <Dialog open={open} onOpenChange={(o) => !o && onClose()}>
      <DialogContent
        className="bg-card border-border"
        data-ocid="add_edge.dialog"
      >
        <DialogHeader>
          <DialogTitle className="font-display">Add Edge</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          <div className="flex flex-col gap-1.5">
            <Label>From Node</Label>
            <Select value={fromNodeId} onValueChange={setFromNodeId}>
              <SelectTrigger
                className="bg-background"
                data-ocid="add_edge.from_select"
              >
                <SelectValue placeholder="Select source node..." />
              </SelectTrigger>
              <SelectContent>
                {nodes.map((n) => (
                  <SelectItem key={n.id} value={n.id}>
                    {n.labelText}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="flex flex-col gap-1.5">
            <Label>To Node</Label>
            <Select value={toNodeId} onValueChange={setToNodeId}>
              <SelectTrigger
                className="bg-background"
                data-ocid="add_edge.to_select"
              >
                <SelectValue placeholder="Select target node..." />
              </SelectTrigger>
              <SelectContent>
                {nodes.map((n) => (
                  <SelectItem
                    key={n.id}
                    value={n.id}
                    disabled={n.id === fromNodeId}
                  >
                    {n.labelText}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="flex flex-col gap-1.5">
            <Label>Relationship Type</Label>
            <Select
              value={relType}
              onValueChange={(v) => setRelType(v as RelationshipType)}
            >
              <SelectTrigger
                className="bg-background"
                data-ocid="add_edge.type_select"
              >
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value={RelationshipType.association}>
                  Association
                </SelectItem>
                <SelectItem value={RelationshipType.causation}>
                  Causation
                </SelectItem>
                <SelectItem value={RelationshipType.sequence}>
                  Sequence
                </SelectItem>
              </SelectContent>
            </Select>
          </div>
          <div className="flex flex-col gap-2">
            <Label>
              Confidence:{" "}
              <span className="text-primary">{confidence[0].toFixed(2)}</span>
            </Label>
            <Slider
              min={0}
              max={1}
              step={0.05}
              value={confidence}
              onValueChange={setConfidence}
              data-ocid="add_edge.confidence_slider"
            />
          </div>
          <div className="flex flex-col gap-2">
            <Label>
              Salience:{" "}
              <span className="text-primary">{salience[0].toFixed(2)}</span>
            </Label>
            <Slider
              min={0}
              max={1}
              step={0.05}
              value={salience}
              onValueChange={setSalience}
              data-ocid="add_edge.salience_slider"
            />
          </div>
          <DialogFooter>
            <Button
              type="button"
              variant="ghost"
              onClick={onClose}
              data-ocid="add_edge.cancel_button"
            >
              Cancel
            </Button>
            <Button
              type="submit"
              disabled={loading || !isValid}
              data-ocid="add_edge.submit_button"
            >
              {loading && <Loader2 className="w-3.5 h-3.5 mr-2 animate-spin" />}
              Add Edge
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
