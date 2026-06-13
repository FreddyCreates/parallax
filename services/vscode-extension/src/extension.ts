// PARRALAX AI VS Code Extension — built with esbuild, minimal TS only for VS Code API types
// This compiles to pure JavaScript. The extension interfaces with the Python AI service.

import * as vscode from 'vscode';

let aiServiceUrl: string;
let defaultModel: string;

export function activate(context: vscode.ExtensionContext) {
    const config = vscode.workspace.getConfiguration('parralax');
    aiServiceUrl = config.get('apiUrl', 'http://localhost:8084');
    defaultModel = config.get('model', 'claude-sonnet-4-20250514');

    // Register inline completion provider
    if (config.get('enableInlineCompletions', true)) {
        const provider = new ParralaxCompletionProvider();
        context.subscriptions.push(
            vscode.languages.registerInlineCompletionItemProvider(
                { pattern: '**' },
                provider
            )
        );
    }

    // Register commands
    context.subscriptions.push(
        vscode.commands.registerCommand('parralax.complete', handleComplete),
        vscode.commands.registerCommand('parralax.chat', handleChat),
        vscode.commands.registerCommand('parralax.review', handleReview),
        vscode.commands.registerCommand('parralax.explain', handleExplain),
    );

    vscode.window.showInformationMessage('PARRALAX AI activated — sovereign intelligence online');
}

export function deactivate() {}

class ParralaxCompletionProvider implements vscode.InlineCompletionItemProvider {
    async provideInlineCompletionItems(
        document: vscode.TextDocument,
        position: vscode.Position,
    ): Promise<vscode.InlineCompletionItem[]> {
        const textBefore = document.getText(new vscode.Range(
            new vscode.Position(Math.max(0, position.line - 50), 0),
            position
        ));

        const response = await fetch(`${aiServiceUrl}/api/v1/completions`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                prompt: textBefore,
                model: defaultModel,
                language: document.languageId,
                max_tokens: 256,
                temperature: 0.2,
            }),
        });

        if (!response.ok) return [];

        const data = await response.json() as { completion: string };
        if (!data.completion) return [];

        return [new vscode.InlineCompletionItem(data.completion)];
    }
}

async function handleComplete() {
    const editor = vscode.window.activeTextEditor;
    if (!editor) return;

    const selection = editor.selection;
    const text = editor.document.getText(selection.isEmpty ? undefined : selection);

    const response = await fetch(`${aiServiceUrl}/api/v1/completions`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            prompt: text,
            model: defaultModel,
            language: editor.document.languageId,
        }),
    });

    const data = await response.json() as { completion: string };
    if (data.completion) {
        editor.edit(editBuilder => {
            editBuilder.insert(selection.end, data.completion);
        });
    }
}

async function handleChat() {
    const panel = vscode.window.createWebviewPanel(
        'parralaxChat',
        'PARRALAX AI Chat',
        vscode.ViewColumn.Two,
        { enableScripts: true }
    );

    panel.webview.html = getChatHtml();
}

async function handleReview() {
    const editor = vscode.window.activeTextEditor;
    if (!editor) return;

    const selection = editor.selection;
    const diff = editor.document.getText(selection);

    const response = await fetch(`${aiServiceUrl}/api/v1/review`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            diff,
            language: editor.document.languageId,
            model: defaultModel,
        }),
    });

    const data = await response.json() as { summary: string; score: number };
    vscode.window.showInformationMessage(
        `PARRALAX Review: Score ${data.score}/10 — ${data.summary}`
    );
}

async function handleExplain() {
    const editor = vscode.window.activeTextEditor;
    if (!editor) return;

    const selection = editor.selection;
    const code = editor.document.getText(selection);

    const response = await fetch(`${aiServiceUrl}/api/v1/chat`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            messages: [{ role: 'user', content: `Explain this code:\n\n${code}` }],
            model: defaultModel,
        }),
    });

    const data = await response.json() as { message: { content: string } };
    const panel = vscode.window.createWebviewPanel(
        'parralaxExplain',
        'PARRALAX: Code Explanation',
        vscode.ViewColumn.Two,
    );
    panel.webview.html = `<html><body><pre>${data.message.content}</pre></body></html>`;
}

function getChatHtml(): string {
    return `<!DOCTYPE html>
<html>
<head><style>
body { font-family: var(--vscode-font-family); padding: 16px; }
#messages { height: 80vh; overflow-y: auto; }
.msg { margin: 8px 0; padding: 8px; border-radius: 4px; }
.user { background: var(--vscode-editor-selectionBackground); }
.assistant { background: var(--vscode-editor-background); border: 1px solid var(--vscode-panel-border); }
#input { width: 100%; padding: 8px; }
</style></head>
<body>
<h2>PARRALAX AI Chat</h2>
<div id="messages"></div>
<input id="input" placeholder="Ask PARRALAX AI..." onkeypress="if(event.key==='Enter')sendMessage()"/>
<script>
const vscode = acquireVsCodeApi();
function sendMessage() {
    const input = document.getElementById('input');
    const msg = input.value;
    input.value = '';
    addMessage('user', msg);
    fetch('${aiServiceUrl}/api/v1/chat', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({messages: [{role: 'user', content: msg}]})
    }).then(r => r.json()).then(data => {
        addMessage('assistant', data.message.content);
    });
}
function addMessage(role, content) {
    const div = document.createElement('div');
    div.className = 'msg ' + role;
    div.textContent = content;
    document.getElementById('messages').appendChild(div);
}
</script>
</body></html>`;
}
