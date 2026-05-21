// @ts-nocheck
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Input } from "@/components/ui/input";
import { ScrollArea } from "@/components/ui/scroll-area";
import {
  Brain,
  ChevronDown,
  Loader2,
  MessageSquare,
  Plus,
  Search,
  Send,
  Trash2,
} from "lucide-react";
import { AnimatePresence, motion } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { toast } from "sonner";
import { MessageRole } from "../backend";
import type { Message } from "../hooks/useChat";
import { useChat } from "../hooks/useChat";
import { useGraph } from "../hooks/useGraph";
import { formatTime, truncate } from "../utils/formatting";
import { MemoryInjectionBlock } from "./MemoryInjectionBlock";

function MessageBubble({ message }: { message: Message }) {
  const isUser = message.role === MessageRole.user;
  const isSystem = message.role === MessageRole.aiSystem;

  if (isSystem) {
    return (
      <div className="flex justify-center my-2">
        <span className="text-xs text-muted-foreground bg-muted px-3 py-1 rounded-full">
          {message.content}
        </span>
      </div>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.2 }}
      className={`flex gap-2 ${isUser ? "flex-row-reverse" : "flex-row"}`}
    >
      <div
        className={`shrink-0 w-7 h-7 rounded-full flex items-center justify-center text-xs font-medium ${
          isUser
            ? "bg-secondary/30 text-secondary"
            : "bg-primary/20 text-primary"
        }`}
      >
        {isUser ? "U" : <Brain className="w-3.5 h-3.5" />}
      </div>
      <div
        className={`max-w-[78%] flex flex-col gap-1 ${
          isUser ? "items-end" : "items-start"
        }`}
      >
        <div
          className={`rounded-xl px-3 py-2 text-sm leading-relaxed ${
            isUser
              ? "bg-secondary/20 border border-secondary/20 text-foreground rounded-tr-none"
              : "bg-muted border border-border text-foreground rounded-tl-none"
          }`}
        >
          {message.content}
        </div>
        <span className="text-xs text-muted-foreground/60">
          {formatTime(message.timestamp)}
        </span>
      </div>
    </motion.div>
  );
}

