//! Tree-sitter based multi-language parser module.

use std::collections::HashMap;
use serde::{Deserialize, Serialize};

/// Registry of available language parsers.
pub struct ParserRegistry {
    languages: HashMap<String, LanguageConfig>,
}

#[derive(Clone, Serialize, Deserialize)]
pub struct LanguageConfig {
    pub name: String,
    pub extensions: Vec<String>,
    pub tree_sitter_grammar: String,
}

#[derive(Serialize, Deserialize)]
pub struct ParseResult {
    pub language: String,
    pub node_count: usize,
    pub root_kind: String,
    pub errors: Vec<ParseError>,
    pub symbols: Vec<Symbol>,
}

#[derive(Serialize, Deserialize)]
pub struct ParseError {
    pub line: usize,
    pub column: usize,
    pub message: String,
}

#[derive(Serialize, Deserialize)]
pub struct Symbol {
    pub name: String,
    pub kind: SymbolKind,
    pub start_line: usize,
    pub end_line: usize,
}

#[derive(Serialize, Deserialize)]
pub enum SymbolKind {
    Function,
    Struct,
    Enum,
    Trait,
    Impl,
    Module,
    Variable,
    Constant,
    Import,
}

impl ParserRegistry {
    pub fn new() -> Self {
        let mut languages = HashMap::new();

        languages.insert("rust".to_string(), LanguageConfig {
            name: "Rust".to_string(),
            extensions: vec!["rs".to_string()],
            tree_sitter_grammar: "tree-sitter-rust".to_string(),
        });

        languages.insert("python".to_string(), LanguageConfig {
            name: "Python".to_string(),
            extensions: vec!["py".to_string(), "pyi".to_string()],
            tree_sitter_grammar: "tree-sitter-python".to_string(),
        });

        languages.insert("go".to_string(), LanguageConfig {
            name: "Go".to_string(),
            extensions: vec!["go".to_string()],
            tree_sitter_grammar: "tree-sitter-go".to_string(),
        });

        Self { languages }
    }

    pub fn get_language(&self, name: &str) -> Option<&LanguageConfig> {
        self.languages.get(name)
    }

    pub fn detect_language(&self, filename: &str) -> Option<&LanguageConfig> {
        let ext = filename.rsplit('.').next()?;
        self.languages.values().find(|lc| lc.extensions.contains(&ext.to_string()))
    }
}

/// Parse source code using tree-sitter and return structured AST info.
pub fn parse_source(language: &str, source: &str) -> ParseResult {
    // In production, this calls tree-sitter with the appropriate grammar
    // For now, we provide a structural result based on naive analysis
    let lines: Vec<&str> = source.lines().collect();
    let node_count = lines.len();

    let mut symbols = Vec::new();

    for (i, line) in lines.iter().enumerate() {
        let trimmed = line.trim();
        match language {
            "rust" => {
                if trimmed.starts_with("fn ") || trimmed.starts_with("pub fn ") {
                    let name = extract_name(trimmed, "fn ");
                    symbols.push(Symbol {
                        name,
                        kind: SymbolKind::Function,
                        start_line: i + 1,
                        end_line: i + 1,
                    });
                } else if trimmed.starts_with("struct ") || trimmed.starts_with("pub struct ") {
                    let name = extract_name(trimmed, "struct ");
                    symbols.push(Symbol {
                        name,
                        kind: SymbolKind::Struct,
                        start_line: i + 1,
                        end_line: i + 1,
                    });
                }
            }
            "python" => {
                if trimmed.starts_with("def ") {
                    let name = extract_name(trimmed, "def ");
                    symbols.push(Symbol {
                        name,
                        kind: SymbolKind::Function,
                        start_line: i + 1,
                        end_line: i + 1,
                    });
                } else if trimmed.starts_with("class ") {
                    let name = extract_name(trimmed, "class ");
                    symbols.push(Symbol {
                        name,
                        kind: SymbolKind::Struct,
                        start_line: i + 1,
                        end_line: i + 1,
                    });
                }
            }
            "go" => {
                if trimmed.starts_with("func ") {
                    let name = extract_name(trimmed, "func ");
                    symbols.push(Symbol {
                        name,
                        kind: SymbolKind::Function,
                        start_line: i + 1,
                        end_line: i + 1,
                    });
                } else if trimmed.starts_with("type ") && trimmed.contains("struct") {
                    let name = extract_name(trimmed, "type ");
                    symbols.push(Symbol {
                        name,
                        kind: SymbolKind::Struct,
                        start_line: i + 1,
                        end_line: i + 1,
                    });
                }
            }
            _ => {}
        }
    }

    ParseResult {
        language: language.to_string(),
        node_count,
        root_kind: "source_file".to_string(),
        errors: vec![],
        symbols,
    }
}

fn extract_name(line: &str, prefix: &str) -> String {
    let after = if let Some(pos) = line.find(prefix) {
        &line[pos + prefix.len()..]
    } else {
        line
    };
    after.split(|c: char| !c.is_alphanumeric() && c != '_')
        .next()
        .unwrap_or("unknown")
        .to_string()
}
