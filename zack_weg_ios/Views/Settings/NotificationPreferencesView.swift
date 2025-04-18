import SwiftUI

struct NotificationPreferencesView: View {
    @StateObject private var viewModel = NotificationPreferencesViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // Group preferences by type for better organization
    private var groupedPreferences: [NotificationType: [NotificationPreference]] {
        Dictionary(grouping: viewModel.notificationPreferences) { $0.type }
    }
    
    var body: some View {
        ZStack {
            List {
                // Help text section
                Section {
                    Text("settings.notifications.help_text".localized)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                // Message Notifications Section
                if let messagePrefs = groupedPreferences[.userMessage] {
                    Section(header: Text("settings.notifications.messages".localized)) {
                        ForEach(messagePrefs) { pref in
                            NotificationToggleRow(
                                title: channelTitle(for: pref.channel),
                                isOn: pref.enabled,
                                iconName: channelIcon(for: pref.channel)
                            ) { isEnabled in
                                Task {
                                    await viewModel.updatePreference(
                                        type: pref.type,
                                        channel: pref.channel,
                                        enabled: isEnabled
                                    )
                                }
                            }
                        }
                    }
                }
                
                // Campaign/Marketing Notifications Section
                if let campaignPrefs = groupedPreferences[.campaign] {
                    Section(header: Text("settings.notifications.marketing".localized)) {
                        ForEach(campaignPrefs) { pref in
                            NotificationToggleRow(
                                title: channelTitle(for: pref.channel),
                                isOn: pref.enabled,
                                iconName: channelIcon(for: pref.channel)
                            ) { isEnabled in
                                Task {
                                    await viewModel.updatePreference(
                                        type: pref.type,
                                        channel: pref.channel,
                                        enabled: isEnabled
                                    )
                                }
                            }
                        }
                    }
                }
                
                if let error = viewModel.error {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("settings.notifications".localized)
            .refreshable {
                Task {
                    await viewModel.fetchNotificationPreferences()
                }
            }
            .overlay(
                viewModel.notificationPreferences.isEmpty && !viewModel.isLoading ?
                ContentUnavailableView(
                    label: {
                        Label("settings.notifications.unavailable".localized, systemImage: "bell.slash")
                    },
                    description: {
                        Text("settings.notifications.try_again".localized)
                    },
                    actions: {
                        Button(action: {
                            Task {
                                await viewModel.fetchNotificationPreferences()
                            }
                        }) {
                            Text("common.refresh".localized)
                        }
                        .buttonStyle(.bordered)
                    }
                )
                : nil
            )
            
            if viewModel.isLoading {
                Color.black.opacity(0.2)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    )
                    .zIndex(2)
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchNotificationPreferences()
            }
        }
    }
    
    // Helper functions to translate channel type to UI elements
    private func channelTitle(for channel: NotificationChannel) -> String {
        switch channel {
        case .email:
            return "settings.notifications.email".localized
        case .mobilePush:
            return "settings.notifications.push".localized
        }
    }
    
    private func channelIcon(for channel: NotificationChannel) -> String {
        switch channel {
        case .email:
            return "envelope"
        case .mobilePush:
            return "iphone.gen3.badge.exclamationmark"
        }
    }
}

// Reusable notification toggle row
struct NotificationToggleRow: View {
    let title: String
    @State var isOn: Bool
    let iconName: String
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Toggle(isOn: Binding(
            get: { isOn },
            set: { newValue in
                isOn = newValue
                onToggle(newValue)
            }
        )) {
            Label {
                Text(title)
            } icon: {
                Image(systemName: iconName)
            }
        }
    }
}

#Preview {
    NavigationView {
        NotificationPreferencesView()
    }
} 