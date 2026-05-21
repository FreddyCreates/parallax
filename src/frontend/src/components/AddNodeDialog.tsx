import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Loader2 } from "lucide-react";
import { useState } from "react";
import { NodeType } from "../hooks/useGraph";

interface Props {
  open: boolean;
  onClose: () => void;
  onAdd: (label: string, type: NodeType) => Promise<void>;
}

export function AddNodeDialog({ open, onClose, onAdd }: Props) {
  const [label, setLabel] = useState("");
  const [nodeType, setNodeType] = useState<NodeType>(NodeType.concept);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!label.trim()) return;
    setLoading(true);
    try {
      await onAdd(label.trim(), nodeType);
      setLabel("");
      setNodeType(NodeType.concept);
      onClose();
    } finally {
      setLoading(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={(o) => !o && onClose()}>
      <DialogContent
        className="bg-card border-border"
        data-ocid="add_node.dialog"
      >
        <DialogHeader>
          <DialogTitle className="font-display">Add Node</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="node-label">Label</Label>
            <Input
              id="node-label"
              value={label}
              onChange={(e) => setLabel(e.target.value)}
              placeholder="Enter node label..."
              autoFocus
              data-ocid="add_node.input"
            />
          </div>
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="node-type">Type</Label>
            <Select
              value={nodeType}
              onValueChange={(v) => setNodeType(v as NodeType)}
            >
              <SelectTrigger
                id="node-type"
                className="bg-background"
                data-ocid="add_node.select"
              >
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value={NodeType.concept}>Concept</SelectItem>
                <SelectItem value={NodeType.memory}>Memory</SelectItem>
                <SelectItem value={NodeType.knowledge}>Knowledge</SelectItem>
                <SelectItem value={NodeType.aiSystem}>AI System</SelectItem>
              </SelectContent>
            </Select>
          </div>
          <DialogFooter>
            <Button
              type="button"
              variant="ghost"
              onClick={onClose}
              data-ocid="add_node.cancel_button"
            >
              Cancel
            </Button>
            <Button
              type="submit"
              disabled={loading || !label.trim()}
              data-ocid="add_node.submit_button"
            >
              {loading && <Loader2 className="w-3.5 h-3.5 mr-2 animate-spin" />}
              Add Node
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
