import PhotosUI
import SwiftUI
import UIKit

// Define Field enum at top level
enum FormField {
    case title, description, price
}

struct ImagePreviewView: View {
    let imageData: Data
    let index: Int
    let onDelete: (Int) -> Void
    
    var body: some View {
        // Extract the UIImage conversion to reduce expression complexity
        let uiImage: UIImage? = UIImage(data: imageData)
        
        if let uiImage = uiImage {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    Button(action: { onDelete(index) }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(4),
                    alignment: .topTrailing
                )
        }
    }
}

struct CategoryPill: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

struct OfferingTypeCardView: View {
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

struct PriceInputView: View {
    @Binding var price: String
    @Binding var isFocused: Bool
    @FocusState.Binding var focusState: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("posts.price".localized)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "eurosign")
                    .foregroundColor(.secondary)
                    .font(.headline)
                
                TextField("0,00", text: $price)
                    .focused($focusState)
                    .keyboardType(.decimalPad)
                    .submitLabel(.done)
                    .onChange(of: price) { newValue in
                        // Replace dots with commas for German number format
                        if newValue.contains(".") {
                            price = newValue.replacingOccurrences(of: ".", with: ",")
                        }
                    }
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                focusState = false
                            }
                        }
                    }
            }
            .padding()
            .background(Color(.systemGray6).opacity(0.5))
            .cornerRadius(8)
        }
    }
}

struct CategorySelectionView: View {
    @Binding var selectedCategory: String
    @Binding var selectedParentCategoryId: String?
    let categories: [Category]
    @EnvironmentObject private var categoryViewModel: CategoryViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if categories.isEmpty {
                Text("posts.loading_categories".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                // Show all categories with selected one first
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        // Use getSortedByCategoryId to put selected category first
                        ForEach(categoryViewModel.getSortedByCategoryId(selectedCategory), id: \.id) { category in
                            CategoryPill(
                                category: category,
                                isSelected: selectedCategory == category.id
                            ) {
                                selectedCategory = category.id
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }
}

struct TitleInputView: View {
    @Binding var title: String
    @Binding var isFocused: Bool
    @FocusState.Binding var focusState: Bool
    var nextFieldAction: (() -> Void)?
    
    var body: some View {
        TextField("posts.title_field".localized, text: $title)
            .focused($focusState)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Color(.systemGray6).opacity(0.5))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .padding(.vertical, 6)
            .submitLabel(.next)
            .onSubmit {
                nextFieldAction?()
            }
    }
}

struct DescriptionInputView: View {
    @Binding var description: String
    @Binding var isFocused: Bool
    @FocusState.Binding var focusState: Bool
    var nextFieldAction: (() -> Void)?
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $description)
                .focused($focusState)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            
            if description.isEmpty {
                Text("posts.description".localized)
                    .font(.body)
                    .foregroundColor(.secondary.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .allowsHitTesting(false)
            }
        }
        .padding(.vertical, 6)
        
        // Character count indicator
        HStack {
            Text("\(description.count)/10 " + "posts.min_chars".localized)
                .font(.caption)
                .foregroundColor(description.count >= 10 ? .green : .orange)
            
            Spacer()
        }
        .padding(.bottom, 10)
    }
}

struct OfferingSelectionView: View {
    @Binding var offering: PostOffering
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            OfferingTypeCardView(
                isSelected: offering == .givingAway,
                title: "posts.give_away".localized,
                icon: "gift.fill",
                iconColor: .green,
                description: "posts.give_away_desc".localized
            ) {
                offering = .givingAway
            }
            
            OfferingTypeCardView(
                isSelected: offering == .soldAtPrice,
                title: "posts.sell".localized,
                icon: "eurosign.circle.fill",
                iconColor: .blue,
                description: "posts.sell_desc".localized
            ) {
                offering = .soldAtPrice
            }
        }
    }
}

struct PostDetailsSection: View {
    @Binding var title: String
    @Binding var description: String
    @Binding var selectedCategory: String
    @Binding var selectedParentCategoryId: String?
    @Binding var offering: PostOffering
    @Binding var price: String
    let categories: [Category]
    @Environment(\.colorScheme) private var colorScheme
    @FocusState.Binding var focusedField: FormField?
    
    // Create FocusState for each field
    @FocusState private var titleFocus: Bool
    @FocusState private var descriptionFocus: Bool
    @FocusState private var priceFocus: Bool
    
