use parralax_execution_engine::{ExecutionEngine, RiskGate, OrderRouter};
use parralax_execution_engine::engine::types::*;
use rust_decimal::Decimal;
use tracing_subscriber::EnvFilter;

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::from_default_env())
        .init();

    println!("╔══════════════════════════════════════════════════════╗");
    println!("║  PARRALAX-AIHFTFUND Execution Engine v0.1.0         ║");
    println!("║  Sovereign AI-Native HFT Infrastructure             ║");
    println!("╚══════════════════════════════════════════════════════╝");

    let risk_gate = RiskGate::with_defaults();
    let router = OrderRouter::with_defaults();
    let engine = ExecutionEngine::new(risk_gate, router);

    // Demo: Submit a test order
    let order = Order::new(
        "signal-agent-001".into(),
        "BTC/USD".into(),
        AssetClass::Crypto,
        OrderSide::Buy,
        OrderType::Market,
        Decimal::new(1, 0),
    );

    match engine.submit_order(order) {
        Ok(id) => println!("[ENGINE] Order submitted: {}", id),
        Err(e) => println!("[ENGINE] Order rejected: {}", e),
    }

    // Process order
    if let Some(receipt) = engine.process_next() {
        println!("[RECEIPT] Order {} — {:?} in {}μs",
            receipt.order_id, receipt.status, receipt.latency_us);
        println!("[RECEIPT] Hash: {}", receipt.hash);
    }

    println!("\n[ENGINE] Total orders: {}", engine.total_orders());
    println!("[ENGINE] Pending: {}", engine.pending_count());
}
