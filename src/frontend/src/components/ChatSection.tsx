// @ts-nocheck
import { Button } from "@/components/ui/button";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Skeleton } from "@/components/ui/skeleton";
import { cn } from "@/lib/utils";
import {
  ChevronLeft,
  Edit2,
  MessageSquare,
  Plus,
  Send,
  Trash2,
} from "lucide-react";
import { AnimatePresence, motion } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { toast } from "sonner";
import { MessageRole, NodeType, RelationshipType } from "../backend.d";
import {
  useAddMessage,
  useAllSessions,
  useCreateEdge,
  useCreateNode,
  useCreateSession,
  useDeleteSession,
  useFullGraph,
  useIncrementEdgeReinforcement,
  useSessionMessages,
} from "../hooks/useQueries";
import type { MemoryEdge, MemoryNode, SkillMode } from "../lib/aiSimulator";
import { generateAIResponse } from "../lib/aiSimulator";
import { conceptToLabel, extractConcepts } from "../lib/memoryExtractor";

interface Props {
  userName?: string;
}

const SKILL_MODES: { id: SkillMode; label: string }[] = [
  { id: "general", label: "General" },
  { id: "summarize", label: "Summarize" },
  { id: "tasks", label: "Tasks" },
  { id: "patterns", label: "Patterns" },
  { id: "writing", label: "Writing" },
  { id: "research", label: "Research" },
  { id: "strategy", label: "Strategy" },
];

function formatTime(ts: bigint) {
  const d = new Date(Number(ts / 1_000_000n));
  return d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
}

