// @ts-nocheck
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { cn } from "@/lib/utils";
import { ArrowLeft, Folder, FolderOpen, Plus, Trash2 } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";
import { NodeType, RelationshipType } from "../backend.d";
import {
  useAllSessions,
  useCreateNode,
  useDeleteNode,
  useFullGraph,
} from "../hooks/useQueries";

const FOLDER_PREFIX = "[FOLDER] ";

export function FoldersSection() {
  const [activeFolderId, setActiveFolderId] = useState<string | null>(null);
  const [newFolderName, setNewFolderName] = useState("");
  const [showNewFolder, setShowNewFolder] = useState(false);

  const { data: graphData, isLoading } = useFullGraph();
  const { data: sessions = [] } = useAllSessions();
  const createNode = useCreateNode();
  const deleteNode = useDeleteNode();

  const nodes = graphData?.nodes ?? [];
  const edges = graphData?.edges ?? [];
  const folders = nodes.filter(
    (n) =>
      n.nodeType === NodeType.concept && n.labelText.startsWith(FOLDER_PREFIX),
  );

  const activeFolder = folders.find((f) => f.id === activeFolderId);

  // Get items tagged to folder via edges
  const folderItemIds = activeFolderId
    ? edges
        .filter(
          (e) =>
            e.fromNodeId === activeFolderId || e.toNodeId === activeFolderId,
        )
        .map((e) =>
          e.fromNodeId === activeFolderId ? e.toNodeId : e.fromNodeId,
        )
    : [];

  const folderSessions = sessions.filter((s) => folderItemIds.includes(s.id));

  const getItemCount = (folderId: string) => {
    return edges.filter(
      (e) => e.fromNodeId === folderId || e.toNodeId === folderId,
    ).length;
  };

  const handleCreateFolder = async () => {
    if (!newFolderName.trim()) return;
    const id = crypto.randomUUID();
    await createNode.mutateAsync({
      id,
      labelText: `${FOLDER_PREFIX}${newFolderName.trim()}`,
      nodeType: NodeType.concept,
    });
    setNewFolderName("");
    setShowNewFolder(false);
    toast.success("Folder created");
  };

  const handleDeleteFolder = async (id: string) => {
    await deleteNode.mutateAsync(id);
    if (activeFolderId === id) setActiveFolderId(null);
    toast.success("Folder deleted");
  };

  return (
    <div className="flex flex-col h-full" data-ocid="folders.section">
      {/* Header */}
      <div className="flex items-center justify-between px-3 py-2 border-b border-border shrink-0">
        <div className="flex items-center gap-2">
          {activeFolderId && (
            <Button
              variant="ghost"
              size="icon"
              className="w-6 h-6 text-muted-foreground hover:text-foreground"
              onClick={() => setActiveFolderId(null)}
              data-ocid="folders.back.button"
            >
              <ArrowLeft className="w-3.5 h-3.5" />
            </Button>
          )}
          <span className="font-mono text-xs text-muted-foreground tracking-widest uppercase">
            {activeFolder
              ? activeFolder.labelText.replace(FOLDER_PREFIX, "")
              : "Folders"}
          </span>
        </div>
        {!activeFolderId && (
          <Button
            variant="ghost"
            size="icon"
            className="w-6 h-6 text-muted-foreground hover:text-primary"
            onClick={() => setShowNewFolder(true)}
            data-ocid="folders.new_folder.button"
          >
            <Plus className="w-3.5 h-3.5" />
          </Button>
        )}
      </div>

      {/* New folder input */}
      {showNewFolder && (
        <div className="flex items-center gap-2 px-3 py-2 border-b border-border">
          <Input
            autoFocus
            value={newFolderName}
            onChange={(e) => setNewFolderName(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter") handleCreateFolder();
              if (e.key === "Escape") setShowNewFolder(false);
            }}
            placeholder="Folder name..."
            className="h-7 text-xs bg-muted border-0 font-mono flex-1"
            data-ocid="folders.new_folder.input"
          />
          <Button
            size="sm"
            className="h-7 text-xs"
            onClick={handleCreateFolder}
            disabled={!newFolderName.trim() || createNode.isPending}
            data-ocid="folders.create.button"
          >
            Create
          </Button>
          <Button
            variant="ghost"
            size="sm"
            className="h-7 text-xs"
            onClick={() => setShowNewFolder(false)}
            data-ocid="folders.cancel.button"
          >
            Cancel
          </Button>
        </div>
      )}

      {/* Content */}
      <div className="flex-1 overflow-auto p-3">
        {isLoading ? (
          <div
            className="grid grid-cols-2 gap-2"
            data-ocid="folders.grid.loading_state"
          >
            {[1, 2, 3, 4].map((i) => (
              <Skeleton key={i} className="h-20 bg-muted" />
            ))}
          </div>
        ) : !activeFolderId ? (
          folders.length === 0 ? (
            <div
              className="flex flex-col items-center justify-center h-48 text-muted-foreground gap-3"
              data-ocid="folders.grid.empty_state"
            >
              <Folder className="w-8 h-8 opacity-30" />
              <p className="text-sm">No folders yet</p>
              <Button
                size="sm"
                variant="outline"
                onClick={() => setShowNewFolder(true)}
                data-ocid="folders.new_folder_empty.button"
              >
                <Plus className="w-3.5 h-3.5 mr-1.5" />
                New Folder
              </Button>
            </div>
          ) : (
            <div className="grid grid-cols-2 gap-2">
              {folders.map((folder, i) => (
                <div
                  key={folder.id}
                  // biome-ignore lint/a11y/useSemanticElements: div needed to avoid nested button
                  role="button"
                  tabIndex={0}
                  className="border border-border bg-card p-3 group cursor-pointer hover:border-primary/30 transition-colors relative"
                  onClick={() => setActiveFolderId(folder.id)}
                  onKeyDown={(e) =>
                    e.key === "Enter" && setActiveFolderId(folder.id)
                  }
                  data-ocid={`folders.item.${i + 1}`}
                >
                  <button
                    type="button"
                    onClick={(e) => {
                      e.stopPropagation();
                      handleDeleteFolder(folder.id);
                    }}
                    className="absolute top-2 right-2 opacity-0 group-hover:opacity-100 text-muted-foreground hover:text-destructive transition-opacity"
                    data-ocid={`folders.delete_button.${i + 1}`}
                  >
                    <Trash2 className="w-3 h-3" />
                  </button>
                  <FolderOpen className="w-5 h-5 text-primary/60 mb-2" />
                  <div className="text-sm font-medium text-foreground truncate">
                    {folder.labelText.replace(FOLDER_PREFIX, "")}
                  </div>
                  <div className="text-xs text-muted-foreground font-mono mt-0.5">
                    {getItemCount(folder.id)} items
                  </div>
                </div>
              ))}
            </div>
          )
        ) : (
          // Folder contents
          <div className="space-y-1">
            {folderSessions.length === 0 ? (
              <div
                className="flex flex-col items-center justify-center h-32 text-muted-foreground text-sm gap-2"
                data-ocid="folders.contents.empty_state"
              >
                <p>No items in this folder</p>
              </div>
            ) : (
              folderSessions.map((s, i) => (
                <div
                  key={s.id}
                  className="flex items-center gap-2 px-2.5 py-2 border border-border hover:bg-muted transition-colors"
                  data-ocid={`folders.contents.item.${i + 1}`}
                >
                  <Folder className="w-3.5 h-3.5 text-muted-foreground shrink-0" />
                  <span className="text-sm text-foreground truncate">
                    {s.title}
                  </span>
                </div>
              ))
            )}
          </div>
        )}
      </div>
    </div>
  );
}
