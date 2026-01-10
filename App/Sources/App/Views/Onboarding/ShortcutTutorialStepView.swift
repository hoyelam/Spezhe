import SwiftUI

struct ShortcutTutorialStepView: View {
    @State private var tryItText = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "keyboard.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text("Your Recording Shortcut")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Use this shortcut from anywhere to start recording.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 8) {
                KeyboardKeyView(key: "control")
                Text("+")
                    .font(.title2)
                    .foregroundColor(.secondary)
                KeyboardKeyView(key: "Space")
            }
            .padding(.vertical, 12)

            // Try it out section
            VStack(alignment: .leading, spacing: 8) {
                Text("Try it out")
                    .font(.headline)

                HStack(spacing: 8) {
                    TextField("Click here, then press the shortcut to record...", text: $tryItText)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(nsColor: .textBackgroundColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .focused($isTextFieldFocused)

                    Button {
                        tryItText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .opacity(tryItText.isEmpty ? 0.3 : 1)
                    .disabled(tryItText.isEmpty)
                }
            }
            .padding(.horizontal, 32)

            Text("You can customize this shortcut in Settings.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
        .padding(.vertical, 24)
    }
}

private struct KeyboardKeyView: View {
    let key: String

    var body: some View {
        Text(key)
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundColor(.primary)
            .padding(.horizontal, key == "control" ? 12 : 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 1, y: 1)
    }
}

private struct TutorialStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.accentColor))

            Text(text)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    ShortcutTutorialStepView()
        .frame(width: 520, height: 480)
}
