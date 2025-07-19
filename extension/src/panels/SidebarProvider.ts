import * as vscode from 'vscode';
import { getNonce } from '../utils/getNonce';

/**
 * Provider for the GemHub sidebar webview
 * Manages tabs: Marketplace, Sandbox, Benchmarks, Chat
 */
export class GemHubSidebarProvider implements vscode.WebviewViewProvider {
    _view?: vscode.WebviewView;
    _doc?: vscode.TextDocument;

    constructor(private readonly _extensionUri: vscode.Uri) {}

    public resolveWebviewView(webviewView: vscode.WebviewView) {
        this._view = webviewView;

        webviewView.webview.options = {
            // Allow scripts in the webview
            enableScripts: true,
            localResourceRoots: [this._extensionUri],
        };

        webviewView.webview.html = this._getHtmlForWebview(webviewView.webview);

        // Handle messages from the webview
        webviewView.webview.onDidReceiveMessage(async (data) => {
            switch (data.type) {
                case 'fetchGems': {
                    await this.fetchGems();
                    break;
                }
                case 'createGem': {
                    await this.createGem(data.gemData);
                    break;
                }
                case 'runBenchmark': {
                    await this.runBenchmark(data.gemName);
                    break;
                }
                case 'showInfo': {
                    vscode.window.showInformationMessage(data.message);
                    break;
                }
            }
        });
    }

    public showMarketplace() {
        if (this._view) {
            this._view.webview.postMessage({ type: 'showTab', tab: 'marketplace' });
        }
    }

    public showWizard() {
        if (this._view) {
            this._view.webview.postMessage({ type: 'showTab', tab: 'wizard' });
        }
    }

    public showCreate() {
        if (this._view) {
            this._view.webview.postMessage({ type: 'showTab', tab: 'create' });
        }
    }

    public showBenchmarks() {
        if (this._view) {
            this._view.webview.postMessage({ type: 'showTab', tab: 'benchmarks' });
        }
    }

    private async fetchGems() {
        try {
            // TODO: Replace with actual API endpoint
            const response = await fetch('http://localhost:4567/gems');
            const gems = await response.json();
            
            this._view?.webview.postMessage({
                type: 'gemsData',
                data: gems
            });
        } catch (error) {
            vscode.window.showErrorMessage(`Failed to fetch gems: ${error}`);
        }
    }

