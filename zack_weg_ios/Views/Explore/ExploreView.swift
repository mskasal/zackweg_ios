import SwiftUI

// Define the BadgeView here within ExploreView.swift
fileprivate struct BadgeView: View {
    let count: Int
    var backgroundColor: Color = .red
    var foregroundColor: Color = .white
    var fontSize: CGFloat = 10
    var size: CGFloat = 16
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: size, height: size)
            
            if count > 0 {
                Text("\(min(count, 99))")
                    .font(.system(size: fontSize, weight: .bold))
                    .foregroundColor(foregroundColor)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    // Hide the number if it's too large to fit
                    .opacity(count > 99 ? 0 : 1)
                
                // Show "99+" if count is very large
                if count > 99 {
                    Text("99+")
                        .font(.system(size: fontSize, weight: .bold))
                        .foregroundColor(foregroundColor)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
            }
        }
    }
}

struct ExploreView: View {
    @StateObject private var viewModel = ExploreViewModel()
    @State private var showFilters = false
    @State private var showMap = false
    @State private var searchTask: Task<Void, Never>?
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("explore.search_placeholder".localized, text: $viewModel.searchFilters.keyword)
                    .textFieldStyle(PlainTextFieldStyle())
                    .textInputAutocapitalization(.never)
                    .onChange(of: viewModel.searchFilters.keyword) { _ in
                        // Cancel any existing search task
                        searchTask?.cancel()
                        // Create a new search task with debounce
                        searchTask = Task {
                            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                            if !Task.isCancelled {
                                await viewModel.searchPosts()
                            }
                        }
                    }
                
                Button(action: { showMap.toggle() }) {
                    Image(systemName: "map")
                        .foregroundColor(.blue)
                }
                
                // Filter button with badge
                Button(action: { showFilters.toggle() }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.blue)
                            .font(.system(size: 22))
                        
