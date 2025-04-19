import SwiftUI
import UIKit

// Image cache for better performance
class ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSString, UIImage>()
    
    private init() {
        // Configure cache limits
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
    }
    
    func set(image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
    
    func get(for key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func prefetchImage(_ urlString: String, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        // Check if already cached
        if let _ = get(for: urlString) {
            completion(true)
            return
        }
        
        // Otherwise download
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil,
                  let image = UIImage(data: data) else {
                completion(false)
                return
            }
            
            self?.set(image: image, for: urlString)
            completion(true)
        }.resume()
    }
}

struct OptimizedAsyncImageView: View {
    let imageUrl: String
    let height: CGFloat
    let onTapAction: (() -> Void)?
    
    @State private var loadedImage: UIImage? = nil
    @State private var isLoading = true
    @State private var loadingFailed = false
    
    init(imageUrl: String, height: CGFloat = 250, onTapAction: (() -> Void)? = nil) {
        self.imageUrl = imageUrl
        self.height = height
        self.onTapAction = onTapAction
    }
    
    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
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
            } else if isLoading {
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
            } else if loadingFailed {
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
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        // Check cache first
        if let cachedImage = ImageCache.shared.get(for: imageUrl) {
            self.loadedImage = cachedImage
            self.isLoading = false
            return
        }
        
        // Download if not cached
        guard let url = URL(string: imageUrl) else {
            self.isLoading = false
            self.loadingFailed = true
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil,
                      let downloadedImage = UIImage(data: data) else {
                    self.isLoading = false
                    self.loadingFailed = true
                    return
                }
                
                ImageCache.shared.set(image: downloadedImage, for: imageUrl)
                self.loadedImage = downloadedImage
                self.isLoading = false
            }
        }.resume()
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
    @State private var loadedImage: UIImage? = nil
    @State private var isLoading = true
    @State private var loadingFailed = false
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                if let image = loadedImage {
                    Image(uiImage: image)
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
                } else if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if loadingFailed {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                loadImage()
            }
        }
    }
    
    private func loadImage() {
        // Check cache first
        if let cachedImage = ImageCache.shared.get(for: imageUrl) {
            self.loadedImage = cachedImage
            self.isLoading = false
            return
        }
        
        // Download if not cached
        guard let url = URL(string: imageUrl) else {
            self.isLoading = false
            self.loadingFailed = true
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil,
                      let downloadedImage = UIImage(data: data) else {
                    self.isLoading = false
                    self.loadingFailed = true
                    return
                }
                
                ImageCache.shared.set(image: downloadedImage, for: imageUrl)
                self.loadedImage = downloadedImage
                self.isLoading = false
            }
        }.resume()
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
        .onAppear {
            // Prefetch all images when the preview opens
            for url in imageUrls {
                ImageCache.shared.prefetchImage(url)
            }
        }
    }
} 