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
    @State private var isProcessingImages = false
    
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
        .onDisappear {
            // Cleanup resources
            viewModel.cleanup()
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
                
                // Image processing indicator
                if isProcessingImages {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        
                        Text("Processing images...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
                }
                
                // Retry button for failed uploads
                if !viewModel.failedUploads.isEmpty {
                    Button(action: {
                        Task {
                            await retryFailedUploads()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .font(.subheadline)
                            Text("Retry Failed Uploads (\(viewModel.failedUploads.count))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                    }
                }
                
                // Upload progress indicator
                if viewModel.isUploading {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Uploading images (\(viewModel.currentUploadIndex)/\(viewModel.totalUploads))...")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        ProgressView(value: viewModel.uploadProgress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle())
                            .frame(height: 8)
                    }
                    .padding(.vertical, 8)
                }
                
                if !hasImages && !isProcessingImages {
                    noImagesView
                } else if !isProcessingImages {
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
                    
                    // Reordering explanation when multiple images exist
                    if (imagePreviews.count + viewModel.imageUrls.count) > 1 {
                        Text("Drag and drop to reorder images. The first image will be shown as the main image.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
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
                        .onDrag {
                            NSItemProvider(object: "\(index)" as NSString)
                        }
                        .onDrop(of: [.text], delegate: ExistingImageDropDelegate(
                            items: $viewModel.imageUrls,
                            draggedItem: index
                        ))
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
                    ForEach(Array(imagePreviews.indices), id: \.self) { index in
                        let imageData = imagePreviews[index]
                        ImagePreviewView(
                            imageData: imageData,
                            index: index,
                            onDelete: { deletionIndex in
                                // Safely delete by checking indices first
                                safelyDeleteImage(at: deletionIndex)
                            }
                        )
                        .onDrag {
                            // Store the index for reordering
                            NSItemProvider(object: "\(index)" as NSString)
                        }
                        .onDrop(of: [.text], delegate: ImageDropDelegate(
                            items: $imagePreviews,
                            draggedItem: index,
                            selectedItems: $selectedImages
                        ))
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    private func safelyDeleteImage(at index: Int) {
        // First ensure index is valid
        guard index >= 0 else { return }
        
        // Create local copy of arrays to manipulate
        var previewsCopy = imagePreviews
        var selectedCopy = selectedImages
        
        // Check bounds for imagePreviews
        if index < previewsCopy.count {
            previewsCopy.remove(at: index)
        }
        
        // Check bounds for selectedImages - ensure it has at least as many items
        if index < selectedCopy.count {
            selectedCopy.remove(at: index)
        } else {
            // If arrays got out of sync, just update previews
            imagePreviews = previewsCopy
            return
        }
        
        // Update both arrays at once to maintain sync
        imagePreviews = previewsCopy
        selectedImages = selectedCopy
    }

    private func handleImageSelection(_ items: [PhotosPickerItem]) {
        Task {
            // Show image processing indicator
            isProcessingImages = true
            
            // Keep track of the current count to handle sequential updates
            let initialPreviewCount = imagePreviews.count
            var successCount = 0
            var failedCount = 0
            
            // Create a temporary array for successful items to maintain synchronization
            var validItems: [PhotosPickerItem] = []
            var validPreviews: [Data] = []
            
            // Process new images with validation and feedback
            for (index, item) in items.enumerated() {
                do {
                    if let data = try await item.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: data) {
                            // Basic image validation
                            if uiImage.size.width > 0 && uiImage.size.height > 0 {
                                validPreviews.append(data)
                                validItems.append(item)
                                successCount += 1
                            } else {
                                failedCount += 1
                                print("⚠️ Invalid image dimensions for item \(index)")
                            }
                        } else {
                            failedCount += 1
                            print("⚠️ Could not create UIImage from data for item \(index)")
                        }
                    }
                } catch {
                    failedCount += 1
                    print("⚠️ Failed to load image \(index): \(error.localizedDescription)")
                }
            }
            
            // Update the arrays together to maintain synchronization
            if !validItems.isEmpty {
                // Replace the picker selection with only valid items
                selectedImages = validItems
                imagePreviews = validPreviews
            }
            
            // Provide feedback if any images failed to load
            if failedCount > 0 {
                error = "Failed to load \(failedCount) image(s). Please try different images."
            }
            
            // Hide image processing indicator
            isProcessingImages = false
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
            // Synchronize image arrays to ensure consistency
            viewModel.synchronizeImageArrays()
            
            // Prepare new image data for upload with validation
            for imageData in imagePreviews {
                let success = viewModel.addImage(imageData)
                if !success {
                    // If image validation fails, stop and show error
                    error = viewModel.error
                    return
                }
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

    private func retryFailedUploads() async {
        do {
            await viewModel.retryFailedUploads()
            validateForm()
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

    struct ImagePreviewView: View {
        let imageData: Data
        let index: Int
        let onDelete: (Int) -> Void
        @State private var isDeleting = false
        
        var body: some View {
            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        Button(action: {
                            withAnimation {
                                isDeleting = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    // Pass the current index - not capturing the closure index
                                    onDelete(index)
                                }
                            }
                        }) {
                            Image(systemName: isDeleting ? "hourglass" : "xmark.circle.fill")
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(4)
                        .disabled(isDeleting),
                        alignment: .topTrailing
                    )
                    .opacity(isDeleting ? 0.5 : 1.0)
            } else {
                // Invalid image placeholder
                Rectangle()
                    .fill(Color.red.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .overlay(
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text("Invalid")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    struct ImageDropDelegate: DropDelegate {
        @Binding var items: [Data]
        let draggedItem: Int
        @Binding var selectedItems: [PhotosPickerItem]
        
        func performDrop(info: DropInfo) -> Bool {
            return true
        }
        
        func dropEntered(info: DropInfo) {
            guard let fromIndex = Int(info.itemProviders(for: [.text]).first?.registeredTypeIdentifiers.first ?? "") else {
                return
            }
            
            // Exit if trying to drop onto itself
            if draggedItem == fromIndex {
                return
            }
            
            // Safely move the item in both arrays
            if items.indices.contains(fromIndex) && items.indices.contains(draggedItem) {
                let itemToMove = items[fromIndex]
                items.remove(at: fromIndex)
                items.insert(itemToMove, at: draggedItem)
                
                // Do the same for the PhotosPickerItems
                if selectedItems.indices.contains(fromIndex) && selectedItems.indices.contains(draggedItem) {
                    let selectionToMove = selectedItems[fromIndex]
                    selectedItems.remove(at: fromIndex)
                    selectedItems.insert(selectionToMove, at: draggedItem)
                }
            }
        }
    }

    struct ExistingImageDropDelegate: DropDelegate {
        @Binding var items: [String]
        let draggedItem: Int
        
        func performDrop(info: DropInfo) -> Bool {
            return true
        }
        
        func dropEntered(info: DropInfo) {
            guard let fromIndex = Int(info.itemProviders(for: [.text]).first?.registeredTypeIdentifiers.first ?? "") else {
                return
            }
            
            // Exit if trying to drop onto itself
            if draggedItem == fromIndex {
                return
            }
            
            // Safely move the item
            if items.indices.contains(fromIndex) && items.indices.contains(draggedItem) {
                let itemToMove = items[fromIndex]
                items.remove(at: fromIndex)
                items.insert(itemToMove, at: draggedItem)
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
