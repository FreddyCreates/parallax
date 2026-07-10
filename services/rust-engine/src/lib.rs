pub mod crdt;
pub mod lsp;
pub mod parser;

use std::sync::Arc;
use tokio::sync::RwLock;

/// Global engine state shared across all services.
pub struct EngineState {
    pub parser_registry: parser::ParserRegistry,
    pub crdt_store: crdt::DocumentStore,
    pub lsp_state: lsp::LspState,
}

impl EngineState {
    pub fn new() -> Arc<RwLock<Self>> {
        Arc::new(RwLock::new(Self {
            parser_registry: parser::ParserRegistry::new(),
            crdt_store: crdt::DocumentStore::new(),
            lsp_state: lsp::LspState::new(),
        }))
    }
}
