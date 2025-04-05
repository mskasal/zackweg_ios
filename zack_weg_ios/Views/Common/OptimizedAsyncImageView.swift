import SwiftUI

struct OptimizedAsyncImageView: View {
    let imageUrl: String
    let height: CGFloat
    let onTapAction: (() -> Void)?
    
    init(imageUrl: String, height: CGFloat = 250, onTapAction: (() -> Void)? = nil) {
        self.imageUrl = imageUrl
        self.height = height
        self.onTapAction = onTapAction
    }
    
    var body: some View {
        AsyncImage(url: URL(string: imageUrl), 
                   transaction: Transaction(animation: .easeInOut)) { phase in
            switch phase {
            case .empty:
                // Placeholder with shimmer effect
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                    )
                    .frame(height: height)
                    .clipped()
                    .transition(.opacity)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: height)
                    .clipped()
                    .transition(.opacity)
                    .onTapGesture {
                        if let action = onTapAction {
                            action()
                        }
                    }
            case .failure:
                // Error placeholder
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title)
                            .foregroundColor(.gray)
                    )
                    .frame(height: height)
                    .clipped()
            @unknown default:
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: height)
                    .clipped()
            }
        }
    }
}

// Empty image placeholder for when there are no images
struct EmptyImagePlaceholderView: View {
    let height: CGFloat
    
    init(height: CGFloat = 250) {
        self.height = height
    }
    
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(height: height)
            .overlay(
                Image(systemName: "photo.fill")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
            )
    }
} 