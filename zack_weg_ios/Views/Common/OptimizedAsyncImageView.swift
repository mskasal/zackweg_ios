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

// Zoomable image view with pinch and double-tap zoom
struct ZoomableAsyncImageView: View {
    let imageUrl: String
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            AsyncImage(url: URL(string: imageUrl),
                       transaction: Transaction(animation: .easeInOut)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    
                                    // Limit zoom out
                                    scale = max(1.0, scale * delta)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                    
                                    // Reset to original size if zoomed too far out
                                    if scale < 1.0 {
                                        withAnimation {
                                            scale = 1.0
                                            offset = .zero
                                        }
                                    }
                                }
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    // Only allow dragging when zoomed in
                                    if scale > 1.0 {
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                    
                                    // Reset offset if scale is reset
                                    if scale <= 1.0 {
                                        withAnimation {
                                            offset = .zero
                                        }
                                    }
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation {
                                if scale > 1.0 {
                                    // Reset to original size if already zoomed in
                                    scale = 1.0
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    // Zoom in to 2x on double tap
                                    scale = 2.0
                                }
                            }
                        }
                case .failure:
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

// Full screen image preview view for post images
struct PostImagePreviewView: View {
    let imageUrls: [String]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            TabView {
                ForEach(imageUrls, id: \.self) { imageUrl in
                    ZoomableAsyncImageView(imageUrl: imageUrl)
                }
            }
            #if os(iOS)
            .tabViewStyle(PageTabViewStyle())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.done".localized) {
                        dismiss()
                    }
                }
            }
            #endif
        }
    }
} 