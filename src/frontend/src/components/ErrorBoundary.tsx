import { Component, type ErrorInfo, type ReactNode } from "react";

interface ErrorBoundaryProps {
  children: ReactNode;
  fallback?: ReactNode;
  onError?: (error: Error, errorInfo: ErrorInfo) => void;
}

interface ErrorBoundaryState {
  hasError: boolean;
  error: Error | null;
}

/**
 * ErrorBoundary — catches unhandled React render errors and displays
 * a graceful fallback UI instead of crashing the entire application.
 */
export class ErrorBoundary extends Component<
  ErrorBoundaryProps,
  ErrorBoundaryState
> {
  constructor(props: ErrorBoundaryProps) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo): void {
    this.props.onError?.(error, errorInfo);
  }

  private handleReset = () => {
    this.setState({ hasError: false, error: null });
  };

  render(): ReactNode {
    if (this.state.hasError) {
      if (this.props.fallback) return this.props.fallback;

      return (
        <div
          className="flex flex-col items-center justify-center min-h-[200px] p-6 gap-4"
          style={{
            background: "oklch(0.08 0.01 240)",
            border: "1px solid oklch(0.55 0.22 25 / 0.3)",
            borderRadius: 8,
          }}
          data-ocid="error.boundary"
        >
          <div
            className="font-mono text-[10px] tracking-[0.3em] uppercase"
            style={{ color: "oklch(0.55 0.22 25)" }}
          >
            ⚠ SUBSTRATE FAULT DETECTED
          </div>
          <div
            className="font-mono text-[11px] max-w-md text-center"
            style={{ color: "oklch(0.55 0.02 240)" }}
          >
            {this.state.error?.message ?? "An unexpected error occurred"}
          </div>
          <button
            type="button"
            onClick={this.handleReset}
            className="font-mono text-[9px] tracking-[0.3em] uppercase px-4 py-2 cursor-pointer"
            style={{
              color: "oklch(0.78 0.15 85)",
              border: "1px solid oklch(0.78 0.15 85 / 0.3)",
              background: "transparent",
              borderRadius: 4,
            }}
          >
            REINITIALIZE MODULE
          </button>
        </div>
      );
    }

    return this.props.children;
  }
}
