import Foundation

class AuthenticatedURLSession {
    static let shared = AuthenticatedURLSession()
    private let session: URLSession
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: configuration)
    }
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        var authenticatedRequest = request
        
        // Add auth token if available - using KeychainManager instead of UserDefaults
        if let token = KeychainManager.shared.getAuthToken() {
            authenticatedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return try await session.data(for: authenticatedRequest)
    }
}

class APIService {
    static let shared = APIService()
    private let baseURL: String
    private let session: AuthenticatedURLSession
    
    private init(baseURL: String? = nil) {
        // Use ConfigurationManager to get the API base URL
        self.baseURL = baseURL ?? ConfigurationManager.shared.apiBaseURL
        self.session = .shared
    }
    
    // For testing purposes
    init(baseURL: String, session: AuthenticatedURLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    struct SignUpRequest: Codable {
        let email: String
        let password: String
        let location: Location
        let nickName: String
        
        enum CodingKeys: String, CodingKey {
            case email
            case password
            case location
            case nickName = "nick_name"
        }
    }
    
    struct Location: Codable {
        let postalCode: String
        let countryCode: String
        
        enum CodingKeys: String, CodingKey {
            case postalCode = "postal_code"
            case countryCode = "country_code"
        }
    }
    
    struct TokenResponse: Codable {
        let token: String
    }
    
    struct ErrorResponse: Codable {
        let message: String
    }
    
    func signIn(email: String, password: String) async throws -> String {
        let url = URL(string: "\(baseURL)/auth/login")!
        print("🔑 Sign In Request URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["email": email, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        print("📦 Sign In Request Body: \(body)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📥 Sign In Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 Sign In Response Body: \(responseString)")
        }
        
        if httpResponse.statusCode == 200 {
            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
            return tokenResponse.token
        } else {
            let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.serverError(errorResponse.message)
        }
    }
    
    func signUp(email: String, password: String, postalCode: String, countryCode: String, nickName: String) async throws -> String {
        let url = URL(string: "\(baseURL)/auth/register")!
        print("🔑 Sign Up Request URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let signUpRequest = SignUpRequest(
            email: email,
            password: password,
            location: Location(postalCode: postalCode, countryCode: countryCode),
            nickName: nickName
        )
        
        request.httpBody = try JSONEncoder().encode(signUpRequest)
        print("📦 Sign Up Request Body: \(signUpRequest)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📥 Sign Up Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 Sign Up Response Body: \(responseString)")
        }
        
        if httpResponse.statusCode == 200 {
            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
            return tokenResponse.token
        } else {
            let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.serverError(errorResponse.message)
        }
    }
    
    func resetPassword(email: String) async throws {
        let url = URL(string: "\(baseURL)/auth/forgot-password")!
        print("🔑 Reset Password Request URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["email": email]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        print("📦 Reset Password Request Body: \(body)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📥 Reset Password Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 Reset Password Response Body: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.serverError(errorResponse?.message ?? "Unknown error")
        }
    }
    
    func getPosts() async throws -> [Post] {
        let url = URL(string: "\(baseURL)/posts")!
        print("🔑 Get Posts Request URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📥 Get Posts Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 Get Posts Response Body: \(responseString)")
        }
        