                        // Only show badge if filters are active
                        let filtersCount = viewModel.countActiveFilters()
                        if filtersCount > 0 {
                            BadgeView(count: filtersCount)
                                .offset(x: 6, y: -6)
                        }
                    }
                    .frame(width: 30, height: 30)
                }
            }
            .padding()
            .background(Color(uiColor: .systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top)
            
            // Filter indicator chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Display active filters as chips
                    if !viewModel.searchFilters.postalCode.isEmpty {
                        HStack {
                            Text(viewModel.searchFilters.postalCode)
                                .font(.caption)
                            
                            Button(action: {
                                viewModel.searchFilters.postalCode = ""
                                Task {
                                    await viewModel.searchPosts()
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    }
                    
                    if viewModel.searchFilters.radiusKm != 20.0 {
                        HStack {
                            Text(String(format: "explore.filter_distance_km".localized, Int(viewModel.searchFilters.radiusKm)))
                                .font(.caption)
                            
                            Button(action: {
                                viewModel.searchFilters.radiusKm = 20.0
                                Task {
                                    await viewModel.searchPosts()
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    }
                    
                    if let offering = viewModel.searchFilters.offering {
                        HStack {
                            Text(offering.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.caption)
                            
                            Button(action: {
                                viewModel.searchFilters.offering = nil
                                Task {
                                    await viewModel.searchPosts()
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    }
                    
                    if !viewModel.searchFilters.keyword.isEmpty {
                        HStack {
                            Text(viewModel.searchFilters.keyword)
                                .font(.caption)
                            
                            Button(action: {
                                viewModel.searchFilters.keyword = ""
                                Task {
                                    await viewModel.searchPosts()
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    }
                    
                    // Display active category filter
                    if !viewModel.searchFilters.categoryId.isEmpty {
                        let categoryName = viewModel.categories.first(where: { $0.id == viewModel.searchFilters.categoryId })?.title ?? "Category"
                        
                        HStack {
                            Text(categoryName)
                                .font(.caption)
                            
                            Button(action: {
                                viewModel.searchFilters.categoryId = ""
                                viewModel.selectedParentCategory = nil
                                Task {
                                    await viewModel.searchPosts()
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 4)
                .padding(.bottom, 8)
            }
            .padding(.vertical, 4)
            .frame(minHeight: 44)
            .opacity(viewModel.countActiveFilters() > 0 ? 1 : 0.01)
            .animation(.easeInOut(duration: 0.2), value: viewModel.countActiveFilters())
            
            // Search Results
            if viewModel.isLoading {
                VStack {
                    Spacer(minLength: 44) // Add space for filter chips
                    ProgressView()
                    Spacer()
                }
                .frame(maxHeight: .infinity)
            } else if viewModel.searchResults.isEmpty {
                VStack {
                    Spacer(minLength: 44) // Add space for filter chips
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("explore.no_posts".localized)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.searchResults) { post in
                        PostCard(post: post, categories: viewModel.categories)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .refreshable {
                    // Refresh data when the user pulls down
                    await viewModel.fetchCategories()
                    await viewModel.fetchPosts()
                }
            }
        }
        .navigationTitle("explore.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showFilters) {
            FilterView(viewModel: viewModel)
        }
        .sheet(isPresented: $showMap) {
            MapView(posts: viewModel.searchResults, categories: viewModel.categories)
        }
        .task {
            // Load categories first, then posts
            await viewModel.fetchCategories()
            
            // Only fetch posts if categories loaded successfully or we already have categories
            if !viewModel.categories.isEmpty {
                await viewModel.fetchPosts()
            }
        }
    }
}

struct CategoryButton: View {
    var title: String?
    var category: Category?
    let isSelected: Bool
    let action: () -> Void
    
    init(category: Category, isSelected: Bool, action: @escaping () -> Void) {
        self.category = category
        self.title = nil
        self.isSelected = isSelected
        self.action = action
    }
    
    init(title: String, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.category = nil
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title ?? category?.title ?? "")
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(uiColor: .systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct FilterView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ExploreViewModel
    
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
                            TextField("Postal Code", text: $viewModel.searchFilters.postalCode)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(10)
                            
                            TextField("Country Code", text: $viewModel.searchFilters.countryCode)
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
                                viewModel.selectedParentCategory = nil
                                viewModel.searchFilters.categoryId = ""
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        
                        if viewModel.isCategoriesLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .padding()
                        } else if viewModel.error != nil && viewModel.topLevelCategories.isEmpty {
                            HStack {
                                Text("explore.failed_categories".localized)
                                    .foregroundColor(.red)
                                Button(action: {
                                    Task {
                                        await viewModel.fetchCategories()
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
                                    // "All" option
                                    Button(action: {
                                        viewModel.selectParentCategory(nil)
                                    }) {
                                        Text("common.all".localized)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                viewModel.selectedParentCategory == nil ? 
                                                    Color.blue : 
                                                    Color(UIColor.secondarySystemBackground)
                                            )
                                            .foregroundColor(viewModel.selectedParentCategory == nil ? .white : .primary)
                                            .cornerRadius(20)
                                    }
                                    
                                    // Parent categories
                                    ForEach(viewModel.topLevelCategories) { category in
                                        Button(action: {
                                            viewModel.selectParentCategory(category)
                                        }) {
                                            Text(category.title)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(
                                                    viewModel.selectedParentCategory?.id == category.id ? 
                                                        Color.blue : 
                                                        Color(UIColor.secondarySystemBackground)
                                                )
                                                .foregroundColor(viewModel.selectedParentCategory?.id == category.id ? .white : .primary)
                                                .cornerRadius(20)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Subcategories (only shown when a parent is selected with children)
                            if let parentCategory = viewModel.selectedParentCategory,
                               let subcategories = viewModel.subCategories[parentCategory.id],
                               !subcategories.isEmpty {
                                
                                Text("explore.filter_subcategories".localized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        // "All in [Parent]" option
                                        Button(action: {
                                            viewModel.searchFilters.categoryId = parentCategory.id
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
                                                viewModel.selectSubcategory(subcategory)
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
                                        Text(offering.replacingOccurrences(of: "_", with: " ").capitalized)
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
                        viewModel.selectedParentCategory = nil
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
                    Button("explore.apply_filters".localized) {
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
}

struct FlatLinkStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

#Preview {
    ExploreView()
} 
