//
//  GradientBackground.swift
//  Micro Diary
//
//  Created by Ryo Asai on 2025/09/30.
//

import SwiftUI

struct GradientBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Group {
            if shouldShowGradient {
                // ライトモード: グラデーション背景
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "667eea"), // 明るい青紫色（左上）
                        Color(hex: "764ba2")  // 濃い紫色（右下）
                    ]),
                    startPoint: .topLeading,    // 左上 (0%, 0%)
                    endPoint: .bottomTrailing   // 右下 (100%, 100%)
                )
            } else {
                // ダークモード: 黒背景
                Color.black
            }
        }
        .ignoresSafeArea()
    }
    
    private var shouldShowGradient: Bool {
        switch themeManager.currentTheme {
        case .light:
            return true
        case .dark:
            return false
        case .system:
            return colorScheme == .light
        }
    }
}

// Color extension for hex color support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Background modifier for easy application
struct GradientBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(GradientBackground())
    }
}

extension View {
    func gradientBackground() -> some View {
        modifier(GradientBackgroundModifier())
    }
}

// テーマ対応のカード背景色
extension Color {
    static var cardBackground: Color {
        Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor.systemGray6.withAlphaComponent(0.8)
            default:
                return UIColor.white.withAlphaComponent(0.9)
            }
        })
    }
    
    static var secondaryCardBackground: Color {
        Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor.systemGray5.withAlphaComponent(0.6)
            default:
                return UIColor.white.withAlphaComponent(0.7)
            }
        })
    }
}

#Preview("Light Mode") {
    VStack {
        Text("Light Mode")
            .font(.title)
            .foregroundColor(.white)
        
        Text("グラデーション背景")
            .font(.body)
            .foregroundColor(.white.opacity(0.8))
    }
    .gradientBackground()
    .onAppear {
        ThemeManager.shared.setTheme(.light)
    }
}

#Preview("Dark Mode") {
    VStack {
        Text("Dark Mode")
            .font(.title)
            .foregroundColor(.white)
        
        Text("黒背景")
            .font(.body)
            .foregroundColor(.white.opacity(0.8))
    }
    .gradientBackground()
    .onAppear {
        ThemeManager.shared.setTheme(.dark)
    }
}