export function ChatPanel() {
  const {
    sessions,
    messages,
    isLoadingSessions,
    isLoadingMessages,
    currentSessionId,
    setCurrentSessionId,
    isSending,
    createSession,
    deleteSession,
    sendMessage,
  } = useChat();

  const { topEdges, nodes } = useGraph();
  const [input, setInput] = useState("");
  const [sessionSearch, setSessionSearch] = useState("");
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);
  const messageCount = messages.length;

  // Auto-scroll to bottom on new messages
  // biome-ignore lint/correctness/useExhaustiveDependencies: scroll on message count change
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messageCount]);

  // Auto-focus input when session changes
  useEffect(() => {
    if (currentSessionId) {
      inputRef.current?.focus();
    }
  }, [currentSessionId]);

  // Auto-resize textarea based on content
  // biome-ignore lint/correctness/useExhaustiveDependencies: resize triggered by input value change
  useEffect(() => {
    const el = inputRef.current;
    if (!el) return;
    el.style.height = "auto";
    el.style.height = `${Math.min(el.scrollHeight, 96)}px`;
  }, [input]);

  // Auto-create a session if none exist after loading
  useEffect(() => {
    if (!isLoadingSessions && sessions.length === 0) {
      createSession().catch(() => {});
    }
  }, [isLoadingSessions, sessions.length, createSession]);

  const filteredSessions = sessionSearch.trim()
    ? sessions.filter((s) =>
        s.title.toLowerCase().includes(sessionSearch.toLowerCase()),
      )
    : sessions;

  const currentSession = sessions.find((s) => s.id === currentSessionId);

  async function handleNewSession() {
    try {
      await createSession();
    } catch {
      toast.error("Failed to create session");
    }
  }

  async function handleDeleteSession(id: string) {
    try {
      await deleteSession(id);
      toast.success("Session deleted");
    } catch {
      toast.error("Failed to delete session");
    }
  }

  async function handleSend(e: React.FormEvent) {
    e.preventDefault();
    if (!input.trim() || isSending) return;
    const text = input;
    setInput("");
    try {
      await sendMessage(text);
    } catch {
      toast.error("Failed to send message");
    }
  }

  function handleKeyDown(e: React.KeyboardEvent<HTMLTextAreaElement>) {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      handleSend(e as unknown as React.FormEvent);
    }
  }

  return (
    <div className="h-full flex overflow-hidden">
      {/* Sessions sidebar */}
      <div className="w-48 shrink-0 border-r border-border flex flex-col bg-sidebar overflow-hidden">
        <div className="p-3 border-b border-border flex flex-col gap-2">
          <Button
            size="sm"
            className="w-full gap-1.5 text-xs h-8"
            onClick={handleNewSession}
            data-ocid="chat.new_session.button"
          >
            <Plus className="w-3.5 h-3.5" />
            New Chat
          </Button>
          {/* Session search */}
          <div className="relative">
            <Search className="absolute left-2 top-1/2 -translate-y-1/2 w-3 h-3 text-muted-foreground pointer-events-none" />
            <Input
              value={sessionSearch}
              onChange={(e) => setSessionSearch(e.target.value)}
              placeholder="Search..."
              className="h-7 pl-6 text-xs bg-muted border-border"
              data-ocid="chat.session.search_input"
            />
          </div>
        </div>
        <ScrollArea className="flex-1">
          <div
            className="p-2 flex flex-col gap-1"
            data-ocid="chat.session.list"
          >
            {isLoadingSessions ? (
              <div
                className="flex justify-center py-4"
                data-ocid="chat.sessions.loading_state"
              >
                <Loader2 className="w-4 h-4 animate-spin text-muted-foreground" />
              </div>
            ) : filteredSessions.length === 0 ? (
              <div
                className="text-center py-6 px-2"
                data-ocid="chat.sessions.empty_state"
              >
                <MessageSquare className="w-6 h-6 text-muted-foreground mx-auto mb-2" />
                <p className="text-xs text-muted-foreground">
                  {sessionSearch ? "No results" : "No chats yet"}
                </p>
              </div>
            ) : (
              filteredSessions.map((session, idx) => (
                <div
                  key={session.id}
                  className="group relative"
                  data-ocid={`chat.session.item.${idx + 1}`}
                >
                  <button
                    type="button"
                    className={`w-full flex items-center gap-1 rounded-md px-2 py-2 text-xs transition-colors ${
                      session.id === currentSessionId
                        ? "bg-accent text-accent-foreground"
                        : "text-muted-foreground hover:bg-accent/50 hover:text-foreground"
                    }`}
                    onClick={() => setCurrentSessionId(session.id)}
                  >
                    <MessageSquare className="w-3.5 h-3.5 shrink-0" />
                    <span className="flex-1 truncate text-left pr-4">
                      {truncate(session.title, 16)}
                    </span>
                  </button>
                  <button
                    type="button"
                    onClick={() => handleDeleteSession(session.id)}
                    className="absolute right-1.5 top-1/2 -translate-y-1/2 opacity-0 group-hover:opacity-100 p-0.5 rounded hover:text-destructive transition-opacity"
                    data-ocid={`chat.session.delete_button.${idx + 1}`}
                  >
                    <Trash2 className="w-3 h-3" />
                  </button>
                </div>
              ))
            )}
          </div>
        </ScrollArea>
      </div>

      {/* Chat area */}
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        {/* Session header */}
        <div className="h-12 flex items-center justify-between px-4 border-b border-border shrink-0">
          {currentSession ? (
            <>
              <span className="text-sm font-medium truncate">
                {currentSession.title}
              </span>
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button
                    variant="ghost"
                    size="icon"
                    className="h-7 w-7 text-muted-foreground"
                    data-ocid="chat.session.dropdown_menu"
                  >
                    <ChevronDown className="w-3.5 h-3.5" />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end">
                  <DropdownMenuItem
                    className="text-destructive"
                    onClick={() =>
                      currentSessionId && handleDeleteSession(currentSessionId)
                    }
                    data-ocid="chat.session.delete_button"
                  >
                    <Trash2 className="w-3.5 h-3.5 mr-2" />
                    Delete session
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </>
          ) : (
            <span className="text-sm text-muted-foreground">
              {isLoadingSessions ? "Loading..." : "Starting new chat..."}
            </span>
          )}
        </div>

        {!currentSession ? (
          <div
            className="flex-1 flex flex-col items-center justify-center gap-4 p-8 text-center"
            data-ocid="chat.empty_state"
          >
            <div className="w-14 h-14 rounded-2xl bg-primary/10 border border-primary/20 flex items-center justify-center">
              <Loader2 className="w-7 h-7 text-primary/50 animate-spin" />
            </div>
            <div className="flex flex-col gap-1.5">
              <p className="text-sm font-medium text-foreground">
                Setting up your chat...
              </p>
              <p className="text-xs text-muted-foreground max-w-52">
                Creating your first session.
              </p>
            </div>
          </div>
        ) : (
          <>
            <ScrollArea className="flex-1">
              <div className="p-4 flex flex-col gap-4">
                <MemoryInjectionBlock topEdges={topEdges} nodes={nodes} />

                {isLoadingMessages ? (
                  <div
                    className="flex justify-center py-8"
                    data-ocid="chat.messages.loading_state"
                  >
                    <Loader2 className="w-5 h-5 animate-spin text-primary" />
                  </div>
                ) : messages.length === 0 ? (
                  <div
                    className="text-center py-8"
                    data-ocid="chat.messages.empty_state"
                  >
                    <p className="text-xs text-muted-foreground">
                      No messages yet. Say something!
                    </p>
                  </div>
                ) : (
                  <AnimatePresence initial={false}>
                    {messages.map((msg, idx) => (
                      <div
                        key={msg.id}
                        data-ocid={`chat.message.item.${idx + 1}`}
                      >
                        <MessageBubble message={msg} />
                      </div>
                    ))}
                  </AnimatePresence>
                )}

                <AnimatePresence>
                  {isSending && (
                    <motion.div
                      initial={{ opacity: 0, y: 8 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: 8 }}
                      className="flex gap-2"
                      data-ocid="chat.typing.loading_state"
                    >
                      <div className="w-7 h-7 rounded-full bg-primary/20 flex items-center justify-center">
                        <Brain className="w-3.5 h-3.5 text-primary" />
                      </div>
                      <div className="bg-muted border border-border rounded-xl rounded-tl-none px-3 py-2 flex items-center gap-1">
                        {[0, 1, 2].map((i) => (
                          <div
                            key={i}
                            className="w-1.5 h-1.5 rounded-full bg-primary/60 animate-bounce"
                            style={{ animationDelay: `${i * 150}ms` }}
                          />
                        ))}
                      </div>
                    </motion.div>
                  )}
                </AnimatePresence>

                <div ref={messagesEndRef} />
              </div>
            </ScrollArea>

            <div className="p-3 border-t border-border shrink-0">
              <form
                onSubmit={handleSend}
                className="flex gap-2 items-end"
                data-ocid="chat.input.section"
              >
                <textarea
                  ref={inputRef}
                  value={input}
                  onChange={(e) => setInput(e.target.value)}
                  onKeyDown={handleKeyDown}
                  placeholder="Type a message... (Enter to send, Shift+Enter for newline)"
                  disabled={isSending}
                  rows={1}
                  className="flex-1 min-w-0 resize-none rounded-md border border-border bg-muted px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-1 focus:ring-ring disabled:opacity-50 leading-relaxed"
                  style={{
                    minHeight: "36px",
                    maxHeight: "96px",
                    overflowY: "auto",
                  }}
                  data-ocid="chat.message.input"
                />
                <Button
                  type="submit"
                  size="icon"
                  disabled={isSending || !input.trim()}
                  className="shrink-0 h-9 w-9"
                  data-ocid="chat.message.submit_button"
                >
                  {isSending ? (
                    <Loader2 className="w-4 h-4 animate-spin" />
                  ) : (
                    <Send className="w-4 h-4" />
                  )}
                </Button>
              </form>
            </div>
          </>
        )}
      </div>
    </div>
  );
}
