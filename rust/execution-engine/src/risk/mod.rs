use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use tracing::warn;

use crate::engine::types::Order;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RiskLimits {
    pub max_order_size: Decimal,
    pub max_position_size: Decimal,
    pub max_daily_loss: Decimal,
    pub max_orders_per_second: u32,
    pub max_notional_exposure: Decimal,
    pub allowed_asset_classes: Vec<String>,
    pub kill_switch_active: bool,
}

impl Default for RiskLimits {
    fn default() -> Self {
        Self {
            max_order_size: Decimal::new(100_000, 0),
            max_position_size: Decimal::new(1_000_000, 0),
            max_daily_loss: Decimal::new(50_000, 0),
            max_orders_per_second: 100,
            max_notional_exposure: Decimal::new(5_000_000, 0),
            allowed_asset_classes: vec![
                "Equity".into(),
                "Crypto".into(),
                "Forex".into(),
                "Token".into(),
            ],
            kill_switch_active: false,
        }
    }
}

pub struct RiskGate {
    limits: RiskLimits,
    daily_pnl: std::sync::atomic::AtomicI64,
}

impl RiskGate {
    pub fn new(limits: RiskLimits) -> Self {
        Self {
            limits,
            daily_pnl: std::sync::atomic::AtomicI64::new(0),
        }
    }

    pub fn with_defaults() -> Self {
        Self::new(RiskLimits::default())
    }

    pub fn validate(&self, order: &Order) -> Result<(), String> {
        // Kill switch check
        if self.limits.kill_switch_active {
            return Err("Kill switch is active — all trading halted".into());
        }

        // Order size check
        if order.quantity > self.limits.max_order_size {
            return Err(format!(
                "Order size {} exceeds max {}",
                order.quantity, self.limits.max_order_size
            ));
        }

        // Asset class check
        let asset_class_str = format!("{:?}", order.asset_class);
        if !self.limits.allowed_asset_classes.contains(&asset_class_str) {
            return Err(format!(
                "Asset class {:?} not in allowed list",
                order.asset_class
            ));
        }

        // Daily loss check
        let current_pnl = self.daily_pnl.load(std::sync::atomic::Ordering::Relaxed);
        let max_loss_cents = self.limits.max_daily_loss.mantissa();
        if current_pnl < -max_loss_cents {
            warn!("Daily loss limit breached");
            return Err("Daily loss limit breached".into());
        }

        Ok(())
    }

    pub fn update_pnl(&self, delta_cents: i64) {
        self.daily_pnl
            .fetch_add(delta_cents, std::sync::atomic::Ordering::Relaxed);
    }

    pub fn activate_kill_switch(&mut self) {
        self.limits.kill_switch_active = true;
    }

    pub fn deactivate_kill_switch(&mut self) {
        self.limits.kill_switch_active = false;
    }
}
