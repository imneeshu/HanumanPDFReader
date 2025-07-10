//
//  StrokeAnimatedText.swift
//  Hanuman PDF Reader
//
//  Created by Neeshu Kumar on 16/06/25.
//


import SwiftUI

// MARK: - Stroke Animation Text View
struct StrokeAnimatedText: View {
    let text: String
    let font: Font
    let gradient: LinearGradient
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .font(font)
                    .foregroundStyle(gradient)
                    .overlay(
                        // Stroke effect
                        Text(String(character))
                            .font(font)
                            .foregroundColor(.clear)
                            .background(
                                Text(String(character))
                                    .font(font)
                                    .foregroundStyle(gradient)
                                    .mask(
                                        Rectangle()
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [.black, .clear]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .scaleEffect(x: animationProgress > CGFloat(index) / CGFloat(text.count) ? 1 : 0, anchor: .leading)
                                    )
                            )
                    )
                    .opacity(animationProgress > CGFloat(index) / CGFloat(text.count) ? 1 : 0.2)
                    .scaleEffect(animationProgress > CGFloat(index) / CGFloat(text.count) ? 1 : 0.8)
                    .animation(
                        .easeInOut(duration: 0.1)
                        .delay(Double(index) * 0.05),
                        value: animationProgress
                    )
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.1)) {
                animationProgress = 1
            }
        }
    }
}

// MARK: - Writing Effect Text View (Alternative approach)
struct WritingEffectText: View {
    let text: String
    let font: Font
    let gradient: LinearGradient
    @State private var visibleCharacters: Int = 0
    
    var body: some View {
        HStack(spacing: 1) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .font(font)
                    .foregroundStyle(gradient)
                    .opacity(index < visibleCharacters ? 1 : 0)
                    .scaleEffect(index < visibleCharacters ? 1 : 0.5)
                    .rotationEffect(.degrees(index < visibleCharacters ? 0 : -10))
                    .animation(
                        .spring(response: 0.3, dampingFraction: 0.7)
                        .delay(Double(index) * 0.08),
                        value: visibleCharacters
                    )
            }
        }
        .onAppear {
            for i in 0...text.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
                    visibleCharacters = i
                }
            }
        }
    }
}

// MARK: - Advanced Stroke Writing Effect
struct AdvancedStrokeText: View {
    let text: String
    let font: Font
    let gradient: LinearGradient
    @State private var strokeProgress: [CGFloat]
    
    init(text: String, font: Font, gradient: LinearGradient) {
        self.text = text
        self.font = font
        self.gradient = gradient
        self._strokeProgress = State(initialValue: Array(repeating: 0, count: text.count))
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                ZStack {
                    // Background character (faded)
                    Text(String(character))
                        .font(font)
                        .foregroundColor(.gray.opacity(0.3))
                    
                    // Animated stroke character
                    Text(String(character))
                        .font(font)
                        .foregroundStyle(gradient)
                        .mask(
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(stops: [
                                            .init(color: .black, location: 0),
                                            .init(color: .black, location: strokeProgress[index]),
                                            .init(color: .clear, location: strokeProgress[index]),
                                            .init(color: .clear, location: 1)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .overlay(
                            // Writing cursor effect
                            Rectangle()
                                .fill(gradient)
                                .frame(width: 2, height: font == .largeTitle ? 40 : 30)
                                .offset(x: strokeProgress[index] * characterWidth(for: character) - characterWidth(for: character)/2)
                                .opacity(strokeProgress[index] < 1 && strokeProgress[index] > 0 ? 1 : 0)
                                .animation(.easeInOut(duration: 0.1), value: strokeProgress[index])
                        )
                }
                .animation(.easeInOut(duration: 0.2), value: strokeProgress[index])
            }
        }
        .onAppear {
            animateStrokes()
        }
    }
    
    private func characterWidth(for character: Character) -> CGFloat {
        // Approximate character widths - you might want to make this more precise
        switch character {
        case " ": return 10
        case "i", "l", "I": return 15
        case "m", "w", "M", "W": return 35
        default: return 25
        }
    }
    
    private func animateStrokes() {
        for (index, _) in text.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    strokeProgress[index] = 1.0
                }
            }
        }
    }
}

// MARK: - Enhanced Splash Screen
struct EnhancedSplashScreenView: View {
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var pulseEffect = false
    
    let gradient = backgroundGradients
    let navy = Color(red: 0.047, green: 0.235, blue: 0.471)
    
    var body: some View {
        ZStack {
            gradient.ignoresSafeArea()
            
            // Animated background elements
            ForEach(0..<6) { i in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: CGFloat.random(in: 50...120))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .scaleEffect(pulseEffect ? 1.2 : 0.8)
                    .animation(
                        .easeInOut(duration: Double.random(in: 2...4))
                        .repeatForever(autoreverses: true),
                        value: pulseEffect
                    )
            }
            
            VStack(spacing: 30) {
                // App icon or logo placeholder
                ZStack {
                    Circle()
                        .fill(navy)
                        .frame(width: 100, height: 100)
                        .scaleEffect(showTitle ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showTitle)
                    
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .scaleEffect(showTitle ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: showTitle)
                }
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                
                // Main title with stroke animation
                if showTitle {
                    AdvancedStrokeText(
                        text: "Smart PDF Toolkit",
                        font: .system(size: 30, weight: .bold, design: .rounded),
                        gradient: LinearGradient(
                            colors: [navy, navy],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }
                
                // Subtitle
                if showSubtitle {
                    Text("Your Ultimate PDF Companion")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(navy.opacity(0.8))
                        .opacity(showSubtitle ? 1 : 0)
                        .scaleEffect(showSubtitle ? 1 : 0.8)
                        .animation(.easeInOut(duration: 0.6), value: showSubtitle)
                }
                
                // Loading indicator
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(navy)
                            .frame(width: 8, height: 8)
                            .scaleEffect(pulseEffect ? 1.3 : 0.7)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                                value: pulseEffect
                            )
                    }
                }
                .opacity(showSubtitle ? 1 : 0)
                .animation(.easeInOut(duration: 0.4).delay(0.8), value: showSubtitle)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4)) {
                showTitle = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    showSubtitle = true
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                pulseEffect = true
            }
        }
    }
}

// MARK: - Simple Typewriter Effect (Bonus)
struct TypewriterText: View {
    let text: String
    let font: Font
    let gradient: LinearGradient
    @State private var displayedText = ""
    @State private var currentIndex = 0
    
    var body: some View {
        Text(displayedText + (currentIndex < text.count ? "|" : ""))
            .font(font)
            .foregroundStyle(gradient)
            .onAppear {
                typeText()
            }
    }
    
    private func typeText() {
        Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { timer in
            if currentIndex < text.count {
                displayedText += String(text[text.index(text.startIndex, offsetBy: currentIndex)])
                currentIndex += 1
            } else {
                timer.invalidate()
                // Remove cursor after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    displayedText = String(displayedText.dropLast())
                }
            }
        }
    }
}

// MARK: - Usage in your ContentView
// Replace your existing SplashScreenView with:
/*
struct SplashScreenView: View {
    var body: some View {
        EnhancedSplashScreenView()
    }
}
*/
