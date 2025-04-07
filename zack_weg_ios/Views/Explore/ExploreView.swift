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
    @EnvironmentObject private var categoryViewModel: CategoryViewModel
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
                    .accessibilityLabel("exploreSearchField")
                    .onChange(of: viewModel.searchFilters.keyword) { _ in
                        // Cancel any existing search task
                        searchTask?.cancel()
                        // Create a new search task with debounce
                        searchTask = Task {
                            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                            if !Task.isCancelled {
                                await viewModel.searchPosts(resetOffset: true)
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
                                    await viewModel.searchPosts(resetOffset: true)
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
                                    await viewModel.searchPosts(resetOffset: true)
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
                                    await viewModel.searchPosts(resetOffset: true)
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
                        let categoryName = categoryViewModel.getCategory(byId: viewModel.searchFilters.categoryId)?.title ?? "Category"
                        
                        HStack {
                            Text(categoryName)
                                .font(.caption)
                            
                            Button(action: {
                                viewModel.searchFilters.categoryId = ""
                                Task {
                                    await viewModel.searchPosts(resetOffset: true)
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
            if viewModel.isLoading && viewModel.searchResults.isEmpty {
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
                ScrollViewReader { proxy in
                    List {
                        ForEach(viewModel.searchResults) { post in
                            PostCard(post: post)
                                .id(post.id) // Make sure each PostCard has an ID
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .onAppear {
                                    // Check if we need to load more posts
                                    Task {
                                        await viewModel.loadMoreIfNeeded(currentItem: post)
                                    }
                                }
                        }
                        .listRowBackground(Color.clear)
                        
                        // Loading indicator at the bottom when loading more
                        if viewModel.isLoadingMore {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        // Refresh data when the user pulls down
                        await categoryViewModel.fetchCategories()
                        await viewModel.searchPosts(resetOffset: true)
                    }
                }
            }
        }
        .navigationTitle("explore.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showFilters) {
            FilterView(viewModel: viewModel)
                .environmentObject(categoryViewModel)
        }
        .sheet(isPresented: $showMap) {
            MapView(posts: viewModel.searchResults)
        }
        .task {
            // Load posts
            await viewModel.searchPosts(resetOffset: true)
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

struct FlatLinkStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

#Preview {
    ExploreView()
} 
