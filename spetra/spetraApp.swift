//
//  spetraApp.swift
//  spetra
//
//  Created by Hoye Lam on 04/01/2026.
//

import SwiftUI
import App

@main
struct spetraApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MainWindowView(viewModel: appDelegate.recordingViewModel)
                .frame(minWidth: 1100, minHeight: 600)
        }
        .windowStyle(.automatic)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1200, height: 700)
        .defaultPosition(.center)
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Recording") {
                    Task {
                        await appDelegate.recordingViewModel.toggleRecording()
                    }
                }
                .keyboardShortcut("r", modifiers: [.command])
            }
        }

        Settings {
            SettingsView(recordingViewModel: appDelegate.recordingViewModel)
        }
    }
}
