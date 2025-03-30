import SwiftUI

struct SplashView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var size = 0.8
    @State private var opacity = 0.5
    
    var body: some View {
            ZStack {
                (themeManager.currentTheme == .dark ? Color.black : Color.white)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Image(themeManager.currentTheme == .dark ? "Logo-nobg" : "Logo-no-bg-reverse-blue")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 240, height: 240)
                }
                .scaleEffect(size)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.2)) {
                        self.size = 1.0
                        self.opacity = 1.0
                    }
                }
            }
    }
}

#Preview {
    SplashView()
        .environmentObject(ThemeManager.shared)
} 
