import SwiftUI

struct HomeView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = CreatePostViewModel()
    
    var body: some View {
        CreatePostView()
    }
}

#Preview {
    HomeView(authViewModel: AuthViewModel())
}
