import SwiftUI
import UIKit

struct FilterView: View {
    @ObservedObject var viewModel: ExploreViewModel
    @EnvironmentObject private var categoryViewModel: CategoryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedParentCategoryId: String? = nil
    
    // Add these offering constants
    private let allOfferings = ["GIVING_AWAY", "SOLD_AT_PRICE"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Location Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("explore.filter_location".localized)
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            TextField("explore.postal_code".localized, text: $viewModel.searchFilters.postalCode)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(10)
                            
                            TextField("explore.country_code".localized, text: $viewModel.searchFilters.countryCode)
                                .textInputAutocapitalization(.characters)
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(10)
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text("explore.filter_radius".localized)
                                    Spacer()
                                    Text(String(format: "explore.filter_distance_km".localized, Int(viewModel.searchFilters.radiusKm)))
                                }
                                
                                Slider(value: $viewModel.searchFilters.radiusKm, in: 1...100, step: 1)
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
                                viewModel.searchFilters.categoryId = ""
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
                                        viewModel.searchFilters.categoryId = ""
                                    }
                                    
                                    // Top level categories
                                    ForEach(categoryViewModel.topLevelCategories) { category in
                                        CategoryButton(
                                            category: category,
                                            isSelected: selectedParentCategoryId == category.id
                                        ) {
                                            selectedParentCategoryId = category.id
                                            
                                            // If category has no children, set it directly as the filter
                                            if !categoryViewModel.hasChildren(for: category.id) {
                                                viewModel.selectCategory(category.id)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Show subcategories if a parent is selected
                            if let parentCategoryId = selectedParentCategoryId,
                               let parentCategory = categoryViewModel.getCategory(byId: parentCategoryId),
                               categoryViewModel.hasChildren(for: parentCategoryId) {
                                
                                let subcategories = categoryViewModel.getChildCategories(for: parentCategoryId)
                                
                                Text("explore.filter_subcategories".localized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        // "All in [Parent]" option
                                        Button(action: {
                                            viewModel.selectCategory(parentCategory.id)
                                        }) {
                                            Text(String(format: "explore.filter_all_in".localized, parentCategory.title))
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(
                                                    viewModel.searchFilters.categoryId == parentCategory.id ? 
                                                        Color.blue : 
                                                        Color(UIColor.secondarySystemBackground)
                                                )
                                                .foregroundColor(viewModel.searchFilters.categoryId == parentCategory.id ? .white : .primary)
                                                .cornerRadius(20)
                                        }
                                        
                                        // Subcategories
                                        ForEach(subcategories) { subcategory in
                                            Button(action: {
                                                viewModel.selectCategory(subcategory.id)
                                            }) {
                                                Text(subcategory.title)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(
                                                        viewModel.searchFilters.categoryId == subcategory.id ? 
                                                            Color.blue : 
                                                            Color(UIColor.secondarySystemBackground)
                                                    )
                                                    .foregroundColor(viewModel.searchFilters.categoryId == subcategory.id ? .white : .primary)
                                                    .cornerRadius(20)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Offering Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("explore.filter_offering".localized)
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Button(action: {
                                viewModel.searchFilters.offering = nil
                            }) {
                                HStack {
                                    Text("common.all".localized)
                                    Spacer()
                                    if viewModel.searchFilters.offering == nil {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(10)
                            }
                            .foregroundColor(.primary)
                            
                            ForEach(allOfferings, id: \.self) { offering in
                                Button(action: {
                                    viewModel.searchFilters.offering = offering
                                }) {
                                    HStack {
                                        Text(getLocalizedOffering(offering))
                                        Spacer()
                                        if viewModel.searchFilters.offering == offering {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding()
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(10)
                                }
                                .foregroundColor(.primary)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Button(action: {
                        viewModel.searchFilters = SearchFilters()
                        selectedParentCategoryId = nil
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
            .navigationTitle("explore.filters".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.apply".localized) {
                        Task {
                            await viewModel.searchPosts()
                        }
                        dismiss()
                    }
                    .fontWeight(.bold)
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