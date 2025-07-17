//
//  CheckInStockTracker.swift
//  CheckIn
//
//  Created by AI Assistant on 28/06/2025.
//

import SwiftUI

// MARK: - Stock Data Models
struct Stock: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let price: Double
    let change: Double
    let changePercent: Double
    
    var isPositive: Bool { change >= 0 }
    var changeText: String {
        let sign = isPositive ? "+" : ""
        return "\(sign)\(String(format: "%.2f", change))"
    }
    var percentText: String {
        let sign = isPositive ? "+" : ""
        return "\(sign)\(String(format: "%.2f", changePercent))%"
    }
}

// MARK: - CheckIn Stock Tracker View
struct CheckInStockTrackerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedStocks: Set<String> = Set()
    @State private var portfolioValue: Double = 47532.85
    @State private var portfolioChange: Double = 1247.30
    @State private var isRefreshing = false
    
    private let watchlistStocks = [
        Stock(symbol: "AAPL", name: "Apple Inc.", price: 187.45, change: 2.34, changePercent: 1.26),
        Stock(symbol: "GOOGL", name: "Alphabet Inc.", price: 2734.67, change: -15.23, changePercent: -0.55),
        Stock(symbol: "MSFT", name: "Microsoft Corp.", price: 334.89, change: 5.67, changePercent: 1.72),
        Stock(symbol: "TSLA", name: "Tesla Inc.", price: 267.43, change: -8.92, changePercent: -3.23),
        Stock(symbol: "AMZN", name: "Amazon.com Inc.", price: 143.67, change: 3.45, changePercent: 2.46),
        Stock(symbol: "NVDA", name: "NVIDIA Corp.", price: 789.32, change: 12.56, changePercent: 1.62),
        Stock(symbol: "META", name: "Meta Platforms", price: 298.45, change: -4.67, changePercent: -1.54),
        Stock(symbol: "NFLX", name: "Netflix Inc.", price: 445.23, change: 7.89, changePercent: 1.80)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with portfolio summary
                        portfolioSummaryView
                        
                        // Mood Impact Selector
                        moodImpactSelector
                        
                        // Stock Watchlist
                        stockWatchlistView
                        
                        // Market Insights for Mood
                        marketInsightsView
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                .refreshable {
                    await refreshData()
                }
            }
            .navigationTitle("Stock Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await refreshData()
                        }
                    }) {
                        Image(systemName: isRefreshing ? "arrow.clockwise" : "arrow.clockwise")
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                    }
                }
            }
        }
    }
    
    // MARK: - Portfolio Summary
    private var portfolioSummaryView: some View {
        VStack(spacing: 16) {
            Text("Portfolio Impact on Mood")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                Text("$\(String(format: "%.2f", portfolioValue))")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Image(systemName: portfolioChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .foregroundColor(portfolioChange >= 0 ? .green : .red)
                    
                    Text(portfolioChange >= 0 ? "+$\(String(format: "%.2f", portfolioChange))" : "-$\(String(format: "%.2f", abs(portfolioChange)))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(portfolioChange >= 0 ? .green : .red)
                    
                    Text("today")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(portfolioChange >= 0 ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(portfolioChange >= 0 ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Mood Impact Selector
    private var moodImpactSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select stocks that impact your mood")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Choose which stocks affect your emotional state the most")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(watchlistStocks.prefix(6)) { stock in
                    stockSelectionButton(stock)
                }
            }
        }
    }
    
    private func stockSelectionButton(_ stock: Stock) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                if selectedStocks.contains(stock.symbol) {
                    selectedStocks.remove(stock.symbol)
                } else {
                    selectedStocks.insert(stock.symbol)
                }
            }
        }) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(stock.symbol)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("$\(String(format: "%.0f", stock.price))")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(stock.changeText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(stock.isPositive ? .green : .red)
                    
                    if selectedStocks.contains(stock.symbol) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selectedStocks.contains(stock.symbol) ? Color.blue.opacity(0.2) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(selectedStocks.contains(stock.symbol) ? Color.blue.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Stock Watchlist
    private var stockWatchlistView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Watchlist")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            LazyVStack(spacing: 8) {
                ForEach(watchlistStocks) { stock in
                    stockRowView(stock)
                }
            }
        }
    }
    
    private func stockRowView(_ stock: Stock) -> some View {
        HStack(spacing: 12) {
            // Stock symbol and name
            VStack(alignment: .leading, spacing: 2) {
                Text(stock.symbol)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text(stock.name)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Price and change
            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(String(format: "%.2f", stock.price))")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: 4) {
                    Image(systemName: stock.isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10))
                        .foregroundColor(stock.isPositive ? .green : .red)
                    
                    Text(stock.percentText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(stock.isPositive ? .green : .red)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Market Insights
    private var marketInsightsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mood Insights")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                insightCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Market Momentum",
                    description: "Tech stocks are up 2.3% today. Your selected stocks show positive correlation with your mood patterns.",
                    color: .green
                )
                
                insightCard(
                    icon: "brain.head.profile",
                    title: "Emotional Impact",
                    description: "High volatility in TSLA may increase stress levels. Consider reducing exposure if it affects your wellbeing.",
                    color: .orange
                )
                
                insightCard(
                    icon: "heart.fill",
                    title: "Wellness Tip",
                    description: "Your mood typically improves when your portfolio is stable. Focus on long-term investments for better emotional balance.",
                    color: .blue
                )
            }
        }
    }
    
    private func insightCard(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Data Refresh
    private func refreshData() async {
        isRefreshing = true
        
        // Simulate API call delay
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Simulate data updates
        withAnimation(.easeInOut(duration: 0.3)) {
                    portfolioValue = 0
        portfolioChange = 0
            isRefreshing = false
        }
    }
}

// MARK: - Preview
#if DEBUG
struct CheckInStockTrackerView_Previews: PreviewProvider {
    static var previews: some View {
        CheckInStockTrackerView()
    }
}
#endif 