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
    @Binding var updatedPost: Post?
    
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
    
    // Update imagePreviews to use id and data for tracking
    @State private var imagePreviews: [(id: String, data: Data)] = []
    
    @State private var error: String?
    @State private var showSuccess = false
    @State private var isFormValid = false
    @State private var selectedParentCategoryId: String? = nil
    @FocusState private var focusedField: FormField?
    @State private var showCamera = false
    @State private var cameraImage: UIImage?
    
    // Create a computed binding for the error alert
    private var errorAlertIsPresented: Binding<Bool> {
        Binding(
            get: { error != nil },
            set: { if !$0 { error = nil } }
        )
    }
    
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
    
    // Max selectable images (15 total - existing images)
    private var remainingImageSlots: Int {
        return max(0, 15 - (viewModel.imageUrls.count + imagePreviews.count))
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
                    categories: categoryViewModel.topLevelCategories,
                    focusedField: $focusedField
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
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("posts.edit".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button(action: {
                    focusedField = nil
                }) {
                    Image(systemName: "keyboard.chevron.compact.down")
                }
                
                Spacer()
                
                Button(action: {
                    moveToNextField()
                }) {
                    Text("Next")
                }
            }
        }
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
            viewModel.resetImageUploads()
        }
        .alert("common.error".localized, isPresented: errorAlertIsPresented) {
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
            Button(action: saveChanges) {
                updateButtonContent
            }
            .disabled(viewModel.isSaving || !isFormValid || !viewModel.allImagesUploaded)
        }
    }

    // Break down the complex button content into a separate view
    @ViewBuilder
    private var updateButtonContent: some View {
        if viewModel.isSaving {
            savingButtonContent
        } else {
            normalButtonContent
        }
    }
    
    private var savingButtonContent: some View {
        HStack {
            Spacer()
            ProgressView()
                .tint(.white)
            Text("common.saving".localized)
                .fontWeight(.semibold)
                .padding(.leading, 8)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.blue.opacity(0.5))
        .foregroundColor(.white)
        .cornerRadius(10)
    }
    
    private var normalButtonContent: some View {
        HStack {
            Spacer()
            Text("posts.update".localized)
                .fontWeight(.semibold)
            Spacer()
        }
        .padding(.vertical, 14)
        .background(isFormValid && viewModel.allImagesUploaded ? Color.blue : Color.gray.opacity(0.3))
        .foregroundColor(isFormValid && viewModel.allImagesUploaded ? .white : .gray)
        .cornerRadius(10)
    }

    private var editImagesSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                // Image picker buttons
                imagePickerButton
                
                if viewModel.imageUrls.isEmpty && imagePreviews.isEmpty {
                    noImagesView
                } else {
                    // Display existing images first if any
                    if !viewModel.imageUrls.isEmpty {
                        existingImagesView
                    }
                    
                    // Display new images with upload status
                    if !imagePreviews.isEmpty {
                        newImagesView
                    }
                }
            }
            .padding(.vertical, 10)
            .sheet(isPresented: $showCamera) {
                CameraView(image: $cameraImage, isShown: $showCamera)
                    .ignoresSafeArea()
                    .onDisappear {
                        if let image = cameraImage, let imageData = image.jpegData(compressionQuality: 0.8) {
                            let id = UUID().uuidString
                            imagePreviews.append((id: id, data: imageData))
                            viewModel.uploadImage(id: id, imageData: imageData)
                            cameraImage = nil
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
        let isDisabled = maxCount <= 0
        
        return HStack(spacing: 12) {
            // Photo library picker with explicit button style
            PhotosPicker(
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
                .background(isDisabled ? Color.gray.opacity(0.1) : Color.blue.opacity(0.1))
                .foregroundColor(isDisabled ? Color.gray : Color.blue)
                .cornerRadius(8)
            }
            .disabled(isDisabled)
            .buttonStyle(BorderlessButtonStyle()) // Ensure tap area is limited to button
            
            // Camera button with explicit tap area
            Button {
                showCamera = true
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                        .font(.headline)
                }
                .frame(width: 50)
                .padding(.vertical, 12)
                .background(isDisabled ? Color.gray.opacity(0.1) : Color.green.opacity(0.1))
                .foregroundColor(isDisabled ? Color.gray : Color.green)
                .cornerRadius(8)
            }
            .disabled(isDisabled)
            .buttonStyle(BorderlessButtonStyle()) // Ensure tap area is limited to button
        }
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
                HStack(spacing: 14) {
                    ForEach(imagePreviews, id: \.id) { item in
                        let index = imagePreviews.firstIndex(where: { $0.id == item.id }) ?? 0
                        let uploadState = viewModel.imageUploadStates[item.id] ?? .notUploaded
                        
                        UploadableImageView(
                            imageData: item.data,
                            index: index,
                            onDelete: { _ in
                                if let idx = imagePreviews.firstIndex(where: { $0.id == item.id }) {
                                    imagePreviews.remove(at: idx)
                                    viewModel.imageUploadStates.removeValue(forKey: item.id)
                                    
                                    // Also remove from uploadedImageUrls if it was uploaded
                                    if case .uploaded(let url) = uploadState {
                                        if let urlIndex = viewModel.uploadedImageUrls.firstIndex(of: url) {
                                            viewModel.uploadedImageUrls.remove(at: urlIndex)
                                        }
                                    }
                                }
                            },
                            uploadState: Binding(
                                get: { uploadState },
                                set: { viewModel.imageUploadStates[item.id] = $0 }
                            ),
                            onRetry: {
                                viewModel.retryImageUpload(id: item.id, imageData: item.data)
                            }
                        )
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    private func handleImageSelection(_ items: [PhotosPickerItem]) {
        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    let id = UUID().uuidString
                    await MainActor.run {
                        imagePreviews.append((id: id, data: data))
                        viewModel.uploadImage(id: id, imageData: data)
                    }
                }
            }
            
            // Don't clear selection after processing - let the picker stay open
            // selectedImages = []
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
            // With the new approach, we don't need to prepare images here
            // as they are already being uploaded immediately when selected
            
            let updatedPost = try await viewModel.updatePost(
                title: title,
                description: description,
                categoryId: selectedCategory,
                offering: offering.rawValue,
                price: offering == .soldAtPrice ? price : "0",
                status: viewModel.status
            )
            
            // Pass the updated post back through binding
            self.updatedPost = updatedPost
            
            // Show success and dismiss
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
            ZStack(alignment: .topTrailing) {
                OptimizedAsyncImageView(
                    imageUrl: url,
                    height: 100
                )
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                .padding(4)
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
        isFormValid = hasTitleAndDescription && 
                     hasCategorySelected && 
                     hasPriceIfNeeded && 
                     hasImages
    }

    private func moveToNextField() {
        switch focusedField {
        case .title:
            focusedField = .description
        case .description:
            if offering == .soldAtPrice {
                focusedField = .price
            } else {
                focusedField = nil
            }
        case .price:
            focusedField = nil
        case nil:
            break
        }
    }

    private func saveChanges() {
        Task {
            await updateExistingPost()
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

// The CameraView has been moved to a shared component file 

struct ImageDropDelegate: DropDelegate {
    @Binding var items: [(id: String, data: Data)]
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
        
        // Safely move the items
        if items.indices.contains(fromIndex) && items.indices.contains(draggedItem) {
            let itemToMove = items[fromIndex]
            items.remove(at: fromIndex)
            items.insert(itemToMove, at: draggedItem)
        }
    }
}

