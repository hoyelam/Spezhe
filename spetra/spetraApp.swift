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
    @StateObject private var recordingsStore = RecordingRepository.shared

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .frame(minWidth: 1100, minHeight: 600)
                .environmentObject(appDelegate.recordingViewModel)
                .environmentObject(recordingsStore)
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
            SettingsView()
                .environmentObject(appDelegate.recordingViewModel)
        }
    }
}
