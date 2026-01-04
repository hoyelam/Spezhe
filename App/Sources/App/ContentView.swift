//
//  ContentView.swift
//  spetra
//
//  Created by Hoye Lam on 04/01/2026.
//

import SwiftUI

public struct ContentView: View {
    public init() {}

    public var body: some View {
        VStack {
            Image(systemName: "waveform")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Spetra is running in the menu bar")
                .font(.headline)
            Text("Press ⌘⌃1 to start recording")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 300, height: 150)
    }
}

#Preview {
    ContentView()
}
