import PhotosUI
import SwiftUI
import UIKit

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
    
    var body: some View {
        HStack {
            Image(systemName: "eurosign.circle")
                .foregroundColor(.blue)
            TextField("posts.price_placeholder".localized, text: $price)
                .keyboardType(.decimalPad)
                .padding(.vertical, 10)
                .onChange(of: price) { newValue in
                    // Ensure only valid decimal characters are entered
                    let filtered = newValue.filter { "0123456789.,".contains($0) }
                    if filtered != newValue {
                        price = filtered
                    }
                }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(8)
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
                // Parent Categories
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(categories, id: \.id) { category in
                            let isSelected: Bool = selectedParentCategoryId == category.id
                            CategoryPill(
                                category: category,
                                isSelected: isSelected
                            ) {
                                selectedParentCategoryId = category.id
                                
                                // Always set selectedCategory to parent category initially
                                selectedCategory = category.id
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Show subcategories if a parent is selected
                if let parentCategoryId = selectedParentCategoryId,
                   categoryViewModel.hasChildren(for: parentCategoryId) {
                    
                    let subcategories = categoryViewModel.getChildCategories(for: parentCategoryId)
                    
                    Text("explore.filter_subcategories".localized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.top, 10)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            // Add option to select the parent category itself (now redundant but kept for UX clarity)
                            if let parentCategory = categoryViewModel.getCategory(byId: parentCategoryId) {
                                Button(action: {
                                    selectedCategory = parentCategory.id
                                }) {
                                    Text(String(format: "explore.filter_all_in".localized, parentCategory.title))
                                        .font(.subheadline)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedCategory == parentCategory.id ? 
                                                Color.blue : 
                                                Color(UIColor.secondarySystemBackground)
                                        )
                                        .foregroundColor(selectedCategory == parentCategory.id ? .white : .primary)
                                        .cornerRadius(20)
                                }
                            }
                            
                            // Subcategories
                            ForEach(subcategories) { subcategory in
                                CategoryPill(
                                    category: subcategory,
                                    isSelected: selectedCategory == subcategory.id
                                ) {
                                    selectedCategory = subcategory.id
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
    }
}

struct TitleInputView: View {
    @Binding var title: String
    
    var body: some View {
        TextField("posts.title_field".localized, text: $title)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Color(.systemGray6).opacity(0.5))
            .cornerRadius(8)
            .padding(.vertical, 6)
    }
}

struct DescriptionInputView: View {
    @Binding var description: String
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $description)
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
    
    var body: some View {
        Section {
            VStack(spacing: 16) {
                TitleInputView(title: $title)
                
                DescriptionInputView(description: $description)
                
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
                    PriceInputView(price: $price)
                        .padding(.top, 8)
                }
            }
            .padding(.vertical, 10)
        } header: {
            Text("posts.details".localized)
                .font(.footnote)
                .fontWeight(.semibold)
                .padding(.top, 8)
                .padding(.bottom, 4)
        } footer: {
            Spacer()
                .frame(height: 12)
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
    }
}

struct ImagesSection: View {
    @Binding var selectedImages: [PhotosPickerItem]
    @Binding var imagePreviews: [Data]
    
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                PhotosPicker(
                    selection: $selectedImages, maxSelectionCount: 5, matching: .images
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
                        
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
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
                        .padding(.vertical, 10)
                    }
                }
            }
            .padding(.vertical, 10)
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
    let isFormValid: Bool
    let isLoading: Bool
    let onCreatePost: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Button(action: onCreatePost) {
                HStack {
                    Spacer()
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("posts.create".localized)
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
                .padding(.vertical, 16)
                .background(isFormValid ? Color.blue : Color.gray.opacity(0.5))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isLoading || !isFormValid)
            
            if !isFormValid {
                Text("posts.fill_required".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 10)
    }
}

struct FormHeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("posts.create_new".localized)
                .font(.title2)
                .fontWeight(.bold)
                
            Text("posts.share_with_community".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 16)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20))
    }
}

struct CreatePostView: View {
    @StateObject private var viewModel: CreatePostViewModel
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
    @State private var navigateToPostDetail = false

    init() {
        _viewModel = StateObject(wrappedValue: CreatePostViewModel())
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

    var body: some View {
        Form {
            FormHeaderView()
            
            PostDetailsSection(
                title: $title,
                description: $description,
                selectedCategory: $selectedCategory,
                selectedParentCategoryId: $selectedParentCategoryId,
                offering: $offering,
                price: $price,
                categories: categoryViewModel.topLevelCategories
            )
            
            ImagesSection(
                selectedImages: $selectedImages,
                imagePreviews: $imagePreviews
            )
            
            LocationSection()
            
            Section {
                CreatePostButtonSection(
                    isFormValid: isFormValid,
                    isLoading: viewModel.isLoading,
                    onCreatePost: {
                        Task {
                            do {
                                try await viewModel.createPost(
                                    title: title,
                                    description: description,
                                    category: selectedCategory,
                                    offering: offering.rawValue,
                                    images: imagePreviews,
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
        .navigationTitle("posts.create".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedImages) { items in
            Task {
                imagePreviews = []
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        imagePreviews.append(data)
                    }
                }
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
            NavigationLink(
                destination: PostDetailView(postId: viewModel.createdPostId ?? ""),
                isActive: $navigateToPostDetail,
                label: { EmptyView() }
            )
        )
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
    CreatePostView()
        .environmentObject(CategoryViewModel.shared)
}
