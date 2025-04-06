# UI Testing Accessibility Guide

This guide explains how to add proper accessibility identifiers to UI elements to support UI testing in the Zack Weg iOS app.

## Why Accessibility Identifiers?

Accessibility identifiers allow UI tests to reliably locate and interact with UI elements. Unlike accessibility labels, identifiers are not exposed to VoiceOver or other assistive technologies, making them ideal for testing purposes.

## Identifier Naming Conventions

Follow these naming conventions for accessibility identifiers:

1. Use camelCase format
2. Be specific and descriptive
3. Follow a consistent pattern for similar elements
4. Use the format: `[elementType][ElementPurpose]`

Examples:
- `emailTextField`
- `passwordSecureField`
- `signInButton`
- `postCell`
- `userProfileImage`

## How to Add Accessibility Identifiers in SwiftUI

### Basic Views

```swift
TextField("Enter email", text: $email)
    .accessibilityIdentifier("emailTextField")

SecureField("Enter password", text: $password)
    .accessibilityIdentifier("passwordTextField")

Button("Sign In") {
    viewModel.signIn()
}
.accessibilityIdentifier("signInButton")
```

### Lists and ForEach

```swift
List {
    ForEach(viewModel.items) { item in
        ItemRow(item: item)
            .accessibilityIdentifier("itemRow_\(item.id)")
    }
}
.accessibilityIdentifier("itemsList")
```

### Custom Views

When creating custom views, expose a method to set the accessibility identifier:

```swift
struct CustomButton: View {
    var title: String
    var action: () -> Void
    private var identifier: String?
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .accessibilityIdentifier(identifier)
    }
    
    func accessibilityId(_ id: String) -> some View {
        var view = self
        view.identifier = id
        return view
    }
}

// Usage
CustomButton(title: "Sign In", action: signIn)
    .accessibilityId("signInButton")
```

## Required Identifiers for Key Screens

### Sign In Screen

All elements on the sign in screen should have accessibility identifiers:

```swift
VStack {
    // App Logo
    Image("logo")
        .accessibilityIdentifier("appLogoImage")
    
    // Email field
    TextField("Email", text: $email)
        .accessibilityIdentifier("emailTextField")
    
    // Password field
    SecureField("Password", text: $password)
        .accessibilityIdentifier("passwordTextField")
    
    // Sign In button
    Button("Sign In") { /* action */ }
        .accessibilityIdentifier("signInButton")
    
    // Forgot Password button
    Button("Forgot Password?") { /* action */ }
        .accessibilityIdentifier("forgotPasswordButton")
    
    // Sign Up button
    Button("Sign Up") { /* action */ }
        .accessibilityIdentifier("signUpButton")
    
    // Error message text
    if showError {
        Text(errorMessage)
            .accessibilityIdentifier("errorMessageText")
    }
}
```

### Home/Explore Screens

Elements on the home and explore screens should also have identifiers:

```swift
// Categories
ScrollView(.horizontal) {
    HStack {
        ForEach(viewModel.categories) { category in
            CategoryButton(category: category)
                .accessibilityIdentifier("categoryButton_\(category.id)")
        }
    }
}
.accessibilityIdentifier("categoriesScrollView")

// Search field
SearchBar(text: $searchText)
    .accessibilityIdentifier("exploreSearchField")

// Items list
ScrollView {
    LazyVStack {
        ForEach(viewModel.items) { item in
            ItemCard(item: item)
                .accessibilityIdentifier("postCell_\(item.id)")
        }
    }
}
.accessibilityIdentifier("postsScrollView")
```

### Post Creation Screen

```swift
VStack {
    // Title field
    TextField("Title", text: $title)
        .accessibilityIdentifier("postTitleField")
    
    // Description field
    TextEditor(text: $description)
        .accessibilityIdentifier("postDescriptionField")
    
    // Category picker
    Button("Select Category") { showCategoryPicker = true }
        .accessibilityIdentifier("selectCategoryButton")
    
    // Add image button
    Button("Add Image") { showImagePicker = true }
        .accessibilityIdentifier("addImageButton")
    
    // Create post button
    Button("Create Post") { submitPost() }
        .accessibilityIdentifier("createPostButton")
}
```

## Testing Accessibility Identifiers

You can verify your accessibility identifiers are properly set by:

1. Running UI tests that explicitly look for these elements
2. Using the Accessibility Inspector in Xcode
3. Adding debug code to print all accessibility identifiers during development

```swift
#if DEBUG
// Debug function to print all accessibility identifiers in a view hierarchy
func printAccessibilityIdentifiers(view: UIView, level: Int = 0) {
    let indent = String(repeating: "  ", count: level)
    
    let identifier = view.accessibilityIdentifier ?? "nil"
    print("\(indent)View: \(type(of: view)), Identifier: \(identifier)")
    
    for subview in view.subviews {
        printAccessibilityIdentifiers(view: subview, level: level + 1)
    }
}

// Call this in your view controller to debug
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    printAccessibilityIdentifiers(view: view)
}
#endif
```

## Best Practices

1. **Add identifiers early** in development to avoid having to retrofit them later
2. **Test identifiers** with actual UI tests to ensure they work as expected
3. **Make identifiers unique** within a screen to avoid confusion
4. **Update identifiers** when UI elements change or are removed
5. **Document new identifiers** for screens to help other developers write UI tests

## Common Issues and Solutions

- **Element not found in UI tests**: Verify the identifier is correctly set and matches what the test is looking for
- **Identifiers changing dynamically**: Avoid using variable content in identifiers that might change between test runs
- **Nested views**: Make sure the outermost accessible view has the identifier, not a child view that might not be accessible
- **Text changing with localization**: Don't rely on text content for testing; use accessibility identifiers instead

By following these guidelines, you'll ensure UI tests can reliably locate and interact with elements in your app, making tests more robust and less prone to failure when the UI changes. 