    private async createGem(gemData: any) {
        try {
            // TODO: Replace with actual API endpoint
            const response = await fetch('http://localhost:4567/gems', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(gemData)
            });
            
            if (response.ok) {
                vscode.window.showInformationMessage('Gem created successfully!');
                await this.fetchGems(); // Refresh the list
            } else {
                throw new Error(`HTTP ${response.status}`);
            }
        } catch (error) {
            vscode.window.showErrorMessage(`Failed to create gem: ${error}`);
        }
    }

    private async runBenchmark(gemName: string) {
        try {
            // TODO: Replace with actual benchmark endpoint
            const response = await fetch(`http://localhost:4567/benchmark/${gemName}`, {
                method: 'POST'
            });
            
            const results = await response.json();
            
            this._view?.webview.postMessage({
                type: 'benchmarkResults',
                data: results
            });
            
            vscode.window.showInformationMessage(`Benchmark completed for ${gemName}`);
        } catch (error) {
            vscode.window.showErrorMessage(`Benchmark failed: ${error}`);
        }
    }

    private _getHtmlForWebview(webview: vscode.Webview) {
        const nonce = getNonce();

        return `<!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src ${webview.cspSource}; script-src 'nonce-${nonce}';">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>GemHub</title>
                <style>
                    body {
                        padding: 0;
                        margin: 0;
                        font-family: var(--vscode-font-family);
                        color: var(--vscode-foreground);
                        background-color: var(--vscode-editor-background);
                    }
                    .tab-container {
                        display: flex;
                        border-bottom: 1px solid var(--vscode-panel-border);
                    }
                    .tab {
                        padding: 8px 16px;
                        cursor: pointer;
                        border: none;
                        background: none;
                        color: var(--vscode-foreground);
                        border-bottom: 2px solid transparent;
                    }
                    .tab.active {
                        border-bottom-color: var(--vscode-focusBorder);
                    }
                    .tab:hover {
                        background-color: var(--vscode-list-hoverBackground);
                    }
                    .content {
                        padding: 16px;
                    }
                    .tab-content {
                        display: none;
                    }
                    .tab-content.active {
                        display: block;
                    }
                    .gem-item {
                        padding: 12px;
                        border: 1px solid var(--vscode-panel-border);
                        margin-bottom: 8px;
                        border-radius: 4px;
                    }
                    .gem-name {
                        font-weight: bold;
                        margin-bottom: 4px;
                    }
                    .gem-description {
                        color: var(--vscode-descriptionForeground);
                        font-size: 0.9em;
                    }
                    .button {
                        background-color: var(--vscode-button-background);
                        color: var(--vscode-button-foreground);
                        border: none;
                        padding: 6px 12px;
                        border-radius: 2px;
                        cursor: pointer;
                        margin-right: 8px;
                        margin-top: 8px;
                    }
                    .button:hover {
                        background-color: var(--vscode-button-hoverBackground);
                    }
                    .form-group {
                        margin-bottom: 12px;
                    }
                    .form-group label {
                        display: block;
                        margin-bottom: 4px;
                        font-weight: bold;
                    }
                    .form-group input, .form-group textarea {
                        width: 100%;
                        padding: 6px;
                        border: 1px solid var(--vscode-input-border);
                        background-color: var(--vscode-input-background);
                        color: var(--vscode-input-foreground);
                        border-radius: 2px;
                    }
                </style>
            </head>
            <body>
                <div class="tab-container">
                    <button class="tab active" data-tab="marketplace">Marketplace</button>
                    <button class="tab" data-tab="sandbox">Sandbox</button>
                    <button class="tab" data-tab="benchmarks">Benchmarks</button>
                    <button class="tab" data-tab="chat">Chat</button>
                </div>
                
                <div class="content">
                    <div id="marketplace" class="tab-content active">
                        <h3>Gem Marketplace</h3>
                        <button class="button" onclick="fetchGems()">Refresh</button>
                        <div id="gems-list"></div>
                    </div>
                    
                    <div id="sandbox" class="tab-content">
                        <h3>Sandbox Environment</h3>
                        <p>Launch one-click Rails demo with your gem</p>
                        <div class="form-group">
                            <label for="sandbox-gem">Gem Name:</label>
                            <input type="text" id="sandbox-gem" placeholder="Enter gem name">
                        </div>
                        <button class="button" onclick="launchSandbox()">Launch Sandbox</button>
                    </div>
                    
                    <div id="benchmarks" class="tab-content">
                        <h3>Benchmarks</h3>
                        <p>Run performance benchmarks on gems</p>
                        <div class="form-group">
                            <label for="benchmark-gem">Gem Name:</label>
                            <input type="text" id="benchmark-gem" placeholder="Enter gem name">
                        </div>
                        <button class="button" onclick="runBenchmark()">Run Benchmark</button>
                        <div id="benchmark-results"></div>
                    </div>
                    
                    <div id="chat" class="tab-content">
                        <h3>AI Assistant</h3>
                        <p>Chat with AI about Ruby gems and development</p>
                        <div class="form-group">
                            <textarea id="chat-input" rows="3" placeholder="Ask about gems, best practices, or get recommendations..."></textarea>
                        </div>
                        <button class="button" onclick="sendChatMessage()">Send</button>
                        <div id="chat-messages"></div>
                    </div>
                </div>

                <script nonce="${nonce}">
                    const vscode = acquireVsCodeApi();
                    
                    // Tab switching
                    document.querySelectorAll('.tab').forEach(tab => {
                        tab.addEventListener('click', () => {
                            const tabName = tab.dataset.tab;
                            showTab(tabName);
                        });
                    });
                    
                    function showTab(tabName) {
                        // Update tab buttons
                        document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
                        document.querySelector('[data-tab="' + tabName + '"]').classList.add('active');
                        
                        // Update content
                        document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
                        document.getElementById(tabName).classList.add('active');
                    }
                    
                    function fetchGems() {
                        vscode.postMessage({ type: 'fetchGems' });
                    }
                    
                    function launchSandbox() {
                        const gemName = document.getElementById('sandbox-gem').value;
                        if (gemName) {
                            vscode.postMessage({ 
                                type: 'showInfo', 
                                message: 'Launching sandbox for ' + gemName + '...' 
                            });
                        }
                    }
                    
                    function runBenchmark() {
                        const gemName = document.getElementById('benchmark-gem').value;
                        if (gemName) {
                            vscode.postMessage({ 
                                type: 'runBenchmark', 
                                gemName: gemName 
                            });
                        }
                    }
                    
                    function sendChatMessage() {
                        const message = document.getElementById('chat-input').value;
                        if (message) {
                            vscode.postMessage({ 
                                type: 'showInfo', 
                                message: 'AI Chat: ' + message 
                            });
                            document.getElementById('chat-input').value = '';
                        }
                    }
                    
                    // Handle messages from extension
                    window.addEventListener('message', event => {
                        const message = event.data;
                        switch (message.type) {
                            case 'showTab':
                                showTab(message.tab);
                                break;
                            case 'gemsData':
                                displayGems(message.data);
                                break;
                            case 'benchmarkResults':
                                displayBenchmarkResults(message.data);
                                break;
                        }
                    });
                    
                    function displayGems(gems) {
                        const container = document.getElementById('gems-list');
                        container.innerHTML = '';
                        
                        gems.forEach(gem => {
                            const gemElement = document.createElement('div');
                            gemElement.className = 'gem-item';
                            gemElement.innerHTML = \`
                                <div class="gem-name">\${gem.name}</div>
                                <div class="gem-description">\${gem.description || 'No description available'}</div>
                                <button class="button" onclick="installGem('\${gem.name}')">Install</button>
                                <button class="button" onclick="viewGem('\${gem.name}')">View Details</button>
                            \`;
                            container.appendChild(gemElement);
                        });
                    }
                    
                    function displayBenchmarkResults(results) {
                        const container = document.getElementById('benchmark-results');
                        container.innerHTML = '<h4>Benchmark Results:</h4><pre>' + JSON.stringify(results, null, 2) + '</pre>';
                    }
                    
                    function installGem(gemName) {
                        vscode.postMessage({ 
                            type: 'showInfo', 
                            message: 'Installing ' + gemName + '...' 
                        });
                    }
                    
                    function viewGem(gemName) {
                        vscode.postMessage({ 
                            type: 'showInfo', 
                            message: 'Viewing details for ' + gemName 
                        });
                    }
                    
                    // Initial load
                    fetchGems();
                </script>
            </body>
            </html>`;
    }
} 