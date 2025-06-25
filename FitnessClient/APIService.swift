// APIService.swift
import Foundation

// Define potential API errors
enum APINetworkError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case noData
    case decodingError(Error)
    case serverError(statusCode: Int, message: String?) // For non-2xx responses
    case unauthorized // Specifically for 401
    case forbidden    // Specifically for 403
    case unknown(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL provided was invalid."
        case .requestFailed(let error):
            return "The network request failed: \(error.localizedDescription)"
        case .noData:
            return "No data was received from the server."
        case .decodingError(let error):
            return "Failed to decode the server's response: \(error.localizedDescription)"
        case .serverError(let statusCode, let message):
            return message ?? "Server error with status code: \(statusCode)."
        case .unauthorized:
            return "Unauthorized. Please check your credentials or log in again."
        case .forbidden:
            return "Access forbidden. You do not have permission to access this resource."
        case .unknown(let statusCode):
            return "An unknown error occurred with status code: \(statusCode)."
        }
    }
}


@MainActor // If this service will publish changes that update UI directly.
           // Otherwise, individual ViewModels can handle MainActor dispatch.
class APIService: ObservableObject {
    private let baseURLString = "https://dev-api.fitnessapp.jutechnik.com/api/v1" // Your API base URL
    private let authService: AuthService // Dependency for getting the auth token

