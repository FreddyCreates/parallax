use serde::{Deserialize, Serialize};

use crate::engine::types::{AssetClass, Order};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Venue {
    pub id: String,
    pub name: String,
    pub asset_classes: Vec<String>,
    pub latency_us: u64,
    pub active: bool,
}

pub struct OrderRouter {
    venues: Vec<Venue>,
}

impl OrderRouter {
    pub fn new(venues: Vec<Venue>) -> Self {
        Self { venues }
    }

    pub fn with_defaults() -> Self {
        Self::new(vec![
            Venue {
                id: "alpaca".into(),
                name: "Alpaca Markets".into(),
                asset_classes: vec!["Equity".into(), "Crypto".into()],
                latency_us: 500,
                active: true,
            },
            Venue {
                id: "binance".into(),
                name: "Binance".into(),
                asset_classes: vec!["Crypto".into(), "Token".into()],
                latency_us: 200,
                active: true,
            },
            Venue {
                id: "interactive_brokers".into(),
                name: "Interactive Brokers".into(),
                asset_classes: vec!["Equity".into(), "Forex".into(), "Commodity".into()],
                latency_us: 1000,
                active: true,
            },
            Venue {
                id: "uniswap".into(),
                name: "Uniswap DEX".into(),
                asset_classes: vec!["Token".into(), "NFT".into()],
                latency_us: 12000,
                active: true,
            },
        ])
    }

    pub fn route(&self, order: &Order) -> Result<String, RoutingError> {
        let asset_class_str = format!("{:?}", order.asset_class);

        let eligible: Vec<&Venue> = self
            .venues
            .iter()
            .filter(|v| v.active && v.asset_classes.contains(&asset_class_str))
            .collect();

        if eligible.is_empty() {
            return Err(RoutingError::NoVenueAvailable {
                asset_class: asset_class_str,
                symbol: order.symbol.clone(),
            });
        }

        // Route to lowest latency venue
        let best = eligible
            .iter()
            .min_by_key(|v| v.latency_us)
            .unwrap();

        Ok(best.id.clone())
    }

    pub fn add_venue(&mut self, venue: Venue) {
        self.venues.push(venue);
    }

    pub fn disable_venue(&mut self, id: &str) {
        if let Some(v) = self.venues.iter_mut().find(|v| v.id == id) {
            v.active = false;
        }
    }
}

#[derive(Debug, thiserror::Error)]
pub enum RoutingError {
    #[error("No venue available for {asset_class} / {symbol}")]
    NoVenueAvailable {
        asset_class: String,
        symbol: String,
    },
    #[error("Venue {0} is offline")]
    VenueOffline(String),
}
