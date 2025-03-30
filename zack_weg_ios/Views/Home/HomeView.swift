import SwiftUI

struct HomeView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = CreatePostViewModel()
    
    var body: some View {
        CreatePostView(viewModel: viewModel)
            .navigationTitle("posts.create".localized)
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    HomeView(authViewModel: AuthViewModel())
}
