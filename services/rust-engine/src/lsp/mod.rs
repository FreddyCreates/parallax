//! LSP (Language Server Protocol) implementation for PARRALAX.

use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// LSP server state.
pub struct LspState {
    pub initialized: bool,
    pub workspace_folders: Vec<String>,
    pub open_documents: HashMap<String, DocumentState>,
    pub diagnostics: HashMap<String, Vec<Diagnostic>>,
}

#[derive(Clone, Serialize, Deserialize)]
pub struct DocumentState {
    pub uri: String,
    pub language_id: String,
    pub version: i32,
    pub content: String,
}

#[derive(Clone, Serialize, Deserialize)]
pub struct Diagnostic {
    pub range: Range,
    pub severity: DiagnosticSeverity,
    pub message: String,
    pub source: String,
}

#[derive(Clone, Serialize, Deserialize)]
pub struct Range {
    pub start: Position,
    pub end: Position,
}

#[derive(Clone, Serialize, Deserialize)]
pub struct Position {
    pub line: u32,
    pub character: u32,
}

#[derive(Clone, Copy, Serialize, Deserialize)]
pub enum DiagnosticSeverity {
    Error = 1,
    Warning = 2,
    Information = 3,
    Hint = 4,
}

#[derive(Serialize, Deserialize)]
pub struct CompletionItem {
    pub label: String,
    pub kind: CompletionKind,
    pub detail: Option<String>,
    pub documentation: Option<String>,
    pub insert_text: String,
}

#[derive(Clone, Copy, Serialize, Deserialize)]
pub enum CompletionKind {
    Function = 3,
    Variable = 6,
    Struct = 22,
    Module = 9,
    Keyword = 14,
    Snippet = 15,
}

#[derive(Serialize, Deserialize)]
pub struct HoverResult {
    pub contents: String,
    pub range: Option<Range>,
}

impl LspState {
    pub fn new() -> Self {
        Self {
            initialized: false,
            workspace_folders: vec![],
            open_documents: HashMap::new(),
            diagnostics: HashMap::new(),
        }
    }

    /// Initialize the LSP server with capabilities.
    pub fn initialize(&mut self, workspace_folders: Vec<String>) {
        self.workspace_folders = workspace_folders;
        self.initialized = true;
    }

    /// Open a text document for tracking.
    pub fn open_document(&mut self, uri: &str, language_id: &str, version: i32, content: &str) {
        self.open_documents.insert(uri.to_string(), DocumentState {
            uri: uri.to_string(),
            language_id: language_id.to_string(),
            version,
            content: content.to_string(),
        });
    }

    /// Update a document with incremental changes.
    pub fn update_document(&mut self, uri: &str, version: i32, content: &str) {
        if let Some(doc) = self.open_documents.get_mut(uri) {
            doc.version = version;
            doc.content = content.to_string();
        }
    }

    /// Get completions at a given position.
    pub fn get_completions(&self, uri: &str, _position: &Position) -> Vec<CompletionItem> {
        let _doc = match self.open_documents.get(uri) {
            Some(d) => d,
            None => return vec![],
        };

        // In production: use tree-sitter AST + AI model for intelligent completions
        vec![
            CompletionItem {
                label: "fn".to_string(),
                kind: CompletionKind::Keyword,
                detail: Some("Function definition".to_string()),
                documentation: None,
                insert_text: "fn ${1:name}(${2:params}) -> ${3:ReturnType} {\n\t$0\n}".to_string(),
            },
            CompletionItem {
                label: "struct".to_string(),
                kind: CompletionKind::Keyword,
                detail: Some("Struct definition".to_string()),
                documentation: None,
                insert_text: "struct ${1:Name} {\n\t$0\n}".to_string(),
            },
        ]
    }

    /// Get hover information at a position.
    pub fn get_hover(&self, uri: &str, _position: &Position) -> Option<HoverResult> {
        let _doc = self.open_documents.get(uri)?;
        // In production: resolve symbol via tree-sitter and type inference
        Some(HoverResult {
            contents: "Symbol documentation via PARRALAX LSP".to_string(),
            range: None,
        })
    }

    /// Get diagnostics for a document.
    pub fn get_diagnostics(&self, uri: &str) -> Vec<Diagnostic> {
        self.diagnostics.get(uri).cloned().unwrap_or_default()
    }
}
