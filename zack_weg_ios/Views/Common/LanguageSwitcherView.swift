import SwiftUI

struct LanguageSwitcherView: View {
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        Menu {
            ForEach(LanguageManager.Language.allCases) { language in
                Button(action: {
                    languageManager.currentLanguage = language
                },label: {
                    HStack {
                        Text(language.displayName)
                            .font(.caption)
                            .foregroundColor(.primary);
                    
                        if languageManager.currentLanguage == language {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                })
                .padding()
                .accessibilityIdentifier("languageOption_\(language.rawValue)")
            }
        } label: {
            HStack(spacing: 8) {
                Text(getFlagEmoji(for: languageManager.currentLanguage))
                    .font(.title2);
                Text(languageManager.currentLanguage.displayName)
                    .foregroundColor(.primary);
            }
        }
        .accessibilityIdentifier("languageSwitcherButton")
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