export function ChatSection({ userName }: Props) {
  const [activeSessionId, setActiveSessionId] = useState<string | null>(null);
  // On mobile, whether we're viewing the chat panel (true) or sessions list (false)
  const [mobileChatView, setMobileChatView] = useState(false);
  const [input, setInput] = useState("");
  const [isAIThinking, setIsAIThinking] = useState(false);
  const [editingTitle, setEditingTitle] = useState(false);
  const [titleInput, setTitleInput] = useState("");
  const [autoSessionCreated, setAutoSessionCreated] = useState(false);
  const [skillMode, setSkillMode] = useState<SkillMode>("general");
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);

  const { data: sessions = [], isLoading: sessionsLoading } = useAllSessions();
  const { data: messages = [], isLoading: messagesLoading } =
    useSessionMessages(activeSessionId);
  const { data: graphData } = useFullGraph();

  const createSession = useCreateSession();
  const deleteSession = useDeleteSession();
  const addMessage = useAddMessage();
  const createNode = useCreateNode();
  const createEdge = useCreateEdge();
  const incrementEdge = useIncrementEdgeReinforcement();

  const chatSessions = sessions.filter((s) => !s.title.startsWith("[NOTE] "));

  const activeSession = chatSessions.find((s) => s.id === activeSessionId);

  // Auto-select first session on desktop
  useEffect(() => {
    if (chatSessions.length > 0 && !activeSessionId) {
      setActiveSessionId(chatSessions[0].id);
    }
  }, [chatSessions, activeSessionId]);

  // Auto-create session if none exist
  // biome-ignore lint/correctness/useExhaustiveDependencies: intentional
  useEffect(() => {
    if (
      !sessionsLoading &&
      chatSessions.length === 0 &&
      !autoSessionCreated &&
      !createSession.isPending
    ) {
      setAutoSessionCreated(true);
      const id = crypto.randomUUID();
      const title = `Session ${new Date().toLocaleString([], { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" })}`;
      createSession.mutateAsync({ id, title }).then(() => {
        setActiveSessionId(id);
        setMobileChatView(true);
      });
    }
  }, [
    sessionsLoading,
    chatSessions.length,
    autoSessionCreated,
    createSession.isPending,
  ]);

  // biome-ignore lint/correctness/useExhaustiveDependencies: intentional
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, isAIThinking]);

  const handleNewSession = async () => {
    const id = crypto.randomUUID();
    const title = `Session ${new Date().toLocaleString([], { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" })}`;
    await createSession.mutateAsync({ id, title });
    setActiveSessionId(id);
    setMobileChatView(true);
  };

  const handleSelectSession = (id: string) => {
    setActiveSessionId(id);
    setMobileChatView(true);
  };

  const handleDeleteSession = async (id: string, e: React.MouseEvent) => {
    e.stopPropagation();
    await deleteSession.mutateAsync(id);
    if (activeSessionId === id) {
      const next = chatSessions.find((s) => s.id !== id);
      setActiveSessionId(next?.id ?? null);
      if (!next) setMobileChatView(false);
    }
  };

  const handleSendMessage = async () => {
    const content = input.trim();
    if (!content || !activeSessionId || isAIThinking) return;
    setInput("");

    const userMsgId = crypto.randomUUID();
    await addMessage.mutateAsync({
      id: userMsgId,
      sessionId: activeSessionId,
      role: MessageRole.user,
      content,
    });

    setIsAIThinking(true);

    await new Promise((r) => setTimeout(r, 800 + Math.random() * 600));

    const aiContent = generateAIResponse(content, {
      priorMessages: messages,
      userName,
      memoryNodes: (graphData?.nodes ?? []) as MemoryNode[],
      memoryEdges: (graphData?.edges ?? []) as MemoryEdge[],
      skillMode,
    });

    const aiMsgId = crypto.randomUUID();
    await addMessage.mutateAsync({
      id: aiMsgId,
      sessionId: activeSessionId,
      role: MessageRole.ai,
      content: aiContent,
    });

    setIsAIThinking(false);

    void extractAndStoreMemory(content, activeSessionId);
  };

  const extractAndStoreMemory = async (text: string, sessionId: string) => {
    try {
      const concepts = extractConcepts(text, 3);
      if (concepts.length === 0) return;

      const nodes = graphData?.nodes ?? [];
      const edges = graphData?.edges ?? [];
      const newNodeIds: string[] = [];

      for (const concept of concepts) {
        const label = conceptToLabel(concept);
        const existing = nodes.find(
          (n) => n.labelText.toLowerCase() === label.toLowerCase(),
        );

        let nodeId: string;
        if (existing) {
          nodeId = existing.id;
          const relatedEdge = edges.find(
            (e) => e.fromNodeId === sessionId || e.toNodeId === existing.id,
          );
          if (relatedEdge) {
            await incrementEdge.mutateAsync(relatedEdge.id);
          }
        } else {
          nodeId = crypto.randomUUID();
          await createNode.mutateAsync({
            id: nodeId,
            labelText: label,
            nodeType: NodeType.memory,
          });
        }
        newNodeIds.push(nodeId);
      }

      for (let i = 0; i < newNodeIds.length - 1; i++) {
        const edgeId = crypto.randomUUID();
        await createEdge.mutateAsync({
          id: edgeId,
          fromNodeId: newNodeIds[i],
          toNodeId: newNodeIds[i + 1],
          relationshipType: RelationshipType.association,
          confidenceScore: 0.7,
          salienceScore: 0.5,
        });
      }
    } catch {
      // Silent — memory extraction is non-critical
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      handleSendMessage();
    }
  };

  // ── Session List Panel ────────────────────────────────────────────────────
  const SessionListPanel = (
    <div className="flex flex-col h-full" data-ocid="chat.sessions.panel">
      <div className="flex items-center justify-between px-3 py-2 border-b border-border shrink-0">
        <span className="font-mono text-xs text-muted-foreground tracking-widest uppercase">
          Sessions
        </span>
        <Button
          variant="ghost"
          size="icon"
          className="w-7 h-7 text-muted-foreground hover:text-primary"
          onClick={handleNewSession}
          disabled={createSession.isPending}
          data-ocid="chat.new_session.button"
        >
          <Plus className="w-4 h-4" />
        </Button>
      </div>
      <ScrollArea className="flex-1">
        {sessionsLoading ? (
          <div
            className="p-2 space-y-1"
            data-ocid="chat.sessions.loading_state"
          >
            {[1, 2, 3].map((i) => (
              <Skeleton key={i} className="h-10 w-full bg-muted" />
            ))}
          </div>
        ) : chatSessions.length === 0 ? (
          <div
            className="p-6 flex flex-col items-center gap-4 text-muted-foreground"
            data-ocid="chat.sessions.empty_state"
          >
            <MessageSquare className="w-8 h-8 opacity-30" />
            <p className="text-xs text-center">
              {createSession.isPending
                ? "Creating session..."
                : "No sessions yet"}
            </p>
            <Button
              size="sm"
              variant="outline"
              onClick={handleNewSession}
              disabled={createSession.isPending}
              data-ocid="chat.new_session_empty.button"
              className="font-mono text-xs tracking-wider"
            >
              <Plus className="w-3.5 h-3.5 mr-1.5" />
              NEW SESSION
            </Button>
          </div>
        ) : (
          <div className="p-1.5 space-y-0.5">
            {chatSessions.map((s, i) => (
              <button
                type="button"
                key={s.id}
                onClick={() => handleSelectSession(s.id)}
                className={cn(
                  "w-full text-left px-3 py-3 text-xs rounded-sm flex items-center justify-between gap-1 group transition-colors",
                  activeSessionId === s.id
                    ? "bg-primary/10 text-primary"
                    : "text-muted-foreground hover:bg-muted hover:text-foreground",
                )}
                data-ocid={`chat.session.item.${i + 1}`}
              >
                <div className="flex items-center gap-2 min-w-0">
                  <MessageSquare className="w-3.5 h-3.5 shrink-0" />
                  <span className="truncate">{s.title}</span>
                </div>
                <button
                  type="button"
                  onClick={(e) => handleDeleteSession(s.id, e)}
                  className="opacity-0 group-hover:opacity-100 text-muted-foreground hover:text-destructive transition-opacity shrink-0 p-1"
                  data-ocid={`chat.session.delete_button.${i + 1}`}
                >
                  <Trash2 className="w-3.5 h-3.5" />
                </button>
              </button>
            ))}
          </div>
        )}
      </ScrollArea>
    </div>
  );

  // ── Skill mode selector ───────────────────────────────────────────────────
  const SkillModeBar = (
    <div
      className="flex gap-1 overflow-x-auto scrollbar-none px-3 py-2 border-b border-border shrink-0"
      data-ocid="chat.skill_mode.tab"
    >
      {SKILL_MODES.map((mode) => (
        <button
          key={mode.id}
          type="button"
          onClick={() => setSkillMode(mode.id)}
          className={cn(
            "shrink-0 px-2.5 py-1 font-mono text-[10px] tracking-widest uppercase transition-colors border",
            skillMode === mode.id
              ? "border-primary text-primary bg-primary/10"
              : "border-border text-muted-foreground hover:border-muted-foreground hover:text-foreground bg-transparent",
          )}
          data-ocid={`chat.skill.${mode.id}.toggle`}
        >
          {mode.label}
        </button>
      ))}
    </div>
  );

  // ── Chat Panel ────────────────────────────────────────────────────────────
  const ChatPanel = (
    <div className="flex flex-col h-full" data-ocid="chat.messages.panel">
      {/* Header */}
      <div className="flex items-center justify-between px-4 py-2 border-b border-border shrink-0">
        <div className="flex items-center gap-2 min-w-0 flex-1">
          {/* Back button — mobile only */}
          <button
            type="button"
            onClick={() => setMobileChatView(false)}
            className="md:hidden text-muted-foreground hover:text-primary p-1 -ml-1 transition-colors"
            data-ocid="chat.back.button"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>
          {editingTitle ? (
            <input
              value={titleInput}
              onChange={(e) => setTitleInput(e.target.value)}
              onBlur={() => setEditingTitle(false)}
              onKeyDown={(e) => e.key === "Enter" && setEditingTitle(false)}
              className="bg-transparent text-sm font-medium text-foreground border-b border-primary outline-none flex-1"
              data-ocid="chat.title.input"
            />
          ) : (
            <button
              type="button"
              onClick={() => {
                setTitleInput(activeSession?.title ?? "");
                setEditingTitle(true);
              }}
              className="text-sm font-medium text-foreground hover:text-primary flex items-center gap-1.5 transition-colors group truncate"
              data-ocid="chat.title.edit_button"
            >
              <span className="truncate">
                {activeSession?.title ?? "Select a session"}
              </span>
              {activeSession && (
                <Edit2 className="w-3 h-3 text-muted-foreground opacity-0 group-hover:opacity-100 transition-opacity shrink-0" />
              )}
            </button>
          )}
        </div>
        <span className="font-mono text-xs text-muted-foreground shrink-0 ml-2">
          {messages.length} msg{messages.length !== 1 ? "s" : ""}
        </span>
      </div>

      {/* Skill mode selector */}
      {SkillModeBar}

      {/* Messages */}
      <ScrollArea className="flex-1">
        <div className="p-4 space-y-4">
          {!activeSessionId ? (
            <div
              className="flex flex-col items-center justify-center h-48 text-muted-foreground gap-3"
              data-ocid="chat.messages.empty_state"
            >
              <MessageSquare className="w-8 h-8 opacity-30" />
              <p className="text-sm">Select or create a session to begin</p>
            </div>
          ) : messagesLoading ? (
            <div className="space-y-4" data-ocid="chat.messages.loading_state">
              {[1, 2].map((i) => (
                <div
                  key={i}
                  className={cn(
                    "flex",
                    i % 2 === 0 ? "justify-end" : "justify-start",
                  )}
                >
                  <Skeleton className="h-16 w-64 bg-muted" />
                </div>
              ))}
            </div>
          ) : messages.length === 0 ? (
            <div
              className="flex flex-col items-center justify-center h-48 text-muted-foreground gap-2"
              data-ocid="chat.messages.empty_state"
            >
              <MessageSquare className="w-6 h-6 opacity-30" />
              <p className="text-xs font-mono">Start the conversation</p>
            </div>
          ) : (
            <AnimatePresence initial={false}>
              {messages.map((msg, idx) => (
                <motion.div
                  key={msg.id}
                  initial={{ opacity: 0, y: 8 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.2 }}
                  className={cn(
                    "flex",
                    msg.role === MessageRole.user
                      ? "justify-end"
                      : "justify-start",
                  )}
                  data-ocid={`chat.message.item.${idx + 1}`}
                >
                  <div
                    className={cn(
                      "max-w-[80%] px-3 py-2.5 text-sm",
                      msg.role === MessageRole.user
                        ? "bg-primary/15 border border-primary/20 text-foreground"
                        : "bg-muted border border-border text-foreground font-mono",
                    )}
                  >
                    <p className="whitespace-pre-wrap leading-relaxed">
                      {msg.content}
                    </p>
                    <span className="text-xs text-muted-foreground mt-1 block">
                      {formatTime(msg.timestamp)}
                    </span>
                  </div>
                </motion.div>
              ))}
              {isAIThinking && (
                <motion.div
                  initial={{ opacity: 0, y: 8 }}
                  animate={{ opacity: 1, y: 0 }}
                  className="flex justify-start"
                  data-ocid="chat.ai.loading_state"
                >
                  <div className="bg-muted border border-border px-3 py-2.5">
                    <div className="flex gap-1 items-center">
                      <span className="w-1.5 h-1.5 bg-primary rounded-full animate-bounce [animation-delay:0ms]" />
                      <span className="w-1.5 h-1.5 bg-primary rounded-full animate-bounce [animation-delay:150ms]" />
                      <span className="w-1.5 h-1.5 bg-primary rounded-full animate-bounce [animation-delay:300ms]" />
                    </div>
                  </div>
                </motion.div>
              )}
            </AnimatePresence>
          )}
          <div ref={messagesEndRef} />
        </div>
      </ScrollArea>

      {/* Input */}
      <div className="border-t border-border p-3 shrink-0">
        <div className="flex gap-2 items-end">
          <textarea
            ref={inputRef}
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder={
              activeSessionId ? "Type a message..." : "Select a session first"
            }
            disabled={!activeSessionId || isAIThinking}
            rows={1}
            className="flex-1 bg-muted border border-border text-foreground text-sm px-3 py-2 resize-none outline-none focus:border-primary/50 placeholder:text-muted-foreground font-mono transition-colors min-h-[44px] max-h-32"
            style={{ fieldSizing: "content" } as React.CSSProperties}
            data-ocid="chat.message.input"
          />
          <Button
            size="icon"
            onClick={handleSendMessage}
            disabled={!input.trim() || !activeSessionId || isAIThinking}
            className="w-11 h-11 shrink-0"
            data-ocid="chat.send.button"
          >
            <Send className="w-4 h-4" />
          </Button>
        </div>
      </div>
    </div>
  );

  return (
    <div className="flex h-full overflow-hidden" data-ocid="chat.section">
      {/* ── Desktop: two-column layout ── */}
      <div className="hidden md:flex h-full w-full">
        {/* Session list */}
        <div className="w-56 border-r border-border shrink-0 flex flex-col">
          {SessionListPanel}
        </div>
        {/* Chat area */}
        <div className="flex-1 min-w-0 flex flex-col">{ChatPanel}</div>
      </div>

      {/* ── Mobile: single-panel with slide ── */}
      <div className="flex md:hidden h-full w-full relative overflow-hidden">
        <AnimatePresence initial={false} mode="wait">
          {!mobileChatView ? (
            <motion.div
              key="sessions"
              initial={{ x: "-100%" }}
              animate={{ x: 0 }}
              exit={{ x: "-100%" }}
              transition={{ type: "tween", duration: 0.22 }}
              className="absolute inset-0 flex flex-col bg-background"
            >
              {SessionListPanel}
            </motion.div>
          ) : (
            <motion.div
              key="chat"
              initial={{ x: "100%" }}
              animate={{ x: 0 }}
              exit={{ x: "100%" }}
              transition={{ type: "tween", duration: 0.22 }}
              className="absolute inset-0 flex flex-col bg-background"
            >
              {ChatPanel}
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </div>
  );
}
