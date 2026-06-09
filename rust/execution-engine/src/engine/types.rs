use chrono::{DateTime, Utc};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum OrderSide {
    Buy,
    Sell,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum OrderType {
    Market,
    Limit { price: Decimal },
    StopLoss { trigger: Decimal },
    StopLimit { trigger: Decimal, price: Decimal },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum AssetClass {
    Equity,
    Crypto,
    Forex,
    Commodity,
    Token,
    NFT,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum OrderStatus {
    Pending,
    Validated,
    Routed,
    PartialFill { filled: Decimal },
    Filled,
    Rejected { reason: String },
    Cancelled,
    Expired,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Order {
    pub id: Uuid,
    pub agent_id: String,
    pub symbol: String,
    pub asset_class: AssetClass,
    pub side: OrderSide,
    pub order_type: OrderType,
    pub quantity: Decimal,
    pub status: OrderStatus,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub metadata: OrderMetadata,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OrderMetadata {
    pub strategy_id: Option<String>,
    pub signal_id: Option<String>,
    pub risk_score: Option<f64>,
    pub priority: u8,
    pub ttl_ms: Option<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Fill {
    pub id: Uuid,
    pub order_id: Uuid,
    pub price: Decimal,
    pub quantity: Decimal,
    pub fee: Decimal,
    pub venue: String,
    pub timestamp: DateTime<Utc>,
    pub latency_us: u64,
}

impl Order {
    pub fn new(
        agent_id: String,
        symbol: String,
        asset_class: AssetClass,
        side: OrderSide,
        order_type: OrderType,
        quantity: Decimal,
    ) -> Self {
        let now = Utc::now();
        Self {
            id: Uuid::new_v4(),
            agent_id,
            symbol,
            asset_class,
            side,
            order_type,
            quantity,
            status: OrderStatus::Pending,
            created_at: now,
            updated_at: now,
            metadata: OrderMetadata {
                strategy_id: None,
                signal_id: None,
                risk_score: None,
                priority: 5,
                ttl_ms: None,
            },
        }
    }
}
