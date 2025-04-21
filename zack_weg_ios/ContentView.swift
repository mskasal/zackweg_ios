//
//  ContentView.swift
//  zack_weg_ios
//
//  Created by Mustafa Samed Kasal on 25.03.25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel.shared
    @StateObject private var unreadMessagesViewModel = UnreadMessagesViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showDebugMenu = false
    @State private var isShowingSplash = true
    @State private var refreshID = UUID() // Add a refresh ID to force view updates
    
    var body: some View {
        ZStack {
            // Main app content
            ZStack(alignment: .topTrailing) {
                TabView(selection: $authViewModel.selectedTab) {
                    NavigationStack {
                        HomeView()
                            .environmentObject(authViewModel)
                    }
                    .tabItem {
                        Label("tab.home".localized, systemImage: "house.fill")
                    }
                    .tag(0)
                    
                    NavigationStack {
                        ExploreView()
                    }
                    .tabItem {
                        Label("explore.title".localized, systemImage: "magnifyingglass")
                    }
                    .tag(1)
                    
                    if authViewModel.isAuthenticated {
                        NavigationStack {
                            CreatePostView()
                        }
                        .tabItem {
                            Label("posts.create".localized, systemImage: "plus.circle.fill")
                        }
                        .tag(2)
                        
                        NavigationStack {
                            MessagesView()
                        }
                        .tabItem {
                            Label("messages.title".localized, systemImage: "message.fill")
                        }
                        .badge(unreadMessagesViewModel.unreadCount)
                        .tag(3)
                    }
                    
                    NavigationStack {
                        if authViewModel.isAuthenticated {
                            ProfileView()
                        } else {
                            SignInView(authViewModel: authViewModel)
                        }
                    }
                    .tabItem {
                        Label(authViewModel.isAuthenticated ? "profile.title".localized : "auth.sign_in".localized, 
                              systemImage: "person.fill")
                    }
                    .tag(4)
                    .environmentObject(authViewModel)
                }
                .id(refreshID) // Force the TabView to rebuild when this changes
                .environmentObject(unreadMessagesViewModel)
                
                // Debug button - only shown in DEBUG builds
                #if DEBUG
                Button(action: {
                    showDebugMenu = true
                }) {
                    Image(systemName: "ladybug.fill")
                        .foregroundColor(.red)
                        .padding(6)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                .padding(.top, 15)
                .padding(.trailing, 20)
                .sheet(isPresented: $showDebugMenu) {
                    DebugMenuView()
                }
                #endif
            }
            .opacity(isShowingSplash ? 0 : 1)
            
            // Splash screen
            if isShowingSplash {
                SplashView()
                    .onAppear {
                        // Simply wait 2 seconds then show the main content
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            isShowingSplash = false
                        }
                    }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            if authViewModel.isAuthenticated {
                unreadMessagesViewModel.refreshUnreadCount()
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { newValue in
            // Force TabView to refresh when authentication state changes
            refreshID = UUID()
            
            // Also refresh unread messages count if authenticated
            if newValue {
                unreadMessagesViewModel.refreshUnreadCount()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager.shared)
}
