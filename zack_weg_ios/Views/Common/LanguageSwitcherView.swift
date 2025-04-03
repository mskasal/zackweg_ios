import SwiftUI

struct LanguageSwitcherView: View {
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        Menu {
            ForEach(LanguageManager.Language.allCases) { language in
                Button(action: {
                    languageManager.currentLanguage = language
                }) {
                    HStack {
                        Text(getFlagEmoji(for: language))
                        Text(language.displayName)
                            .font(.caption)
                            .foregroundColor(.blue)
                        if languageManager.currentLanguage == language {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(getFlagEmoji(for: languageManager.currentLanguage))
                    .font(.title2);
                Text(languageManager.currentLanguage.displayName)
                    .foregroundColor(.primary);
            }
        }
    }
    
    private func getFlagEmoji(for language: LanguageManager.Language) -> String {
        switch language {
        case .english: return "🇬🇧"
        case .german: return "🇩🇪"
        case .turkish: return "🇹🇷"
        }
    }
}

#Preview {
    LanguageSwitcherView()
        .environmentObject(LanguageManager.shared)
} 
