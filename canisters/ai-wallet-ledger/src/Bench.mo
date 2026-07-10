import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Types "Types";

module {
  public func makeBenchmarkId(input : Types.BenchmarkInput, now : Int) : Text {
    "bench:" # input.suite # ":" # input.name # ":" # Int.toText(now)
  };

  public func record(input : Types.BenchmarkInput, now : Int) : Types.BenchmarkReceipt {
    let average = if (input.iterations == 0) 0 else input.totalLatencyNanos / input.iterations;
    {
      benchmarkId = makeBenchmarkId(input, now);
      name = input.name;
      suite = input.suite;
      iterations = input.iterations;
      averageLatencyNanos = average;
      maxLatencyNanos = input.maxLatencyNanos;
      minLatencyNanos = input.minLatencyNanos;
      recordedAt = now;
      notes = input.notes;
    }
  };
}
