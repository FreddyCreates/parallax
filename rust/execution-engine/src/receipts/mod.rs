use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::engine::types::OrderStatus;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExecutionReceipt {
    pub receipt_id: Uuid,
    pub order_id: Uuid,
    pub status: OrderStatus,
    pub latency_us: u64,
    pub timestamp: DateTime<Utc>,
    pub hash: String,
}

impl ExecutionReceipt {
    pub fn new(order_id: Uuid, status: OrderStatus, latency: std::time::Duration) -> Self {
        let receipt_id = Uuid::new_v4();
        let timestamp = Utc::now();
        let latency_us = latency.as_micros() as u64;

        // Deterministic hash for audit trail
        let hash_input = format!("{}:{}:{}:{}", receipt_id, order_id, latency_us, timestamp);
        let hash = format!("{:x}", md5_hash(hash_input.as_bytes()));

        Self {
            receipt_id,
            order_id,
            status,
            latency_us,
            timestamp,
            hash,
        }
    }

    pub fn verify(&self) -> bool {
        let hash_input = format!(
            "{}:{}:{}:{}",
            self.receipt_id, self.order_id, self.latency_us, self.timestamp
        );
        let expected = format!("{:x}", md5_hash(hash_input.as_bytes()));
        self.hash == expected
    }
}

// Simple hash for receipt integrity (not cryptographic security)
fn md5_hash(data: &[u8]) -> u128 {
    let mut hash: u128 = 0xcbf29ce484222325;
    for &byte in data {
        hash ^= byte as u128;
        hash = hash.wrapping_mul(0x100000001b3);
    }
    hash
}
