import SwiftUI
import UIKit

struct FilterView: View {
    @ObservedObject var viewModel: ExploreViewModel
    @EnvironmentObject private var categoryViewModel: CategoryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedParentCategoryId: String? = nil
    @State private var selectedCountry: Country? = Country.germany
    @FocusState private var isSearchFocused: Bool
    
    // Local copy of filters that we'll apply only when user taps "Apply"
    @State private var tempFilters: SearchFilters = SearchFilters()
    
    // Props to focus on search when opening
    var focusOnSearch: Bool = false
    
    // Add these offering constants
    private let allOfferings = ["GIVING_AWAY", "SOLD_AT_PRICE"]
    
    // Local method to select/deselect a category
    private func selectCategory(_ categoryId: String) {
        // If the category is already selected, remove it
        if tempFilters.categoryIds.contains(categoryId) {
            tempFilters.categoryIds.removeAll { $0 == categoryId }
        } else {
            // Otherwise add it
            tempFilters.categoryIds.append(categoryId)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Search Field at the top
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("explore.search_placeholder".localized, text: $tempFilters.keyword)
                            .textFieldStyle(PlainTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .focused($isSearchFocused)
                            .accessibilityLabel("exploreFilterSearchField")
                            .submitLabel(.search)
                            .onSubmit {
                                // Apply filters then dismiss
                                viewModel.searchFilters = tempFilters
                                Task {
                                    await viewModel.searchPosts()
                                    dismiss()
                                }
                            }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Location Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("explore.filter_location".localized)
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            TextField("explore.postal_code".localized, text: $tempFilters.postalCode)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(10)
                            
                            CountrySelectView(
                                selectedCountry: $selectedCountry,
                                label: "explore.country".localized
                            )
                            .onChange(of: selectedCountry) { newCountry in
                                tempFilters.countryCode = newCountry?.code ?? "DEU"
                            }
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text("explore.filter_radius".localized)
                                    Spacer()
                                    Text(String(format: "explore.filter_distance_km".localized, Int(tempFilters.radiusKm)))
                                }
                                
                                Slider(value: $tempFilters.radiusKm, in: 1...100, step: 1)
                            }
                            .padding(.horizontal, 4)
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Categories Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("explore.filter_categories".localized)
                                .font(.headline)
                            Spacer()
                            Button("common.clear".localized) {
                                selectedParentCategoryId = nil
                                tempFilters.categoryIds = []
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        
                        if categoryViewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .padding()
                        } else if categoryViewModel.error != nil && categoryViewModel.topLevelCategories.isEmpty {
                            HStack {
                                Text("explore.failed_categories".localized)
                                    .foregroundColor(.red)
                                Button(action: {
                                    Task {
                                        await categoryViewModel.fetchCategories()
                                    }
                                }) {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                        } else {
                            // Parent Categories
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    // All categories option
                                    CategoryButton(
                                        title: "common.all".localized,
                                        isSelected: selectedParentCategoryId == nil
                                    ) {
                                        selectedParentCategoryId = nil
                                        tempFilters.categoryIds = []
                                    }
                                    
                                    // Top level categories
                                    ForEach(categoryViewModel.topLevelCategories) { category in
                                        ParentCategoryButton(
                                            category: category,
                                            isSelected: selectedParentCategoryId == category.id || tempFilters.categoryIds.contains(category.id),
                                            hasChildren: categoryViewModel.hasChildren(for: category.id)
                                        ) {
                                            // If category has children, just highlight it to show subcategories
                                            if categoryViewModel.hasChildren(for: category.id) {
                                                if selectedParentCategoryId == category.id {
                                                    // If already selected, toggle it off
                                                    selectedParentCategoryId = nil
                                                } else {
                                                    // Otherwise select it to show subcategories
                                                    selectedParentCategoryId = category.id
                                                }
                                            } else {
                                                // If category has no children, toggle its selection in the filter
                                                selectCategory(category.id)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Show subcategories if a parent is selected
                            if let parentCategoryId = selectedParentCategoryId,
                               let _ = categoryViewModel.getCategory(byId: parentCategoryId),
                               categoryViewModel.hasChildren(for: parentCategoryId) {
                                
                                let subcategories = categoryViewModel.getChildCategories(for: parentCategoryId)
                                
                                Text("explore.filter_subcategories".localized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        // Subcategories
                                        ForEach(subcategories) { subcategory in
                                            Button(action: {
                                                selectCategory(subcategory.id)
                                            }) {
                                                Text(subcategory.title)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(
                                                        tempFilters.categoryIds.contains(subcategory.id) ? 
                                                            Color.blue : 
                                                            Color(UIColor.secondarySystemBackground)
                                                    )
                                                    .foregroundColor(tempFilters.categoryIds.contains(subcategory.id) ? .white : .primary)
                                                    .cornerRadius(20)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    
                    Button(action: {
                        // Create new empty filters
                        tempFilters = SearchFilters()
                        selectedParentCategoryId = nil
                        
                        // Apply the cleared filters to the viewModel and search
                        viewModel.searchFilters = tempFilters
                        Task {
                            await viewModel.searchPosts()
                        }
                        dismiss()
                    }) {
                        Text("explore.clear_filters".localized)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .padding(.vertical)
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("explore.filters".localized)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                // Copy the existing filters when opening the view
                tempFilters = viewModel.searchFilters
                
                // Focus on search if specified - using task is more reliable than onAppear
                if focusOnSearch {
                    // Short delay to ensure view is ready
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                    isSearchFocused = true
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.apply".localized) {
                        // Apply the temporary filters to the viewModel
                        viewModel.searchFilters = tempFilters
                        Task {
                            await viewModel.searchPosts()
                        }
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
                
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("common.done".localized) {
                            isSearchFocused = false
                        }
                    }
                }
            }
        }
    }
    
    // Helper method to get localized offering text
    private func getLocalizedOffering(_ offering: String) -> String {
        switch offering {
        case "GIVING_AWAY":
            return "explore.filter_giving_away".localized
        case "SOLD_AT_PRICE":
            return "explore.filter_selling".localized
        default:
            return offering.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}

// Add this after the existing CategoryButton struct
struct ParentCategoryButton: View {
    var category: Category
    let isSelected: Bool
    let hasChildren: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(category.title)
                if hasChildren {
                    Image(systemName: isSelected ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(UIColor.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
} 
