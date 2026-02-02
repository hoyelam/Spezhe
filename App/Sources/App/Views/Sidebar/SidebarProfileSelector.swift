import SwiftUI

/// Compact profile selector for the sidebar footer
struct SidebarProfileSelector: View {
    @ObservedObject var viewModel: ProfilesViewModel
    @State private var showProfilePicker = false

    var body: some View {
        HStack(spacing: 6) {
            Button(action: {
                showProfilePicker.toggle()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: iconName)
                        .font(.system(size: 12))
                        .foregroundColor(iconColor)

                    Text(titleText)
                        .font(.system(size: 12, weight: titleWeight))
                        .foregroundColor(titleColor)
                        .lineLimit(1)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showProfilePicker, arrowEdge: .top) {
                ProfilePickerPopover(viewModel: viewModel)
            }

            SettingsLink {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(nsColor: .controlBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .help(L10n.ProfileEditor.createProfile)
            .simultaneousGesture(TapGesture().onEnded {
                NotificationCenter.default.post(name: .openProfilesSettings, object: nil)
            })
        }
    }

    private var iconName: String {
        viewModel.activeProfile != nil ? "person.crop.rectangle.stack.fill" : "rectangle.dashed"
    }

    private var iconColor: Color {
        viewModel.activeProfile != nil ? .accentColor : .secondary
    }

    private var titleText: String {
        viewModel.activeProfile?.name ?? L10n.Recording.Popup.noProfile
    }

    private var titleWeight: Font.Weight {
        viewModel.activeProfile != nil ? .medium : .regular
    }

    private var titleColor: Color {
        viewModel.activeProfile != nil ? .primary : .secondary
    }
}
