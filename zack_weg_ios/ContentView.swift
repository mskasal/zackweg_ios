//
//  ContentView.swift
//  zack_weg_ios
//
//  Created by Mustafa Samed Kasal on 25.03.25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var unreadMessagesViewModel = UnreadMessagesViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showDebugMenu = false
    @State private var isShowingSplash = true
    
    var body: some View {
        ZStack {
            // Main app content
            ZStack(alignment: .topTrailing) {
                Group {
                    if authViewModel.isAuthenticated {
                        TabView(selection: $authViewModel.selectedTab) {
                            NavigationStack {
                                HomeView()
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
                            
                            NavigationStack {
                                SettingsView()
                            }
                            .tabItem {
                                Label("settings.title".localized, systemImage: "person.fill")
                            }
                            .tag(4)
                            .environmentObject(authViewModel)
                        }
                        .environmentObject(unreadMessagesViewModel)
                    } else {
                        NavigationStack {
                            SignInView(authViewModel: authViewModel)
                        }
                    }
                }
                
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
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager.shared)
}