        if httpResponse.statusCode == 200 {
            return try JSONDecoder().decode([Post].self, from: data)
        } else {
            let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.serverError(errorResponse.message)
        }
    }
    
    func createPost(title: String, description: String, categoryId: String, offering: String, imageUrls: [String], price: Double? = nil) async throws {
        let url = URL(string: "\(baseURL)/posts")!
        print("🔑 Create Post Request URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "title": title,
            "description": description,
            "category_id": categoryId,
            "offering": offering,
            "image_urls": imageUrls,
            "price": price ?? 0
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        print("📦 Create Post Request Body: \(body)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📥 Create Post Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 Create Post Response Body: \(responseString)")
        }
        
        guard httpResponse.statusCode == 201 else {
            let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.serverError(errorResponse.message)
        }
    }
    
    func uploadImage(_ imageData: Data) async throws -> String {
        let url = URL(string: "\(baseURL)/images/upload")!
        print("🔑 Upload Image Request URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.setValue("no-cache", forHTTPHeaderField: "cache-control")
        
        // Send the binary image data directly instead of base64 encoding
        request.httpBody = imageData
        print("📦 Upload Image Request Body: [Binary Image Data]")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📥 Upload Image Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 Upload Image Response Body: \(responseString)")
        }
        
        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            let response = try JSONDecoder().decode(ImageUploadResponse.self, from: data)
            return response.url
        } else {
            let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.serverError(errorResponse.message)
        }
    }
    
    func reportPost(postId: String, reason: String) async throws {
        let url = URL(string: "\(baseURL)/reports")!
        print("🔑 Report Post Request URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "post_id": postId,
            "reason": reason,
            "message": ""
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        print("📦 Report Post Request Body: \(body)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📥 Report Post Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 Report Post Response Body: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.message)
            }
            throw APIError.serverError("Failed to submit report with status: \(httpResponse.statusCode)")
        }
    }
    
    func getCategories() async throws -> [Category] {
        let url = URL(string: "\(baseURL)/categories")!
        print("🔑 Get Categories Request URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📥 Get Categories Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 Get Categories Response Body: \(responseString)")
        }
        
        if httpResponse.statusCode == 200 {
            return try JSONDecoder().decode([Category].self, from: data)
        } else {
            let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.serverError(errorResponse.message)
        }
    }
    
    func getMyProfile() async throws -> User {
        let url = URL(string: "\(baseURL)/users/me")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.message)
            }
            throw APIError.serverError("Failed to get profile")
        }
        
        let user = try JSONDecoder().decode(User.self, from: data)
        
        // Save user ID and nickname to UserDefaults
        UserDefaults.standard.set(user.id, forKey: "userId")
        UserDefaults.standard.set(user.nickName, forKey: "userNickName")
        
        // Save location information to UserDefaults
        UserDefaults.standard.set(user.location.postalCode, forKey: "postalCode")
        UserDefaults.standard.set(user.location.countryCode, forKey: "countryCode")
        
        return user
    }
    
    func searchPosts(
        keyword: String? = nil,
        postal_code: String? = nil,
        country_code: String? = nil,
        radius_km: Double? = 1.0,
        limit: Int? = 10,
        offset: Int? = 0,
        category_id: String? = nil,
        offering: String? = nil
    ) async throws -> [Post] {
        var components = URLComponents(string: "\(baseURL)/posts/search")!
        
        // Determine postal_code to use (parameter > keychain > userdefaults > default)
        let finalPostalCode: String
        if let postal_code = postal_code, !postal_code.isEmpty {
            finalPostalCode = postal_code
        } else if let keychainPostalCode = KeychainManager.shared.getPostalCode(), !keychainPostalCode.isEmpty {
            finalPostalCode = keychainPostalCode
        } else if let userDefaultsPostalCode = UserDefaults.standard.string(forKey: "postalCode"), !userDefaultsPostalCode.isEmpty {
            finalPostalCode = userDefaultsPostalCode
        } else {
            finalPostalCode = "10317" // Default fallback
            print("⚠️ Using default postal code for search: 10317")
        }
        
        // Determine country_code to use (parameter > keychain > userdefaults > default)
        let finalCountryCode: String
        if let country_code = country_code, !country_code.isEmpty {
            finalCountryCode = country_code
        } else if let keychainCountryCode = KeychainManager.shared.getCountryCode(), !keychainCountryCode.isEmpty {
            finalCountryCode = keychainCountryCode
        } else if let userDefaultsCountryCode = UserDefaults.standard.string(forKey: "countryCode"), !userDefaultsCountryCode.isEmpty {
            finalCountryCode = userDefaultsCountryCode
        } else {
            finalCountryCode = "DEU" // Default fallback
            print("⚠️ Using default country code for search: DEU")
        }
        
        var queryItems: [URLQueryItem] = []
        if let keyword = keyword {
            queryItems.append(URLQueryItem(name: "keyword", value: keyword))
        }
        queryItems.append(URLQueryItem(name: "postal_code", value: finalPostalCode))
        queryItems.append(URLQueryItem(name: "country_code", value: finalCountryCode))
        queryItems.append(URLQueryItem(name: "radius_km", value: String(radius_km ?? 1.0)))
        queryItems.append(URLQueryItem(name: "limit", value: String(limit ?? 10)))
        queryItems.append(URLQueryItem(name: "offset", value: String(offset ?? 0)))
        if let category_id = category_id {
            queryItems.append(URLQueryItem(name: "category_id", value: category_id))
        }
        if let offering = offering {
            queryItems.append(URLQueryItem(name: "offering", value: offering))
        }
        
        components.queryItems = queryItems
        
        // Log the request URL and parameters
        print("🔍 Search Posts Request URL: \(components.url!.absoluteString)")
        print("🔍 Search Parameters - Keyword: \(keyword ?? "None"), Postal Code: \(finalPostalCode), Country: \(finalCountryCode), Radius: \(radius_km ?? 1.0)km")
        print("🔍 Search Pagination - Limit: \(limit ?? 10), Offset: \(offset ?? 0)")
        if let category_id = category_id {
            print("🔍 Search Category: \(category_id)")
        }
        if let offering = offering {
            print("🔍 Search Offering Type: \(offering)")
        }
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Search Posts Error: Invalid response type")
                throw APIError.invalidResponse
            }
            
            print("📥 Search Posts Response Status: \(httpResponse.statusCode)")
            
            // Log response size for performance monitoring
            let dataSizeKB = Double(data.count) / 1024.0
            print("📦 Search Posts Response Size: \(String(format: "%.2f", dataSizeKB))KB")
            
            // Log abbreviated response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                // Only log the first part of the response to avoid console flooding
                let maxLength = min(responseString.count, 500)
                let truncatedResponse = responseString.prefix(maxLength)
                print("📦 Search Posts Response (truncated): \(truncatedResponse)\(responseString.count > maxLength ? "..." : "")")
            }
            
            if httpResponse.statusCode == 200 {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                let posts = try decoder.decode([Post].self, from: data)
                print("✅ Search Posts Success: Found \(posts.count) posts")
                return posts
            } else {
                let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                print("❌ Search Posts Error: \(errorResponse.message)")
                throw APIError.serverError(errorResponse.message)
            }
        } catch let error as APIError {
            print("❌ Search Posts API Error: \(error.localizedDescription)")
            throw error
        } catch {
            print("❌ Search Posts Unexpected Error: \(error.localizedDescription)")
            throw APIError.networkError(error)
        }
    }
    
    func getPostById(_ id: String) async throws -> Post {
        let url = URL(string: "\(baseURL)/posts/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("🔍 Get Post Request URL: \(url.absoluteString)")
        print("📥 Get Post Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 Get Post Response Body: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError("Server returned status code \(httpResponse.statusCode)")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(Post.self, from: data)
    }
    
    func startConversation(postId: String, message: String) async throws -> Conversation {
        let url = URL(string: "\(baseURL)/messages/conversations")!
        print("💬 startConversation Request URL: \(url.absoluteString)")
        print("💬 startConversation Message: \(message)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "post_id": postId,
            "message": message
        ]
        
        print("📤 startConversation Request Body: \(body)")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ startConversation Error: Invalid response type")
                throw APIError.invalidResponse
            }
            
            print("📥 startConversation Response Status: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📦 startConversation Response Body: \(responseString)")
            }
            
            if httpResponse.statusCode == 401 {
                print("❌ startConversation Error: Unauthorized")
                throw APIError.unauthorized
            }
            
            guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    print("❌ startConversation Error: \(errorResponse.message)")
                    throw APIError.serverError(errorResponse.message)
                }
                print("❌ startConversation Error: Failed to start conversation, status code: \(httpResponse.statusCode)")
                throw APIError.serverError("Failed to start conversation")
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let conversation = try decoder.decode(Conversation.self, from: data)
            print("✅ startConversation Success: Created conversation with ID: \(conversation.id)")
            return conversation
        } catch let error as APIError {
            print("❌ startConversation Error: \(error.localizedDescription)")
            throw error
        } catch {
            print("❌ startConversation Unexpected Error: \(error.localizedDescription)")
            throw APIError.networkError(error)
        }
    }
    
    func sendMessage(conversationId: String, content: String) async throws -> Message {
        let url = URL(string: "\(baseURL)/messages/send")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "conversation_id": conversationId,
            "content": content
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("💬 Send Message Request URL: \(url.absoluteString)")
        print("📥 Send Message Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 Send Message Response Body: \(responseString)")
        }
        
        guard httpResponse.statusCode == 201 else {
            let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.serverError(errorResponse.message)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(Message.self, from: data)
    }
    
    func getConversations() async throws -> [Conversation] {
        let url = URL(string: "\(baseURL)/messages/conversations")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("💬 Get Conversations Request URL: \(url.absoluteString)")
        print("📥 Get Conversations Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 Get Conversations Response Body: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.serverError(errorResponse.message)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode([Conversation].self, from: data)
    }
    
    func getMessages(conversationId: String) async throws -> [Message] {
        let url = URL(string: "\(baseURL)/messages/conversations/\(conversationId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("💬 Get Messages Request URL: \(url.absoluteString)")
        print("📥 Get Messages Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 Get Messages Response Body: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.serverError(errorResponse.message)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // Handle the new response structure
        let conversationWithMessages = try decoder.decode(ConversationWithMessages.self, from: data)
        return conversationWithMessages.messages
    }
    
    func getConversationWithMessages(conversationId: String) async throws -> ConversationWithMessages {
        let url = URL(string: "\(baseURL)/messages/conversations/\(conversationId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("💬 Get Conversation With Messages Request URL: \(url.absoluteString)")
        print("📥 Get Conversation With Messages Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 Get Conversation With Messages Response Body: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.serverError(errorResponse.message)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(ConversationWithMessages.self, from: data)
    }
    
    func markConversationAsRead(conversationId: String) async throws {
        let url = URL(string: "\(baseURL)/messages/conversations/\(conversationId)/read")!
        print("📱 Mark Conversation as Read Request URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📥 Mark Conversation as Read Response Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError("Failed to mark conversation as read: \(httpResponse.statusCode)")
        }
        
        print("✅ Successfully marked conversation as read")
    }
    
    func getUnreadCount(conversationId: String) async throws -> Int {
        let url = URL(string: "\(baseURL)/messages/conversations/\(conversationId)/unread")!
        print("📱 Get Unread Count Request URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📥 Get Unread Count Response Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError("Failed to get unread count: \(httpResponse.statusCode)")
        }
        
        let decoder = JSONDecoder()
        let countResponse = try decoder.decode(UnreadCountResponse.self, from: data)
        
        print("✅ Successfully got unread count: \(countResponse.count)")
        return countResponse.count
    }
    
    // MARK: - Settings
    
    func updateProfile(email: String? = nil, postalCode: String? = nil, countryCode: String? = nil) async throws -> User {
        let url = URL(string: "\(baseURL)/users/me")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Ensure we have email
        guard let email = email, !email.isEmpty else {
            throw APIError.serverError("Email is required")
        }
        
        // Ensure we have postalCode and countryCode
        guard let postalCode = postalCode, !postalCode.isEmpty else {
            throw APIError.serverError("Postal code is required")
        }
        
        guard let countryCode = countryCode, !countryCode.isEmpty else {
            throw APIError.serverError("Country code is required")
        }
        
        var bodyDict: [String: Any] = [
            "email": email,
            "location": [
                "postal_code": postalCode,
                "country_code": countryCode
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: bodyDict)
        print("📦 Update Profile Request Body: \(bodyDict)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📥 Update Profile Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 Update Profile Response Body: \(responseString)")
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.message)
            }
            throw APIError.serverError("Failed to update profile")
        }
        
        // Decode the updated user data
        let user = try JSONDecoder().decode(User.self, from: data)
        
        // Update UserDefaults with the new information
        UserDefaults.standard.set(user.email, forKey: "userEmail")
        UserDefaults.standard.set(user.location.postalCode, forKey: "postalCode")
        UserDefaults.standard.set(user.location.countryCode, forKey: "countryCode")
        
        return user
    }
    
    func updatePassword(currentPassword: String, newPassword: String) async throws {
        let url = URL(string: "\(baseURL)/users/password")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "current_password": currentPassword,
            "new_password": newPassword
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.message)
            }
            throw APIError.serverError("Failed to update password")
        }
    }
    
    func signOut() {
        // Clear all stored user data
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userNickName")
    }
    
    func getUserById(_ userId: String) async throws -> PublicUser {
        let url = URL(string: "\(baseURL)/users/\(userId)")!
        print("🔍 getUserById Request URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ getUserById Error: Invalid response type")
            throw APIError.invalidResponse
        }
        
        print("📥 getUserById Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 getUserById Response Body: \(responseString)")
        }
        
        if httpResponse.statusCode == 401 {
            print("❌ getUserById Error: Unauthorized")
            throw APIError.unauthorized
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                print("❌ getUserById Error: \(errorResponse.message)")
                throw APIError.serverError(errorResponse.message)
            }
            print("❌ getUserById Error: Failed to get user information, status code: \(httpResponse.statusCode)")
            throw APIError.serverError("Failed to get user information")
        }
        
        let user = try JSONDecoder().decode(PublicUser.self, from: data)
        print("✅ getUserById Success: Retrieved user with nickname: \(user.nickName)")
        return user
    }
    
    func getUnreadMessagesCount() async throws -> Int {
        let url = URL(string: "\(baseURL)/messages/conversations/unread")!
        print("📱 Get Total Unread Count Request URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📥 Get Total Unread Count Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 Get Total Unread Count Response Body: \(responseString)")
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            throw APIError.serverError("Invalid status code: \(httpResponse.statusCode)")
        }
        
        do {
            let decoder = JSONDecoder()
            let countResponse = try decoder.decode([String: Int].self, from: data)
            print("✅ Successfully got total unread count: \(countResponse["count"] ?? 0)")
            return countResponse["count"] ?? 0
        } catch {
            print("❌ Error decoding unread count: \(error)")
            throw APIError.decodingError(error)
        }
    }
    
    // MARK: - Posts
    
    func deletePost(postId: String) async throws {
        let url = URL(string: "\(baseURL)/posts/\(postId)")!
        print("🗑️ Delete Post Request URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📥 Delete Post Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 Delete Post Response Body: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 204 else {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.serverError(errorResponse?.message ?? "Failed to delete post: \(httpResponse.statusCode)")
        }
        
        print("✅ Successfully deleted post with ID: \(postId)")
    }
    
    func getPostsByUser(userId: String) async throws -> [Post] {
        let url = URL(string: "\(baseURL)/posts?user_id=\(userId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        print("🔍 Get Posts by User Request URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📥 Get Posts by User Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 Get Posts by User Response Body: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.message)
            }
            throw APIError.serverError("Failed to fetch posts for user \(userId)")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode([Post].self, from: data)
    }
    
    func getUserProfile(userId: String) async throws -> PublicUser {
        let url = URL(string: "\(baseURL)/users/\(userId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        print("👤 Get User Profile Request URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📥 Get User Profile Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 Get User Profile Response Body: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.message)
            }
            throw APIError.serverError("Failed to fetch user profile for \(userId)")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(PublicUser.self, from: data)
    }
}

