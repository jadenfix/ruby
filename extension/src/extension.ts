import * as vscode from 'vscode';
import { GemHubSidebarProvider } from './panels/SidebarProvider';

/**
 * This method is called when the extension is activated
 * The extension is activated the very first time the command is executed
 */
export function activate(context: vscode.ExtensionContext) {
    console.log('GemHub extension is now active!');

    // Initialize the sidebar provider
    const sidebarProvider = new GemHubSidebarProvider(context.extensionUri);
    context.subscriptions.push(
        vscode.window.registerWebviewViewProvider(
            'gemhubSidebar',
            sidebarProvider
        )
    );

    // Register commands
    const commands = [
        vscode.commands.registerCommand('gemhub.wizard', () => {
            vscode.window.showInformationMessage('Starting GemHub Wizard...');
            sidebarProvider.showWizard();
        }),

        vscode.commands.registerCommand('gemhub.create', () => {
            vscode.window.showInformationMessage('Creating new gem scaffold...');
            sidebarProvider.showCreate();
        }),

        vscode.commands.registerCommand('gemhub.benchmark', () => {
            vscode.window.showInformationMessage('Running benchmarks...');
            sidebarProvider.showBenchmarks();
        }),

        vscode.commands.registerCommand('gemhub.openMarketplace', () => {
            sidebarProvider.showMarketplace();
        })
    ];

    context.subscriptions.push(...commands);
}

/**
 * This method is called when the extension is deactivated
 */
export function deactivate() {
    console.log('GemHub extension deactivated');
} 