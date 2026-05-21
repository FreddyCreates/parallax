// @ts-nocheck
import { Button } from "@/components/ui/button";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Skeleton } from "@/components/ui/skeleton";
import { cn } from "@/lib/utils";
import { FileText, Plus, Save, Trash2 } from "lucide-react";
import { useEffect, useState } from "react";
import { toast } from "sonner";
import { MessageRole } from "../backend.d";
import {
  useAddMessage,
  useAllSessions,
  useCreateSession,
  useDeleteSession,
  useSessionMessages,
} from "../hooks/useQueries";

const NOTE_PREFIX = "[NOTE] ";

function formatDate(ts: bigint) {
  const d = new Date(Number(ts / 1_000_000n));
  return d.toLocaleDateString([], {
    month: "short",
    day: "numeric",
    year: "2-digit",
  });
}

export function NotesSection() {
  const [activeNoteId, setActiveNoteId] = useState<string | null>(null);
  const [noteTitle, setNoteTitle] = useState("");
  const [noteContent, setNoteContent] = useState("");
  const [isDirty, setIsDirty] = useState(false);

  const { data: sessions = [], isLoading } = useAllSessions();
  const notes = sessions.filter((s) => s.title.startsWith(NOTE_PREFIX));
  const { data: messages = [] } = useSessionMessages(activeNoteId);

  const createSession = useCreateSession();
  const deleteSession = useDeleteSession();
  const addMessage = useAddMessage();

  const activeNote = notes.find((n) => n.id === activeNoteId);

  // biome-ignore lint/correctness/useExhaustiveDependencies: stable setters
  useEffect(() => {
    if (messages.length > 0) {
      setNoteContent(messages[messages.length - 1].content);
      setIsDirty(false);
    } else {
      setNoteContent("");
    }
  }, [messages, activeNoteId]);

  useEffect(() => {
    if (activeNote) {
      setNoteTitle(activeNote.title.replace(NOTE_PREFIX, ""));
    }
  }, [activeNote]);

  const handleNewNote = async () => {
    const id = crypto.randomUUID();
    const title = `${NOTE_PREFIX}Untitled ${new Date().toLocaleDateString([], { month: "short", day: "numeric" })}`;
    await createSession.mutateAsync({ id, title });
    setActiveNoteId(id);
    setNoteTitle("Untitled");
    setNoteContent("");
    setIsDirty(false);
  };

  const handleSave = async () => {
    if (!activeNoteId || !noteContent.trim()) return;
    const msgId = crypto.randomUUID();
    await addMessage.mutateAsync({
      id: msgId,
      sessionId: activeNoteId,
      role: MessageRole.user,
      content: noteContent,
    });
    setIsDirty(false);
    toast.success("Note saved");
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if ((e.ctrlKey || e.metaKey) && e.key === "s") {
      e.preventDefault();
      handleSave();
    }
  };

  return (
    <div className="flex h-full" data-ocid="notes.section">
      {/* Notes list */}
      <div className="w-52 border-r border-border flex flex-col shrink-0">
        <div className="flex items-center justify-between px-3 py-2 border-b border-border">
          <span className="font-mono text-xs text-muted-foreground tracking-widest uppercase">
            Notes
          </span>
          <Button
            variant="ghost"
            size="icon"
            className="w-6 h-6 text-muted-foreground hover:text-primary"
            onClick={handleNewNote}
            disabled={createSession.isPending}
            data-ocid="notes.new_note.button"
          >
            <Plus className="w-3.5 h-3.5" />
          </Button>
        </div>
        <ScrollArea className="flex-1">
          {isLoading ? (
            <div className="p-2 space-y-1" data-ocid="notes.list.loading_state">
              {[1, 2, 3].map((i) => (
                <Skeleton key={i} className="h-10 w-full bg-muted" />
              ))}
            </div>
          ) : notes.length === 0 ? (
            <div
              className="p-4 text-center text-muted-foreground text-xs"
              data-ocid="notes.list.empty_state"
            >
              No notes yet
            </div>
          ) : (
            <div className="p-1.5 space-y-0.5">
              {notes.map((note, i) => (
                <button
                  type="button"
                  key={note.id}
                  onClick={() => setActiveNoteId(note.id)}
                  className={cn(
                    "w-full text-left px-2.5 py-2 text-xs rounded-sm flex items-start justify-between gap-1 group transition-colors",
                    activeNoteId === note.id
                      ? "bg-primary/10 text-primary"
                      : "text-muted-foreground hover:bg-muted hover:text-foreground",
                  )}
                  data-ocid={`notes.item.${i + 1}`}
                >
                  <div className="flex items-start gap-1.5 min-w-0">
                    <FileText className="w-3 h-3 shrink-0 mt-0.5" />
                    <div className="min-w-0">
                      <div className="truncate">
                        {note.title.replace(NOTE_PREFIX, "")}
                      </div>
                      <div
                        className="text-muted-foreground font-mono"
                        style={{ fontSize: "10px" }}
                      >
                        {formatDate(note.createdAt)}
                      </div>
                    </div>
                  </div>
                  <button
                    type="button"
                    onClick={(e) => {
                      e.stopPropagation();
                      deleteSession.mutateAsync(note.id).then(() => {
                        if (activeNoteId === note.id) setActiveNoteId(null);
                      });
                    }}
                    className="opacity-0 group-hover:opacity-100 text-muted-foreground hover:text-destructive transition-opacity shrink-0 mt-0.5"
                    data-ocid={`notes.delete_button.${i + 1}`}
                  >
                    <Trash2 className="w-3 h-3" />
                  </button>
                </button>
              ))}
            </div>
          )}
        </ScrollArea>
      </div>

      {/* Editor */}
      <div className="flex-1 flex flex-col min-w-0">
        {!activeNoteId ? (
          <div
            className="flex flex-col items-center justify-center h-full text-muted-foreground gap-3"
            data-ocid="notes.editor.empty_state"
          >
            <FileText className="w-8 h-8 opacity-30" />
            <p className="text-sm">Select or create a note</p>
            <Button
              size="sm"
              variant="outline"
              onClick={handleNewNote}
              data-ocid="notes.new_note_empty.button"
            >
              <Plus className="w-3.5 h-3.5 mr-1.5" />
              New Note
            </Button>
          </div>
        ) : (
          <>
            <div className="flex items-center gap-2 px-4 py-2 border-b border-border shrink-0">
              <input
                value={noteTitle}
                onChange={(e) => setNoteTitle(e.target.value)}
                className="flex-1 bg-transparent text-sm font-medium text-foreground outline-none"
                placeholder="Note title..."
                data-ocid="notes.title.input"
              />
              <Button
                variant="ghost"
                size="sm"
                onClick={handleSave}
                disabled={!isDirty || addMessage.isPending}
                className={cn(
                  "text-xs gap-1.5 h-7",
                  isDirty ? "text-primary" : "text-muted-foreground",
                )}
                data-ocid="notes.save.button"
              >
                <Save className="w-3.5 h-3.5" />
                {addMessage.isPending
                  ? "Saving..."
                  : isDirty
                    ? "Save"
                    : "Saved"}
              </Button>
            </div>
            <textarea
              value={noteContent}
              onChange={(e) => {
                setNoteContent(e.target.value);
                setIsDirty(true);
              }}
              onKeyDown={handleKeyDown}
              onBlur={handleSave}
              placeholder="Start writing... (Ctrl+S to save)"
              className="flex-1 bg-transparent text-sm text-foreground outline-none resize-none p-4 font-mono leading-relaxed placeholder:text-muted-foreground"
              data-ocid="notes.content.textarea"
            />
          </>
        )}
      </div>
    </div>
  );
}
