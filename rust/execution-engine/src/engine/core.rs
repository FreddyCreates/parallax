use std::sync::Arc;

use crossbeam_channel::{bounded, Receiver, Sender};
use dashmap::DashMap;
use tracing::{error, info, warn};
use uuid::Uuid;

use super::types::{Fill, Order, OrderStatus};
use crate::receipts::ExecutionReceipt;
use crate::risk::RiskGate;
use crate::routing::OrderRouter;

pub struct ExecutionEngine {
    orders: Arc<DashMap<Uuid, Order>>,
    fills: Arc<DashMap<Uuid, Vec<Fill>>>,
    receipts: Arc<DashMap<Uuid, ExecutionReceipt>>,
    risk_gate: Arc<RiskGate>,
    router: Arc<OrderRouter>,
    order_tx: Sender<Order>,
    order_rx: Receiver<Order>,
}

impl ExecutionEngine {
    pub fn new(risk_gate: RiskGate, router: OrderRouter) -> Self {
        let (order_tx, order_rx) = bounded(10_000);
        Self {
            orders: Arc::new(DashMap::new()),
            fills: Arc::new(DashMap::new()),
            receipts: Arc::new(DashMap::new()),
            risk_gate: Arc::new(risk_gate),
            router: Arc::new(router),
            order_tx,
            order_rx,
        }
    }

    pub fn submit_order(&self, mut order: Order) -> Result<Uuid, EngineError> {
        let order_id = order.id;

        // Risk validation
        match self.risk_gate.validate(&order) {
            Ok(()) => {
                order.status = OrderStatus::Validated;
                info!(order_id = %order_id, symbol = %order.symbol, "Order validated");
            }
            Err(reason) => {
                order.status = OrderStatus::Rejected {
                    reason: reason.clone(),
                };
                warn!(order_id = %order_id, reason = %reason, "Order rejected by risk gate");
                self.orders.insert(order_id, order);
                return Err(EngineError::RiskRejection(reason));
            }
        }

        self.orders.insert(order_id, order.clone());
        self.order_tx
            .send(order)
            .map_err(|_| EngineError::QueueFull)?;

        Ok(order_id)
    }

    pub fn process_next(&self) -> Option<ExecutionReceipt> {
        match self.order_rx.try_recv() {
            Ok(order) => {
                let receipt = self.execute_order(order);
                Some(receipt)
            }
            Err(_) => None,
        }
    }

    fn execute_order(&self, mut order: Order) -> ExecutionReceipt {
        let start = std::time::Instant::now();

        // Route order to venue
        let route_result = self.router.route(&order);

        match route_result {
            Ok(venue) => {
                order.status = OrderStatus::Routed;
                if let Some(mut entry) = self.orders.get_mut(&order.id) {
                    entry.status = OrderStatus::Routed;
                }
                info!(
                    order_id = %order.id,
                    venue = %venue,
                    "Order routed"
                );
            }
            Err(e) => {
                let reason = format!("Routing failed: {}", e);
                order.status = OrderStatus::Rejected {
                    reason: reason.clone(),
                };
                error!(order_id = %order.id, error = %e, "Routing failed");
            }
        }

        let latency = start.elapsed();
        let receipt = ExecutionReceipt::new(order.id, order.status.clone(), latency);
        self.receipts.insert(order.id, receipt.clone());
        receipt
    }

    pub fn get_order(&self, id: &Uuid) -> Option<Order> {
        self.orders.get(id).map(|o| o.clone())
    }

    pub fn get_receipt(&self, id: &Uuid) -> Option<ExecutionReceipt> {
        self.receipts.get(id).map(|r| r.clone())
    }

    pub fn pending_count(&self) -> usize {
        self.order_rx.len()
    }

    pub fn total_orders(&self) -> usize {
        self.orders.len()
    }
}

#[derive(Debug, thiserror::Error)]
pub enum EngineError {
    #[error("Risk rejection: {0}")]
    RiskRejection(String),
    #[error("Order queue full")]
    QueueFull,
    #[error("Order not found: {0}")]
    NotFound(Uuid),
}
