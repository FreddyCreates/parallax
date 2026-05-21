import { Input } from "@/components/ui/input";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Skeleton } from "@/components/ui/skeleton";
import { Clock, MessageSquare, Search } from "lucide-react";
import { useState } from "react";
import { useAllSessions } from "../hooks/useQueries";

function formatDate(ts: bigint) {
  const d = new Date(Number(ts / 1_000_000n));
  return d.toLocaleString([], {
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

interface Props {
  onOpenSession: (id: string) => void;
}

export function HistorySection({ onOpenSession }: Props) {
  const [search, setSearch] = useState("");
  const { data: sessions = [], isLoading } = useAllSessions();

  const chatSessions = sessions
    .filter((s) => !s.title.startsWith("[NOTE] "))
    .sort((a, b) => Number(b.createdAt - a.createdAt));

  const filtered = search
    ? chatSessions.filter((s) =>
        s.title.toLowerCase().includes(search.toLowerCase()),
      )
    : chatSessions;

  return (
    <div className="flex flex-col h-full" data-ocid="history.section">
      <div className="px-3 py-2 border-b border-border shrink-0">
        <div className="flex items-center gap-2">
          <Search className="w-3.5 h-3.5 text-muted-foreground shrink-0" />
          <Input
            placeholder="Search sessions..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="h-7 text-xs bg-transparent border-0 font-mono flex-1 outline-none p-0 placeholder:text-muted-foreground focus-visible:ring-0"
            data-ocid="history.search_input"
          />
        </div>
      </div>

      <ScrollArea className="flex-1">
        {isLoading ? (
          <div className="p-3 space-y-2" data-ocid="history.list.loading_state">
            {[1, 2, 3, 4, 5].map((i) => (
              <Skeleton key={i} className="h-14 w-full bg-muted" />
            ))}
          </div>
        ) : filtered.length === 0 ? (
          <div
            className="flex flex-col items-center justify-center h-48 text-muted-foreground gap-2"
            data-ocid="history.list.empty_state"
          >
            <Clock className="w-8 h-8 opacity-30" />
            <p className="text-sm">
              {search ? "No matching sessions" : "No session history"}
            </p>
          </div>
        ) : (
          <div className="p-2 space-y-0.5">
            {filtered.map((s, i) => (
              <button
                type="button"
                key={s.id}
                onClick={() => onOpenSession(s.id)}
                className="w-full text-left px-3 py-2.5 hover:bg-muted border border-transparent hover:border-border transition-colors group flex items-start gap-2.5"
                data-ocid={`history.item.${i + 1}`}
              >
                <MessageSquare className="w-3.5 h-3.5 text-muted-foreground shrink-0 mt-0.5" />
                <div className="flex-1 min-w-0">
                  <div className="text-sm text-foreground truncate group-hover:text-primary transition-colors">
                    {s.title}
                  </div>
                  <div
                    className="font-mono text-muted-foreground"
                    style={{ fontSize: "10px" }}
                  >
                    {formatDate(s.createdAt)}
                  </div>
                </div>
              </button>
            ))}
          </div>
        )}
      </ScrollArea>
    </div>
  );
}
