//
//  ContactDetailManager.swift
//  CheckIn
//
//  Created by Masroor Elahi on 19/06/2025.
//

import Foundation

class ContactDetailManager: ObservableObject {
    @Published var htmlContent: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    private var contactName: String?
    
    // Function to fetch HTML from an API (POST request with parameters)
    func fetchHTML(from url: URL, parameters: [String: Any]) {
        // Store the contact name for HTML processing
        self.contactName = parameters["contact_name"] as? String
        
        // Use loading state instead of dummy data
        isLoading = true
        self.htmlContent = generateManualHTML()
        // Note: Replace this with actual API call when ready
        
        isLoading = true
        errorMessage = nil
        
        // Create a URLRequest with POST method
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Set the content type for the request (application/x-www-form-urlencoded or application/json)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        // Convert parameters to a URL-encoded string
        guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: []) else { return }
        request.httpBody = jsonData
        
        // Perform the network request
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data, let html = String(data: data, encoding: .utf8) else {
                    self?.errorMessage = "Failed to load content."
                    return
                }
                
                // Process and update the HTML content
                self?.htmlContent = self?.processHTML(html) ?? html
            }
        }.resume()
    }
    
    // Function to process HTML content and replace generic text with contact name
    private func processHTML(_ html: String) -> String {
        var processedHTML = html
        
        // Remove "Checkin" title
        processedHTML = processedHTML.replacingOccurrences(of: "Checkin", with: "")
        
        // Replace "Unknown User's Emotion:" with just the contact name
        if let name = contactName {
            processedHTML = processedHTML.replacingOccurrences(of: "Unknown User's Emotion:", with: name)
            processedHTML = processedHTML.replacingOccurrences(of: "Unknown User", with: name)
            processedHTML = processedHTML.replacingOccurrences(of: "Your Emotion:", with: name)
        }
        
        // Remove any mentions of "Emotion:" if we want to be more aggressive
        processedHTML = processedHTML.replacingOccurrences(of: "Emotion:", with: "")
        
        return processedHTML
    }
    
    // Function to generate empty HTML content - no dummy data during loading
    private func generateManualHTML() -> String {
        let contactName = self.contactName ?? "Contact"
        
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
          <title>\(contactName)</title>
          <style>
            body {
              margin: 0;
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
              background: transparent;
              color: #ffffff;
              padding: 20px;
              text-align: center;
              display: flex;
              flex-direction: column;
              justify-content: center;
              align-items: center;
              min-height: 50vh;
            }
            
            .loading-message {
              font-size: 18px;
              color: #ccc;
              margin-bottom: 20px;
            }
            
            .spinner {
              width: 40px;
              height: 40px;
              border: 4px solid rgba(255,255,255,0.3);
              border-top: 4px solid #fff;
              border-radius: 50%;
              animation: spin 1s linear infinite;
            }
            
            @keyframes spin {
              0% { transform: rotate(0deg); }
              100% { transform: rotate(360deg); }
            }
          </style>
        </head>
        <body>
          <div class="loading-message">Loading analysis for \(contactName)...</div>
          <div class="spinner"></div>
        </body>
        </html>
        """
    }
}
