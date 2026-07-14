import Foundation

struct FastingLog: Identifiable, Codable {
    var id = UUID()
    let plan: FastingPlan
    let startDate: Date
    let endDate: Date
    let completedSuccessfully: Bool
    let durationInSeconds: TimeInterval
    
    var formattedDuration: String {
        let hours = Int(durationInSeconds) / 3600
        let minutes = (Int(durationInSeconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ro_RO")
        return formatter.string(from: startDate)
    }
}
