import Foundation
import SwiftUI

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    enum Theme: String, CaseIterable, Identifiable {
        case light = "light"
        case dark = "dark"
        case system = "system"
        
        var id: String { self.rawValue }
        
        var displayName: String {
            switch self {
            case .light: return "settings.theme.light".localized
            case .dark: return "settings.theme.dark".localized
            case .system: return "settings.theme.system".localized
            }
        }
        
        var colorScheme: ColorScheme? {
            switch self {
            case .light: return .light
            case .dark: return .dark
            case .system: return nil
            }
        }
    }
    
    @Published var currentTheme: Theme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "app_theme")
        }
    }
    
    private init() {
        let savedTheme = UserDefaults.standard.string(forKey: "app_theme") ?? Theme.system.rawValue
        self.currentTheme = Theme(rawValue: savedTheme) ?? .system
    }
} 