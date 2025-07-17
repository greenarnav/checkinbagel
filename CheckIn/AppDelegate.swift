//
//  AppDelegate.swift
//  CheckIn
//
//  Created by Ali Jawad on 11/06/2025.
//

import UIKit
import GoogleSignIn
import Firebase

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        // Enhanced tab bar appearance configuration
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        
        // Ensure background is visible and not transparent
        appearance.backgroundColor = UIColor.systemBackground
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
        
        // Configure tab bar item colors
        appearance.inlineLayoutAppearance.normal.iconColor = UIColor.systemBlue
        appearance.inlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.inlineLayoutAppearance.selected.iconColor = UIColor.systemBlue
        appearance.inlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.systemBlue]
        
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemBlue
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.systemBlue]
        
        appearance.compactInlineLayoutAppearance.normal.iconColor = UIColor.systemBlue
        appearance.compactInlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.compactInlineLayoutAppearance.selected.iconColor = UIColor.systemBlue
        appearance.compactInlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.systemBlue]
        
        // Apply the appearance to the tab bar
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().tintColor = UIColor.systemBlue
        UITabBar.appearance().unselectedItemTintColor = UIColor.secondaryLabel
        
        // Ensure tab bar is always visible and interactive
        UITabBar.appearance().isHidden = false
        UITabBar.appearance().isTranslucent = true
        UITabBar.appearance().isUserInteractionEnabled = true
        UITabBar.appearance().alpha = 1.0
        
        // Additional debugging for tab bar
        print("🔧 AppDelegate: Tab bar configuration applied")
        print("   - isHidden: \(UITabBar.appearance().isHidden)")
        print("   - isUserInteractionEnabled: \(UITabBar.appearance().isUserInteractionEnabled)")
        
        FirebaseApp.configure()
        return true
    }

    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        } else if SpotifyAuthManager.shared.sessionManager?.application(app, open: url, options: options) ?? false {
            return true
        }
        return false
    }
}
