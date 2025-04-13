import SwiftUI
import UIKit

// Image upload state for tracking individual uploads
public enum ImageUploadState {
    case notUploaded
    case uploading(progress: Double)
    case uploaded(url: String)
    case failed(error: String)
}

// Component to display and manage a single image upload
public struct UploadableImageView: View {
    let imageData: Data
    let index: Int
    let onDelete: (Int) -> Void
    @Binding var uploadState: ImageUploadState
    var onRetry: (() -> Void)?
    
    public var body: some View {
        // Extract the UIImage conversion to reduce expression complexity
        let uiImage: UIImage? = UIImage(data: imageData)
        
        if let uiImage = uiImage {
            ZStack(alignment: .topTrailing) {
                // Base image
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Overlay based on upload state
                switch uploadState {
                case .notUploaded:
                    Color.black.opacity(0.3)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            ProgressView()
                                .tint(.white)
                        )
                    
                case .uploading(let progress):
                    Color.black.opacity(0.3)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            ZStack {
                                CircularProgressView(progress: progress)
                                    .frame(width: 30, height: 30)
                                Text("\(Int(progress * 100))%")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white)
                            }
                        )
                    
                case .uploaded:
                    Color.clear
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .background(Color.white.opacity(0.7))
                                .clipShape(Circle())
                                .padding(4),
                            alignment: .bottomTrailing
                        )
                    
                case .failed(let errorMessage):
                    Color.black.opacity(0.3)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            VStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 24))
                                
                                Text("Retry")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.red)
                                    .cornerRadius(4)
                            }
                        )
                        .onTapGesture {
                            if let retry = onRetry {
                                retry()
                            }
                        }
                }
                
                // Delete button always visible at top-right
                Button(action: { onDelete(index) }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                        .font(.system(size: 18))
                }
                .padding(4)
            }
            .frame(width: 100, height: 100) // Fixed frame to prevent stretching
        }
    }
}

// Simple circular progress view
public struct CircularProgressView: View {
    var progress: Double
    
    public var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.gray.opacity(0.5),
                    lineWidth: 4
                )
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    Color.white,
                    style: StrokeStyle(
                        lineWidth: 4,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear, value: progress)
        }
    }
} 