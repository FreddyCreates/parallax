use std::net::SocketAddr;

use axum::{
    extract::State,
    routing::{get, post},
    Json, Router,
};
use tower_http::cors::CorsLayer;
use tower_http::trace::TraceLayer;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

use parralax_rust_engine::EngineState;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::new(
            std::env::var("RUST_LOG").unwrap_or_else(|_| "info".to_string()),
        ))
        .with(tracing_subscriber::fmt::layer().json())
        .init();

    let state = EngineState::new();

    let app = Router::new()
        .route("/health", get(health))
        .route("/api/v1/parse", post(parse_code))
        .route("/api/v1/documents", get(list_documents))
        .route("/api/v1/documents/:id", get(get_document))
        .route("/ws/collaborate", get(ws_collaborate))
        .layer(CorsLayer::permissive())
        .layer(TraceLayer::new_for_http())
        .with_state(state);

    let port: u16 = std::env::var("RUST_ENGINE_PORT")
        .unwrap_or_else(|_| "8083".to_string())
        .parse()?;

    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    tracing::info!("PARRALAX Rust Engine starting on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}

async fn health() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "status": "healthy",
        "service": "parralax-rust-engine",
        "version": "1.0.0",
        "capabilities": ["tree-sitter", "lsp", "crdt", "websocket"]
    }))
}

async fn parse_code(
    State(_state): State<std::sync::Arc<tokio::sync::RwLock<parralax_rust_engine::EngineState>>>,
    Json(payload): Json<serde_json::Value>,
) -> Json<serde_json::Value> {
    let language = payload.get("language").and_then(|v| v.as_str()).unwrap_or("rust");
    let code = payload.get("code").and_then(|v| v.as_str()).unwrap_or("");

    // Parse with tree-sitter
    let result = parralax_rust_engine::parser::parse_source(language, code);

    Json(serde_json::json!({
        "language": language,
        "ast": result,
        "status": "parsed"
    }))
}

async fn list_documents(
    State(_state): State<std::sync::Arc<tokio::sync::RwLock<parralax_rust_engine::EngineState>>>,
) -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "documents": [],
        "count": 0
    }))
}

async fn get_document(
    State(_state): State<std::sync::Arc<tokio::sync::RwLock<parralax_rust_engine::EngineState>>>,
) -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "status": "not_found"
    }))
}

async fn ws_collaborate(
    ws: axum::extract::WebSocketUpgrade,
    State(state): State<std::sync::Arc<tokio::sync::RwLock<parralax_rust_engine::EngineState>>>,
) -> axum::response::Response {
    ws.on_upgrade(move |socket| handle_ws(socket, state))
}

async fn handle_ws(
    mut socket: axum::extract::ws::WebSocket,
    _state: std::sync::Arc<tokio::sync::RwLock<parralax_rust_engine::EngineState>>,
) {
    use axum::extract::ws::Message;

    while let Some(Ok(msg)) = futures::StreamExt::next(&mut socket).await {
        match msg {
            Message::Text(text) => {
                // Process CRDT updates
                let response = serde_json::json!({
                    "type": "ack",
                    "payload": text
                });
                let _ = futures::SinkExt::send(
                    &mut socket,
                    Message::Text(response.to_string()),
                )
                .await;
            }
            Message::Binary(data) => {
                // Binary CRDT sync protocol (Yjs encoding)
                let _ = futures::SinkExt::send(&mut socket, Message::Binary(data)).await;
            }
            Message::Close(_) => break,
            _ => {}
        }
    }
}
