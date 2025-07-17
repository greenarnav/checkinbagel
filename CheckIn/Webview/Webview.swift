//
//  Webview.swift
//  CheckIn
//
//  Created by Masroor Elahi on 18/06/2025.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    var htmlContent: String
    
    // Create and configure the WKWebView
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = UIColor.clear
        webView.isOpaque = false  // Ensure the background is not opaque (transparent)
        return webView
    }
    
    // Update the WKWebView with the HTML content
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlContent, baseURL: nil)
    }
}


let emotionHtml: String = """
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Loading Analysis</title>
  <style>
    body {
      margin: 0;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: transparent;
      color: #ffffff;
      padding: 20px;
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      min-height: 50vh;
      text-align: center;
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
  <div class="loading-message">Loading emotion analysis...</div>
  <div class="spinner"></div>
</body>
</html>
"""
