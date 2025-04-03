import Foundation
import SwiftUI

@available(iOS 14.0, *)
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: Language {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "app_language")
            applyLanguage()
        }
    }
    
    enum Language: String, CaseIterable, Identifiable {
        case english = "en"
        case german = "de"
        case turkish = "tr"
        
        var id: String { self.rawValue }
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .german: return "Deutsch"
            case .turkish: return "Türkçe"
            }
        }
        
        var localeIdentifier: String {
            switch self {
            case .english: return "en-US"
            case .german: return "de-DE"
            case .turkish: return "tr-TR"
            }
        }
    }
    
    private init() {
        let savedLanguage = UserDefaults.standard.string(forKey: "app_language") ?? Language.english.rawValue
        self.currentLanguage = Language(rawValue: savedLanguage) ?? .english
    }
    
    func configureAppLanguage() {
        applyLanguage()
    }
    
    private func applyLanguage() {
        // Set the preferred language for the app
        UserDefaults.standard.set([currentLanguage.rawValue], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // For current app session - without requiring restart
        Bundle.setLanguage(currentLanguage.rawValue)
    }
}

// Extension to reload the bundle when language changes
extension Bundle {
    private static var bundle: Bundle?
    
    static func setLanguage(_ language: String) {
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj") else {
            bundle = Bundle.main
            return
        }
        
        bundle = Bundle(path: path)
    }
    
    static func localizedString(for key: String, value: String? = nil) -> String {
        let bundle = self.bundle ?? Bundle.main
        return bundle.localizedString(forKey: key, value: value, table: nil)
    }
}

// Extension to make localization more convenient
extension String {
    var localized: String {
        return Bundle.localizedString(for: self)
    }
} 
