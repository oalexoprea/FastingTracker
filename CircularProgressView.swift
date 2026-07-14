import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    let formattedElapsed: String
    let formattedRemaining: String
    let isFasting: Bool
    
    var body: some View {
        ZStack {
            // Background Circle
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: 24)
            
            // Progress Circle with Gradient
            Circle()
                .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    AngularGradient(
                        colors: [Color.orange, Color.red, Color.purple, Color.orange],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 24, lineCap: .round, lineJoin: .round)
                )
                .rotationEffect(Angle(degrees: -90))
                .animation(.linear(duration: 1.0), value: progress)
            
            // Inside text
            VStack(spacing: 8) {
                Text(isFasting ? "TIMP SCURS" : "PREGĂTIT")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                Text(formattedElapsed)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                if isFasting {
                    Divider()
                        .frame(width: 120)
                    
                    Text("RĂMAS")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Text(formattedRemaining)
                        .font(.headline)
                        .foregroundColor(.orange)
                }
            }
        }
        .frame(width: 280, height: 280)
        .padding()
    }
}

struct CircularProgressView_Previews: PreviewProvider {
    static var previews: some View {
        CircularProgressView(
            progress: 0.45,
            formattedElapsed: "07:12:00",
            formattedRemaining: "08:48:00",
            isFasting: true
        )
        .preferredColorScheme(.dark)
    }
}