    // Custom JSONDecoder for consistent date parsing
    private var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        let iso8601WithMillisecondsFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter
        }()
        decoder.dateDecodingStrategy = .formatted(iso8601WithMillisecondsFormatter)
        return decoder
    }
    
    // Custom JSONEncoder (if you need to send data with specific date encoding)
    private var jsonEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        let iso8601WithMillisecondsFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            // ... (same setup as decoder's formatter)
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter
        }()
        encoder.dateEncodingStrategy = .formatted(iso8601WithMillisecondsFormatter)
        return encoder
    }


    init(authService: AuthService) {
        self.authService = authService
    }

    // --- Generic GET Request ---
    func GET<T: Decodable>(endpoint: String, queryItems: [URLQueryItem]? = nil) async throws -> T {
        return try await performRequest(endpoint: endpoint, method: "GET", body: Optional<Data>.none, queryItems: queryItems)
    }

    // --- Generic POST Request ---
    func POST<Body: Encodable, T: Decodable>(endpoint: String, body: Body, queryItems: [URLQueryItem]? = nil) async throws -> T {
        let bodyData = try jsonEncoder.encode(body)
        return try await performRequest(endpoint: endpoint, method: "POST", body: bodyData, queryItems: queryItems)
    }

    // --- Generic PUT Request ---
    func PUT<Body: Encodable, T: Decodable>(endpoint: String, body: Body, queryItems: [URLQueryItem]? = nil) async throws -> T {
        let bodyData = try jsonEncoder.encode(body)
        return try await performRequest(endpoint: endpoint, method: "PUT", body: bodyData, queryItems: queryItems)
    }
    
    // --- Generic PUT Request (No Response Body Expected, or don't care about it) ---
    func PUT<Body: Encodable>(endpoint: String, body: Body, queryItems: [URLQueryItem]? = nil) async throws {
        let bodyData = try jsonEncoder.encode(body)
        // Call performRequest but ignore the decodable result for Void equivalent
        let _: EmptyDecodable = try await performRequest(endpoint: endpoint, method: "PUT", body: bodyData, queryItems: queryItems)
    }


    // --- Generic DELETE Request (No Response Body Expected) ---
    func DELETE(endpoint: String, queryItems: [URLQueryItem]? = nil) async throws {
        // Call performRequest but ignore the decodable result for Void equivalent
        // We use EmptyDecodable for the type T when we don't expect a body or don't need to decode one.
        let _: EmptyDecodable = try await performRequest(endpoint: endpoint, method: "DELETE", body: Optional<Data>.none, queryItems: queryItems)
    }
    
    // --- Generic PATCH Request ---
    func PATCH<Body: Encodable, T: Decodable>(endpoint: String, body: Body, queryItems: [URLQueryItem]? = nil) async throws -> T {
        let bodyData = try jsonEncoder.encode(body) // Use self.jsonEncoder
        return try await performRequest(endpoint: endpoint, method: "PATCH", body: bodyData, queryItems: queryItems)
    }

    // Overload for PATCH when no decodable response body is expected (e.g. 204 No Content)
    func PATCH<Body: Encodable>(endpoint: String, body: Body, queryItems: [URLQueryItem]? = nil) async throws {
        let bodyData = try jsonEncoder.encode(body)
        let _: EmptyDecodable = try await performRequest(endpoint: endpoint, method: "PATCH", body: bodyData, queryItems: queryItems)
    }

    // --- Core Request Logic ---
    private func performRequest<T: Decodable>(endpoint: String, method: String, body: Data? = nil, queryItems: [URLQueryItem]? = nil) async throws -> T {
        guard let token = authService.authToken else {
            // If no token, trigger logout or signal re-authentication needed
            // This could also be handled by the caller if they check authService.authToken first
            print("APIService: No auth token found. User needs to log in.")
            await authService.logout() // Forcing logout if token is missing during an API call
            throw APINetworkError.unauthorized // No token, so unauthorized
        }

        var urlComponents = URLComponents(string: baseURLString)
        urlComponents?.path += endpoint // Append endpoint to base path
        urlComponents?.queryItems = queryItems

        guard let url = urlComponents?.url else {
            throw APINetworkError.invalidURL
        }
        
        print("APIService: Requesting \(method) \(url)")

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        if let body = body {
            request.httpBody = body
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APINetworkError.unknown(statusCode: -1) // Or a more specific "cannotParseResponse"
        }
        
        print("APIService: Received status code: \(httpResponse.statusCode) for \(method) \(url)")

        // --- TEMPORARY DEBUGGING: Print raw response data for non-2xx ---
        // if !(200..<300).contains(httpResponse.statusCode) || T.self == EmptyDecodable.self {
        //     if let jsonString = String(data: data, encoding: .utf8), !jsonString.isEmpty {
        //         print("APIService RAW RESPONSE (\(httpResponse.statusCode)):\n\(jsonString)\n--------------------")
        //     } else if data.isEmpty {
        //         print("APIService RAW RESPONSE (\(httpResponse.statusCode)): Empty")
        //     }
        // }
        // --- END TEMPORARY DEBUGGING ---

        switch httpResponse.statusCode {
        case 200..<300: // Success range
            // Handle 204 No Content specifically if T is EmptyDecodable
            if httpResponse.statusCode == 204, T.self == EmptyDecodable.self {
                 // For 204 No Content, if we expect no body, return a dummy EmptyDecodable
                // This cast is a bit of a trick to satisfy the generic return type.
                guard let empty = EmptyDecodable() as? T else {
                    // This should ideally not happen if T is correctly EmptyDecodable
                    throw APINetworkError.decodingError(NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Type mismatch for EmptyDecodable"]))
                }
                return empty
            }
            // For other success codes, or if T is not EmptyDecodable for 204, try to decode
            guard !data.isEmpty else {
                if T.self == EmptyDecodable.self { // If we expect no content and got no content
                    guard let empty = EmptyDecodable() as? T else { throw APINetworkError.decodingError(NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Type mismatch for EmptyDecodable"]))}
                    return empty
                }
                throw APINetworkError.noData // Expected data but got none
            }
            do {
                return try jsonDecoder.decode(T.self, from: data)
            } catch {
                print("APIService: Decoding error - \(error)")
                throw APINetworkError.decodingError(error)
            }
        case 401:
            print("APIService: Unauthorized (401). Logging out user.")
            await authService.logout() // Automatically log out user on 401
            throw APINetworkError.unauthorized
        case 403:
            throw APINetworkError.forbidden
        case 409: // <<< NEW CASE
            do {
                let errorResponse = try jsonDecoder.decode(APIErrorResponse.self, from: data)
                throw APINetworkError.serverError(statusCode: 409, message: errorResponse.error) // Pass specific message
            } catch {
                throw APINetworkError.serverError(statusCode: 409, message: "A conflict occurred.") // Fallback
            }
        default:
            // Try to decode an APIErrorResponse from the body for other errors
            do {
                let errorResponse = try jsonDecoder.decode(APIErrorResponse.self, from: data)
                throw APINetworkError.serverError(statusCode: httpResponse.statusCode, message: errorResponse.error)
            } catch {
                // If decoding our standard error fails, throw a generic unknown error
                throw APINetworkError.unknown(statusCode: httpResponse.statusCode)
            }
        }
    }
}

// Helper struct for requests where we don't expect a decodable response body (e.g., DELETE, or PUT without response)
struct EmptyDecodable: Decodable {}