    var body: some View {
        Section {
            VStack(spacing: 16) {
                // Use TitleInputView with direct FocusState
                TextField("posts.title_field".localized, text: $title)
                    .focused($titleFocus)
                    .focused($focusedField, equals: .title)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.vertical, 6)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .description
                    }
                
                // Use direct TextEditor for description
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $description)
                        .focused($descriptionFocus)
                        .focused($focusedField, equals: .description)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Color(.systemGray6).opacity(0.5))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    
                    if description.isEmpty {
                        Text("posts.description".localized)
                            .font(.body)
                            .foregroundColor(.secondary.opacity(0.8))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false)
                    }
                }
                .padding(.vertical, 6)
                
                // Character count indicator
                HStack {
                    Text("\(description.count)/10 " + "posts.min_chars".localized)
                        .font(.caption)
                        .foregroundColor(description.count >= 10 ? .green : .orange)
                    
                    Spacer()
                }
                .padding(.bottom, 10)
                
                Divider()
                    .padding(.vertical, 4)
                
                Text("posts.category".localized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                CategorySelectionView(
                    selectedCategory: $selectedCategory,
                    selectedParentCategoryId: $selectedParentCategoryId,
                    categories: categories
                )
                
                Divider()
                    .padding(.vertical, 4)
                
                Text("posts.offering_question".localized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                OfferingSelectionView(offering: $offering)
                
                if offering == .soldAtPrice {
                    // Direct price input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("posts.price".localized)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "eurosign")
                                .foregroundColor(.secondary)
                                .font(.headline)
                            
                            TextField("0,00", text: $price)
                                .focused($priceFocus)
                                .focused($focusedField, equals: .price)
                                .keyboardType(.decimalPad)
                                .submitLabel(.done)
                                .onChange(of: price) { newValue in
                                    // Replace dots with commas for German number format
                                    if newValue.contains(".") {
                                        price = newValue.replacingOccurrences(of: ".", with: ",")
                                    }
                                }
                                .toolbar {
                                    ToolbarItemGroup(placement: .keyboard) {
                                        Spacer()
                                        Button("Done") {
                                            focusedField = nil
                                        }
                                    }
                                }
                        }
                        .padding()
                        .background(Color(.systemGray6).opacity(0.5))
                        .cornerRadius(8)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.vertical, 10)
        } header: {
            Text("posts.details".localized)
                .font(.footnote)
                .fontWeight(.semibold)
                .padding(.top, 4)
                .padding(.bottom, 4)
        } footer: {
            Spacer()
                .frame(height: 12)
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
    }
}

struct ImagesSection: View {
    @EnvironmentObject private var viewModel: CreatePostViewModel
    @Binding var selectedImages: [PhotosPickerItem]
    @Binding var imagePreviews: [(id: String, data: Data)]
    @State private var showCamera = false
    @State private var cameraImage: UIImage?
    
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    // Photo library picker - wrap in explicit Button for clearer tap target
                    PhotoPickerButton(selectedImages: $selectedImages)
                    
                    // Camera button - explicit button with clear tap area
                    CameraButton(showCamera: $showCamera)
                }
                
                if imagePreviews.isEmpty {
                    Text("posts.images_help".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                } else {
                    Text(String(format: "posts.images_count".localized, imagePreviews.count))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    
                    // Display images with upload status
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
                        .padding(.vertical, 10)
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
                .padding(.top, 16)
                .padding(.bottom, 4)
        } footer: {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 12)
                Text("posts.images_footer".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
            }
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
    }
}

// Extract photo picker button to a separate view
struct PhotoPickerButton: View {
    @Binding var selectedImages: [PhotosPickerItem]
    
    var body: some View {
        PhotosPicker(
            selection: $selectedImages, 
            maxSelectionCount: 15, 
            matching: .images
        ) {
            HStack {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.headline)
                Text("posts.select_images".localized)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(10)
        }
        .buttonStyle(BorderlessButtonStyle()) // Ensure tap area is limited to button
    }
}

// Extract camera button to a separate view
struct CameraButton: View {
    @Binding var showCamera: Bool
    
    var body: some View {
        Button {
            showCamera = true
        } label: {
            HStack {
                Image(systemName: "camera.fill")
                    .font(.headline)
            }
            .frame(width: 50)
            .padding(.vertical, 14)
            .background(Color.green.opacity(0.1))
            .foregroundColor(.green)
            .cornerRadius(10)
        }
        .buttonStyle(BorderlessButtonStyle()) // Ensure tap area is limited to button
    }
}

