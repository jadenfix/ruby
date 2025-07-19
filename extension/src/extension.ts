import * as vscode from 'vscode';

/**
 * This method is called when the extension is activated
 */
export function activate(context: vscode.ExtensionContext) {
    console.log('GemHub extension is now active!');

    // Register commands
    const commands = [
        vscode.commands.registerCommand('gemhub.wizard', () => {
            vscode.window.showInformationMessage('🧙‍♂️ Starting GemHub Wizard...');
        }),

        vscode.commands.registerCommand('gemhub.create', () => {
            vscode.window.showInformationMessage('📦 Creating new gem scaffold...');
        }),

        vscode.commands.registerCommand('gemhub.benchmark', () => {
            vscode.window.showInformationMessage('⚡ Running benchmarks...');
        })
    ];

    context.subscriptions.push(...commands);
    
    // Show activation message
    vscode.window.showInformationMessage('GemHub Lane A - Ready for development!');
}

/**
 * This method is called when the extension is deactivated
 */
export function deactivate() {
    console.log('GemHub extension deactivated');
}
