import SwiftUI

enum Tab: Hashable {
    case home
    case explore
    case messages
    case settings
}

class NavigationState: ObservableObject {
    @Published var selectedTab: Tab = .home
    @Published var isAuthenticated: Bool = false
    
    func signIn() {
        isAuthenticated = true
    }
    
    func signOut() {
        isAuthenticated = false
    }
} 