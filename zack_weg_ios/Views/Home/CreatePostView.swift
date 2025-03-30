import PhotosUI
import SwiftUI
import UIKit

struct ImagePreviewView: View {
    let imageData: Data
    let index: Int
    let onDelete: (Int) -> Void
    
    var body: some View {
        if let uiImage = UIImage(data: imageData) {
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
                .background(isSelected ? Color.blue : Color(.systemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

struct PostDetailsSection: View {
    @Binding var title: String
    @Binding var description: String
    @Binding var selectedCategory: String
    @Binding var offering: PostOffering
    @Binding var price: String
    let categories: [Category]
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Text("posts.title_field".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("posts.enter_title".localized, text: $title)
                    .padding(.vertical, 8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("posts.description".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextEditor(text: $description)
                    .frame(minHeight: 120)
                    .padding(4)
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("posts.category".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if categories.isEmpty {
                    Text("posts.loading_categories".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories) { category in
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

            VStack(alignment: .leading, spacing: 12) {
                Text("posts.offering_question".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                offeringTypeCard(
                    isSelected: offering == .givingAway,
                    title: "posts.give_away".localized,
                    icon: "gift.fill",
                    iconColor: .green,
                    description: "posts.give_away_desc".localized
                ) {
                    offering = .givingAway
                }
                
                offeringTypeCard(
                    isSelected: offering == .soldAtPrice,
                    title: "posts.sell".localized,
                    icon: "eurosign.circle.fill",
                    iconColor: .blue,
                    description: "posts.sell_desc".localized
                ) {
                    offering = .soldAtPrice
                }
            }

            if offering == .soldAtPrice {
                VStack(alignment: .leading, spacing: 4) {
                    Text("posts.price_currency".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        Image(systemName: "eurosign.circle")
                            .foregroundColor(.blue)
                        TextField("posts.price_placeholder".localized, text: $price)
                            .keyboardType(.decimalPad)
                            .padding(.vertical, 8)
                    }
                }
            }
        } header: {
            Text("posts.details".localized)
                .font(.footnote)
                .fontWeight(.semibold)
        }
    }
    
    private func offeringTypeCard(isSelected: Bool, title: String, icon: String, iconColor: Color, description: String, action: @escaping () -> Void) -> some View {
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

struct ImagesSection: View {
    @Binding var selectedImages: [PhotosPickerItem]
    @Binding var imagePreviews: [Data]
    
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
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
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
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
                        HStack(spacing: 12) {
                            ForEach(Array(imagePreviews.enumerated()), id: \.offset) { index, imageData in
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
}

struct LocationSection: View {
    // Get location data from UserDefaults
    var postalCode: String = UserDefaults.standard.string(forKey: "postalCode") ?? ""
    var countryCode: String = UserDefaults.standard.string(forKey: "countryCode") ?? ""
    
    var hasValidLocation: Bool {
        return !postalCode.isEmpty && !countryCode.isEmpty && 
               postalCode != "Unknown" && countryCode != "Unknown"
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
            if hasValidLocation {
                HStack {
                    Image(systemName: "location.circle.fill")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text("posts.posting_location".localized)
                            .font(.subheadline)
                        Text("\(postalCode), \(localizedCountry)")
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
                    VStack(alignment: .leading) {
                        Text("posts.location_unavailable".localized)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("posts.update_location".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            Text("posts.location".localized)
                .font(.footnote)
                .fontWeight(.semibold)
        } footer: {
            Text("posts.location_footer".localized)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct CreatePostView: View {
    @ObservedObject var viewModel: CreatePostViewModel
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
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 0) {
                Text("posts.create_new".localized)
                    .font(.title2)
                    .fontWeight(.bold)
                    
                Text("posts.share_with_community".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
            
            PostDetailsSection(
                title: $title,
                description: $description,
                selectedCategory: $selectedCategory,
                offering: $offering,
                price: $price,
                categories: viewModel.categories
            )
            
            ImagesSection(
                selectedImages: $selectedImages,
                imagePreviews: $imagePreviews
            )
            
            LocationSection()
            
            Section {
                VStack(spacing: 16) {
                    Button(action: {
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
                                showSuccess = true
                                // Reset form
                                resetForm()
                            } catch {
                                self.error = error.localizedDescription
                            }
                        }
                    }) {
                        HStack {
                            Spacer()
                            if viewModel.isLoading {
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
                    .disabled(
                        viewModel.isLoading || !isFormValid
                    )
                    
                    if !isFormValid {
                        Text("posts.fill_required".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .listRowBackground(Color.clear)
        }
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
        .onChange(of: [title, description, selectedCategory, price]) { _ in
            validateForm()
        }
        .onChange(of: offering) { _ in
            validateForm()
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
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("posts.post_created".localized)
        }
        .task {
            await viewModel.fetchCategories()
        }
    }
    
    private func validateForm() {
        isFormValid = !title.isEmpty && 
                     !description.isEmpty && 
                     !selectedCategory.isEmpty && 
                     (offering == .givingAway || (offering == .soldAtPrice && !price.isEmpty))
    }
    
    private func resetForm() {
        title = ""
        description = ""
        selectedCategory = ""
        offering = .givingAway
        price = ""
        selectedImages = []
        imagePreviews = []
    }
}

#Preview {
    CreatePostView(viewModel: CreatePostViewModel())
}
