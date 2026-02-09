//
//  CircularProgressView.swift
//  TokenMint
//
//  Circular countdown timer visualization
//

import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    var lineWidth: CGFloat = 4
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(lineWidth: lineWidth)
                .opacity(0.3)
                .foregroundColor(color)
            
            // Progress circle
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .foregroundColor(color)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear(duration: 1.0), value: progress)
        }
    }
}
