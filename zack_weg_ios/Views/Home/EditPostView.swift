import PhotosUI
import SwiftUI
import UIKit

// Status selection card component
struct StatusCardView: View {
    let isSelected: Bool
    let title: String
    let icon: String
    let iconColor: Color
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title.localized)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(description.localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    .background(isSelected ? Color.blue.opacity(0.1) : Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EditPostView: View {
    let postId: String
    @Binding var shouldRefresh: Bool
    
    @StateObject private var viewModel = EditPostViewModel()
    @EnvironmentObject private var categoryViewModel: CategoryViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Form state properties
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory = ""
    @State private var offering = PostOffering.givingAway
    @State private var price = ""
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var imagePreviews: [Data] = []
    @State private var error: String?
    @State private var showSuccess = false
    @State private var isFormValid = false
    @State private var selectedParentCategoryId: String? = nil
    
    // Computed properties to break down complex expressions
    private var hasTitleAndDescription: Bool {
        return !title.isEmpty && !description.isEmpty
    }
    
    private var hasCategorySelected: Bool {
        return !selectedCategory.isEmpty
    }
    
    private var hasPriceIfNeeded: Bool {
        return offering == .givingAway || (offering == .soldAtPrice && !price.isEmpty)
    }
    
    // Max selectable images (5 total - existing images)
    private var remainingImageSlots: Int {
        return max(0, 5 - (viewModel.imageUrls.count + imagePreviews.count))
    }
    
    private var hasImages: Bool {
        return !viewModel.imageUrls.isEmpty || !imagePreviews.isEmpty
    }

    var body: some View {
        Form {
            if viewModel.isLoading {
                loadingSection
            } else if let post = viewModel.post {
                EditPostFormHeaderView()
                
                PostDetailsSection(
                    title: $title,
                    description: $description,
                    selectedCategory: $selectedCategory,
                    selectedParentCategoryId: $selectedParentCategoryId,
                    offering: $offering,
                    price: $price,
                    categories: categoryViewModel.topLevelCategories
                )
                
                // Status selection section - highlighted for visibility
                statusSelectionSection
                
                // EditImagesSection - Modified for editing
                editImagesSection
                
                LocationSection()
                
                // Update Button Section
                updateButtonSection
            } else {
                errorSection
            }
        }
        .navigationTitle("posts.edit".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedImages) { items in
            handleImageSelection(items)
        }
        .onChange(of: title) { _ in validateForm() }
        .onChange(of: description) { _ in validateForm() }
        .onChange(of: selectedCategory) { _ in validateForm() }
        .onChange(of: price) { _ in validateForm() }
        .onChange(of: offering) { _ in validateForm() }
        .onChange(of: viewModel.imageUrls.count) { _ in validateForm() }
        .onChange(of: imagePreviews.count) { _ in validateForm() }
        .onChange(of: viewModel.status) { _ in validateForm() }
        .task {
            await loadPostData()
        }
        .alert("common.error".localized, isPresented: .constant(error != nil)) {
            Button("common.ok".localized) {
                error = nil
            }
        } message: {
            Text(error ?? "")
        }
        .alert("common.success".localized, isPresented: $showSuccess) {
            Button("common.ok".localized, role: .cancel) {
                dismiss()
            }
        } message: {
            Text("posts.post_updated".localized)
        }
    }
    
    // MARK: - Extracted View Components

    private var loadingSection: some View {
        Section {
            HStack {
                Spacer()
                VStack(spacing: 16) {
                    ProgressView()
                    Text("common.loading".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
        }
    }

    private var errorSection: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                Text("posts.failed_to_load".localized)
                    .font(.headline)
                if let error = viewModel.error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                Button("common.retry".localized) {
                    Task {
                        await viewModel.loadPost(postId: postId)
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
    }

    private var updateButtonSection: some View {
        Section {
            Button(action: {
                Task {
                    await updateExistingPost()
                }
            }) {
                HStack {
                    Spacer()
                    if viewModel.isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("posts.update".localized)
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
                .padding(.vertical, 16)
                .background(isFormValid ? Color.blue : Color.gray.opacity(0.5))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(viewModel.isSaving || !isFormValid)
            
            if !isFormValid {
                Text("posts.fill_required".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .listRowBackground(Color.clear)
    }

    private var editImagesSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                // Image picker button
                imagePickerButton
                
                if !hasImages {
                    noImagesView
                } else {
                    // Image count display
                    let totalImagesCount = viewModel.imageUrls.count + imagePreviews.count
                    Text(String(format: "posts.images_count".localized, totalImagesCount))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    
                    // Display existing images if available
                    if !viewModel.imageUrls.isEmpty {
                        existingImagesView
                    }
                    
                    // Display new images if available
                    if !imagePreviews.isEmpty {
                        newImagesView
                    }
                }
            }
        } header: {
            Text("posts.photos".localized)
                .font(.footnote)
                .fontWeight(.semibold)
        } footer: {
            Text("posts.images_footer".localized)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var imagePickerButton: some View {
        // Create a fixed property for maxSelectionCount
        let maxCount = remainingImageSlots
        
        return PhotosPicker(
            selection: $selectedImages,
            maxSelectionCount: maxCount,
            matching: .images
        ) {
            HStack {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.headline)
                Text("posts.select_images".localized)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(8)
        }
        .disabled(maxCount <= 0)
    }

    private var noImagesView: some View {
        Text("posts.images_help".localized)
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.vertical, 8)
    }

    private var existingImagesView: some View {
        VStack(alignment: .leading) {
            Text("posts.existing_images".localized)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(zip(viewModel.imageUrls.indices, viewModel.imageUrls)), id: \.0) { index, url in
                        ExistingImageView(url: url, index: index, onDelete: { 
                            viewModel.removeImage(at: index)
                        })
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    private var newImagesView: some View {
        VStack(alignment: .leading) {
            Text("posts.new_images".localized)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<imagePreviews.count, id: \.self) { index in
                        let imageData = imagePreviews[index]
                        ImagePreviewView(
                            imageData: imageData,
                            index: index,
                            onDelete: { index in
                                selectedImages.remove(at: index)
                                imagePreviews.remove(at: index)
                            }
                        )
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    private var statusSelectionSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("posts.post_status".localized)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.bottom, 4)
                
                StatusCardView(
                    isSelected: viewModel.status == "ACTIVE",
                    title: "posts.status_active",
                    icon: "checkmark.circle.fill",
                    iconColor: .green,
                    description: "posts.status_active_desc"
                ) {
                    viewModel.status = "ACTIVE"
                }
                .padding(.vertical, 4)
                
                StatusCardView(
                    isSelected: viewModel.status == "ARCHIVED",
                    title: "posts.status_archived",
                    icon: "archivebox.fill",
                    iconColor: .orange,
                    description: "posts.status_archived_desc"
                ) {
                    viewModel.status = "ARCHIVED"
                }
                .padding(.vertical, 4)
            }
        }
        .listRowBackground(Color.yellow.opacity(0.1)) // Highlighted background
        .padding(.vertical, 8)
    }

    // MARK: - Helper Functions

    private func validateForm() {
        // Check if any field has changed from the original post
        let hasChanges = viewModel.post.map { post in
            title != post.title ||
            description != post.description ||
            selectedCategory != post.categoryId ||
            offering.rawValue != post.offering ||
            (offering == .soldAtPrice ? price != String(format: "%.2f", post.price ?? 0) : false) ||
            viewModel.status != post.status ||
            !imagePreviews.isEmpty ||
            !viewModel.removedImageUrls.isEmpty
        } ?? false
        
        // Also ensure all required fields are filled
        let hasRequiredFields = hasTitleAndDescription && 
                              hasCategorySelected && 
                              hasPriceIfNeeded && 
                              hasImages &&
                              !viewModel.status.isEmpty
        
        isFormValid = hasChanges && hasRequiredFields
    }

    private func handleImageSelection(_ items: [PhotosPickerItem]) {
        Task {
            // Process new images
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    imagePreviews.append(data)
                }
            }
        }
    }

    private func loadPostData() async {
        // Load the post data
        await viewModel.loadPost(postId: postId)
        
        // Populate form fields when post is loaded
        if let post = viewModel.post {
            populateFormFields(with: post)
        }
    }

    private func populateFormFields(with post: Post) {
        title = post.title
        description = post.description
        selectedCategory = post.categoryId
        
        // Find the parent category
        if let category = categoryViewModel.getCategory(byId: post.categoryId) {
            selectedCategory = category.id
            
            // If this is a subcategory, find its parent
            if let parentCategory = categoryViewModel.getParentCategory(for: category.id) {
                selectedParentCategoryId = parentCategory.id
            } else {
                // This is a top-level category
                selectedParentCategoryId = category.id
            }
        }
        
        // Set offering enum from string
        if let offeringEnum = PostOffering(rawValue: post.offering) {
            offering = offeringEnum
        }
        
        // Set price if available
        if let postPrice = post.price {
            price = String(format: "%.2f", postPrice)
        }
        
        // Validate the form with the loaded data
        validateForm()
    }

    private func updateExistingPost() async {
        do {
            // Prepare new image data for upload
            for imageData in imagePreviews {
                viewModel.addImage(imageData)
            }
            
            try await viewModel.updatePost(
                title: title,
                description: description,
                categoryId: selectedCategory,
                offering: offering.rawValue,
                price: offering == .soldAtPrice ? price : "0",
                status: viewModel.status
            )
            shouldRefresh = true
            showSuccess = true
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Helper Views

    struct ExistingImageView: View {
        let url: String
        let index: Int
        let onDelete: () -> Void
        
        var body: some View {
            AsyncImage(url: URL(string: url)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 100, height: 100)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            Button(action: onDelete) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            .padding(4),
                            alignment: .topTrailing
                        )
                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "photo.fill")
                                .foregroundColor(.gray)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                @unknown default:
                    EmptyView()
                }
            }
        }
    }
}

struct EditPostFormHeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("posts.update_post".localized)
                .font(.title2)
                .fontWeight(.bold)
                
            Text("posts.update_details".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
    }
} 