struct LocationSection: View {
    // Get location data from UserDefaults
    var postalCode: String = UserDefaults.standard.string(forKey: "postalCode") ?? ""
    var countryCode: String = UserDefaults.standard.string(forKey: "countryCode") ?? ""
    
    var hasValidLocation: Bool {
        // Split into separate conditions to reduce complexity
        let hasNonEmptyValues = !postalCode.isEmpty && !countryCode.isEmpty
        let hasKnownValues = postalCode != "Unknown" && countryCode != "Unknown"
        return hasNonEmptyValues && hasKnownValues
    }
    
    // Translate country code
    var localizedCountry: String {
        if countryCode == "DEU" {
            return "auth.country_germany".localized
        } else {
            return countryCode
        }
    }
    
    var body: some View {
        Section {
            VStack {
                if hasValidLocation {
                    HStack {
                        Image(systemName: "location.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                            .padding(.trailing, 4)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("posts.posting_location".localized)
                                .font(.subheadline)
                            // Prepare formatted location string separately
                            let locationText = "\(postalCode), \(localizedCountry)"
                            Text(locationText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("posts.from_profile".localized)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                } else {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .font(.title3)
                            .padding(.trailing, 4)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("posts.location_unavailable".localized)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("posts.update_location".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.vertical, 12)
        } header: {
            Text("posts.location".localized)
                .font(.footnote)
                .fontWeight(.semibold)
                .padding(.top, 16)
                .padding(.bottom, 4)
        } footer: {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 12)
                Text("posts.location_footer".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
            }
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
    }
}

struct CreatePostButtonSection: View {
    var isFormValid: Bool
    var isLoading: Bool
    var allImagesUploaded: Bool
    var onCreatePost: () -> Void
    
    var body: some View {
        Button(action: onCreatePost) {
            if isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(.white)
                    Text("common.creating".localized)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue.opacity(0.5))
                .foregroundColor(.white)
                .cornerRadius(12)
            } else {
                Text("posts.create".localized)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isFormValid ? Color.blue : Color.gray.opacity(0.3))
                    .foregroundColor(isFormValid ? .white : .gray)
                    .cornerRadius(12)
            }
        }
        .disabled(isLoading || !isFormValid)
        .padding(.vertical, 16)
    }
}

struct CreatePostView: View {
    @StateObject private var viewModel = CreatePostViewModel()
    @EnvironmentObject private var categoryViewModel: CategoryViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageManager: LanguageManager
    
    // Form state properties
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory = ""
    @State private var offering = PostOffering.givingAway
    @State private var price = ""
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var imagePreviews: [(id: String, data: Data)] = []
    @State private var error: String?
    @State private var showSuccess = false
    @State private var isFormValid = false
    @State private var selectedParentCategoryId: String? = nil // Keep but don't use functionally
    @State private var navigateToPostDetail = false
    @FocusState private var focusedField: FormField?
    
    // Computed properties to break down complex expressions
    private var hasTitleAndDescription: Bool {
        return !title.isEmpty && description.count >= 10
    }
    
    private var hasCategorySelected: Bool {
        return !selectedCategory.isEmpty
    }
    
    private var hasPriceIfNeeded: Bool {
        return offering == .givingAway || (offering == .soldAtPrice && !price.isEmpty)
    }

    var body: some View {
        Form {
            
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
            
            ImagesSection(
                selectedImages: $selectedImages,
                imagePreviews: $imagePreviews
            )
            .environmentObject(viewModel)
            
            LocationSection()
            
            Section {
                // Upload status summary
                if !imagePreviews.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        let uploadedCount = viewModel.uploadedImageUrls.count
                        let totalCount = imagePreviews.count
                        let failedCount = viewModel.hasFailedUploads ? imagePreviews.count - uploadedCount : 0
                        
                        HStack {
                            Text("posts.image_upload_status".localized)
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            if viewModel.allImagesUploaded {
                                Text("posts.all_images_uploaded".localized)
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else if failedCount > 0 {
                                Text(String(format: "posts.upload_failed_count".localized, failedCount))
                                    .font(.caption)
                                    .foregroundColor(.red)
                            } else {
                                Text(String(format: "posts.upload_progress".localized, uploadedCount, totalCount))
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if !viewModel.allImagesUploaded && !viewModel.hasFailedUploads {
                            Text("posts.wait_for_upload".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom, 8)
                }
                
                CreatePostButtonSection(
                    isFormValid: isFormValid,
                    isLoading: viewModel.isLoading,
                    allImagesUploaded: viewModel.allImagesUploaded,
                    onCreatePost: {
                        Task {
                            do {
                                try await viewModel.createPost(
                                    title: title,
                                    description: description,
                                    category: selectedCategory,
                                    offering: offering.rawValue,
                                    price: offering == .soldAtPrice ? price : nil
                                )
                                
                                print("Post creation successful - postId exists: \(viewModel.createdPostId != nil)")
                                
                                // Only show success alert if we couldn't get the post ID
                                if viewModel.createdPostId == nil {
                                    print("No post ID - showing success alert")
                                    showSuccess = true
                                    resetForm()
                                } else {
                                    print("Post ID available - navigating to detail view")
                                    // Navigate to post detail if we have the post ID
                                    // Add a small delay to ensure state updates properly
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        navigateToPostDetail = true
                                    }
                                }
                            } catch {
                                self.error = error.localizedDescription
                            }
                        }
                    }
                )
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        }
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("posts.create".localized)
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
                    focusedField = nil
                }) {
                    Text("common.done".localized)
                }
            }
        }
        .onChange(of: selectedImages) { items in
            Task {
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        let id = UUID().uuidString
                        imagePreviews.append((id: id, data: data))
                        viewModel.uploadImage(id: id, imageData: data)
                    }
                }
                // Don't clear selection - let the picker stay open
                // selectedImages = []
            }
        }
        .onChange(of: title) { _ in validateForm() }
        .onChange(of: description) { _ in validateForm() }
        .onChange(of: selectedCategory) { _ in validateForm() }
        .onChange(of: price) { _ in validateForm() }
        .onChange(of: offering) { _ in validateForm() }
        .onChange(of: navigateToPostDetail) { isActive in
            // When navigation completes (becomes inactive), reset the form
            if !isActive {
                print("Navigation completed, resetting form")
                resetForm()
                // Also reset the created post data
                viewModel.createdPost = nil
                viewModel.createdPostId = nil
            }
        }
        .applyAlerts(error: $error, showSuccess: $showSuccess, onDismissSuccess: { dismiss() })
        