// Response Models
struct AuthResponse: Codable {
    let token: String
    let user: User
}

struct ImageUploadResponse: Codable {
    let url: String
}

struct Conversation: Codable, Identifiable {
    let id: String
    let user1: ConversationUser
    let user2: ConversationUser
    let postId: String
    let createdAt: Date
    let lastMessage: Message?
    
    enum CodingKeys: String, CodingKey {
        case id
        case user1
        case user2
        case postId = "post_id"
        case createdAt = "created_at"
        case lastMessage = "last_message"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        user1 = try container.decode(ConversationUser.self, forKey: .user1)
        user2 = try container.decode(ConversationUser.self, forKey: .user2)
        postId = try container.decode(String.self, forKey: .postId)
        
        let dateString = try container.decode(String.self, forKey: .createdAt)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            createdAt = date
        } else {
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                createdAt = date
            } else {
                throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Invalid date format")
            }
        }
        
        lastMessage = try container.decodeIfPresent(Message.self, forKey: .lastMessage)
    }
}

struct ConversationUser: Codable {
    let id: String
    let nickName: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case nickName = "nick_name"
    }
}

struct UnreadCountResponse: Codable {
    let count: Int
}

struct ConversationWithMessages: Codable {
    let conversation: Conversation
    let messages: [Message]
}
