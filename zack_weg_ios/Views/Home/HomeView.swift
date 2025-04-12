import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = CreatePostViewModel()
    
    var body: some View {
        VStack(spacing: 20) {}
    }
}

#Preview {
    HomeView()
}