        // Always include NavigationLink in view hierarchy
        .background(
            NavigationLink(destination: EmptyView()) {
                EmptyView()
            }
            .hidden()
        )
        .background(
            Group {
                if let post = viewModel.createdPost {
                    // Navigate to UserPostsView instead of PostDetailView
                    NavigationLink(
                        destination: UserPostsView(userId: KeychainManager.shared.getUserId() ?? UserDefaults.standard.string(forKey: "userId") ?? ""),
                        isActive: $navigateToPostDetail,
                        label: { EmptyView() }
                    )
                } else if let postId = viewModel.createdPostId, !postId.isEmpty {
                    // Fallback to using postId if no post object but ID exists
                    Text("Navigating by ID - should not see this")
                        .hidden()
                } else {
                    // No post data available
                    EmptyView()
                }
            }
        )
        .id(languageManager.currentLanguage.rawValue)
    }
    
    private func validateForm() {
        isFormValid = hasTitleAndDescription && hasCategorySelected && hasPriceIfNeeded
    }
    
    private func resetForm() {
        title = ""
        description = ""
        selectedCategory = ""
        selectedParentCategoryId = nil
        offering = .givingAway
        price = ""
        selectedImages = []
        imagePreviews = []
        viewModel.resetImageUploads()
    }
}

// Extension to apply alert modifiers
extension View {
    func applyAlerts(error: Binding<String?>, showSuccess: Binding<Bool>, onDismissSuccess: @escaping () -> Void) -> some View {
        return self
            .alert("common.error".localized, isPresented: .constant(error.wrappedValue != nil)) {
                Button("common.ok".localized) {
                    error.wrappedValue = nil
                }
            } message: {
                Text(error.wrappedValue ?? "")
            }
            .alert("common.success".localized, isPresented: showSuccess) {
                Button("common.ok".localized, role: .cancel) {
                    onDismissSuccess()
                }
            } message: {
                Text("posts.post_created".localized)
            }
    }
}

#Preview {
    NavigationStack {
        CreatePostView()
            .environmentObject(LanguageManager.shared)
            .environmentObject(CategoryViewModel.shared)
    }
}

