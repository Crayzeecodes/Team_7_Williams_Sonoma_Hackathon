//
//  AuthViewModel.swift
//  WSHackathonApp
//

import Foundation
import Combine

class AuthViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    // Note: Assuming running on simulator connecting to localhost (127.0.0.1)
    let baseURL = "http://127.0.0.1:3001/auth"
    
    struct AuthResponse: Codable {
        let token: String
        let user: SessionManager.User
    }
    
    func login() {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(baseURL)/login") else { return }
        let body = ["email": email, "password": password]
        
        performRequest(url: url, body: body)
    }
    
    func register() {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(baseURL)/register") else { return }
        let body = ["name": name, "email": email, "password": password]
        
        performRequest(url: url, body: body)
    }
    
    private func performRequest(url: URL, body: [String: String]) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received"
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                    self.errorMessage = "Error: \(httpResponse.statusCode)"
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(AuthResponse.self, from: data)
                    SessionManager.shared.login(token: result.token, user: result.user)
                } catch {
                    self.errorMessage = "Failed to decode response"
                }
            }
        }.resume()
    }
}
