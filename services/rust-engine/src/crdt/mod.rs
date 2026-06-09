//! CRDT-based collaborative document store using Yrs (Yjs Rust port).

use std::collections::HashMap;
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use chrono::{DateTime, Utc};

/// Store for CRDT-managed collaborative documents.
pub struct DocumentStore {
    documents: HashMap<String, CrdtDocument>,
}

/// A collaboratively-edited document backed by Yjs CRDT.
pub struct CrdtDocument {
    pub id: String,
    pub filename: String,
    pub language: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub collaborators: Vec<Collaborator>,
    pub content: String,
    // In production: yrs::Doc instance for conflict-free editing
}

#[derive(Clone, Serialize, Deserialize)]
pub struct Collaborator {
    pub user_id: String,
    pub cursor_line: u32,
    pub cursor_col: u32,
    pub color: String,
    pub connected_at: DateTime<Utc>,
}

#[derive(Serialize, Deserialize)]
pub struct DocumentUpdate {
    pub document_id: String,
    pub user_id: String,
    pub operations: Vec<CrdtOperation>,
    pub timestamp: DateTime<Utc>,
}

#[derive(Serialize, Deserialize)]
pub enum CrdtOperation {
    Insert { position: usize, text: String },
    Delete { position: usize, length: usize },
    CursorMove { line: u32, col: u32 },
}

impl DocumentStore {
    pub fn new() -> Self {
        Self {
            documents: HashMap::new(),
        }
    }

    /// Create a new collaborative document.
    pub fn create_document(&mut self, filename: &str, language: &str, content: &str) -> String {
        let id = Uuid::new_v4().to_string();
        let now = Utc::now();
        let doc = CrdtDocument {
            id: id.clone(),
            filename: filename.to_string(),
            language: language.to_string(),
            created_at: now,
            updated_at: now,
            collaborators: vec![],
            content: content.to_string(),
        };
        self.documents.insert(id.clone(), doc);
        id
    }

    /// Join a document session as a collaborator.
    pub fn join_document(&mut self, doc_id: &str, user_id: &str, color: &str) -> bool {
        if let Some(doc) = self.documents.get_mut(doc_id) {
            doc.collaborators.push(Collaborator {
                user_id: user_id.to_string(),
                cursor_line: 0,
                cursor_col: 0,
                color: color.to_string(),
                connected_at: Utc::now(),
            });
            true
        } else {
            false
        }
    }

    /// Apply a CRDT update to a document.
    pub fn apply_update(&mut self, update: &DocumentUpdate) -> bool {
        if let Some(doc) = self.documents.get_mut(&update.document_id) {
            for op in &update.operations {
                match op {
                    CrdtOperation::Insert { position, text } => {
                        let pos = (*position).min(doc.content.len());
                        doc.content.insert_str(pos, text);
                    }
                    CrdtOperation::Delete { position, length } => {
                        let start = (*position).min(doc.content.len());
                        let end = (start + length).min(doc.content.len());
                        doc.content.drain(start..end);
                    }
                    CrdtOperation::CursorMove { line, col } => {
                        if let Some(collab) = doc.collaborators.iter_mut()
                            .find(|c| c.user_id == update.user_id)
                        {
                            collab.cursor_line = *line;
                            collab.cursor_col = *col;
                        }
                    }
                }
            }
            doc.updated_at = Utc::now();
            true
        } else {
            false
        }
    }

    /// Get document content.
    pub fn get_document(&self, doc_id: &str) -> Option<&CrdtDocument> {
        self.documents.get(doc_id)
    }

    /// List all active documents.
    pub fn list_documents(&self) -> Vec<&CrdtDocument> {
        self.documents.values().collect()
    }
}
