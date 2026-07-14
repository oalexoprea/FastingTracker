import Foundation
import Combine

class FastingViewModel: ObservableObject {
    @Published var currentPlan: FastingPlan = .classic16 {
        didSet {
            saveState()
        }
    }
    @Published var isFasting: Bool = false
    @Published var startTime: Date?
    @Published var endTime: Date?
    @Published var history: [FastingLog] = []
    
    // Timer properties
    @Published var elapsedSeconds: TimeInterval = 0
    @Published var progress: Double = 0.0
    
    private var timer: AnyCancellable?
    
    init() {
        loadHistory()
        loadState()
        
        // Dacă postul era activ, repornește temporizatorul și calculează timpul scurs
        if isFasting, let start = startTime {
            let elapsed = Date().timeIntervalSince(start)
            let total = Double(currentPlan.fastingHours * 3600)
            
            if elapsed >= total {
                // Postul s-a încheiat în timp ce aplicația a fost închisă
                self.elapsedSeconds = total
                self.progress = 1.0
            } else {
                self.elapsedSeconds = elapsed
                self.progress = elapsed / total
                startTimer()
            }
        }
    }
    
    var totalSeconds: Double {
        Double(currentPlan.fastingHours * 3600)
    }
    
    var remainingSeconds: TimeInterval {
        max(totalSeconds - elapsedSeconds, 0)
    }
    
    var formattedElapsed: String {
        formatTime(elapsedSeconds)
    }
    
    var formattedRemaining: String {
        formatTime(remainingSeconds)
    }
    
    func startFasting() {
        startTime = Date()
        endTime = startTime?.addingTimeInterval(totalSeconds)
        isFasting = true
        elapsedSeconds = 0
        progress = 0.0
        
        saveState()
        startTimer()
    }
    
    func endFasting() {
        guard let start = startTime else { return }
        let now = Date()
        let actualDuration = now.timeIntervalSince(start)
        let successfullyCompleted = actualDuration >= totalSeconds
        
        let newLog = FastingLog(
            plan: currentPlan,
            startDate: start,
            endDate: now,
            completedSuccessfully: successfullyCompleted,
            durationInSeconds: actualDuration
        )
        
        history.insert(newLog, at: 0)
        saveHistory()
        
        // Reset state
        isFasting = false
        startTime = nil
        endTime = nil
        elapsedSeconds = 0
        progress = 0.0
        stopTimer()
        saveState()
    }
    
    func cancelFasting() {
        isFasting = false
        startTime = nil
        endTime = nil
        elapsedSeconds = 0
        progress = 0.0
        stopTimer()
        saveState()
    }
    
    private func startTimer() {
        timer?.cancel()
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimer()
            }
    }
    
    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }
    
    private func updateTimer() {
        guard let start = startTime else { return }
        let elapsed = Date().timeIntervalSince(start)
        let total = totalSeconds
        
        DispatchQueue.main.async {
            if elapsed >= total {
                self.elapsedSeconds = total
                self.progress = 1.0
                self.stopTimer()
                // Aici se poate adăuga o notificare locală
            } else {
                self.elapsedSeconds = elapsed
                self.progress = elapsed / total
            }
        }
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // MARK: - Persistence
    
    private func saveState() {
        UserDefaults.standard.set(currentPlan.rawValue, forKey: "fasting_plan")
        UserDefaults.standard.set(isFasting, forKey: "is_fasting")
        UserDefaults.standard.set(startTime, forKey: "start_time")
        UserDefaults.standard.set(endTime, forKey: "end_time")
    }
    
    private func loadState() {
        if let planRaw = UserDefaults.standard.string(forKey: "fasting_plan"),
           let plan = FastingPlan(rawValue: planRaw) {
            self.currentPlan = plan
        }
        self.isFasting = UserDefaults.standard.bool(forKey: "is_fasting")
        self.startTime = UserDefaults.standard.object(forKey: "start_time") as? Date
        self.endTime = UserDefaults.standard.object(forKey: "end_time") as? Date
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: "fasting_history")
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "fasting_history"),
           let decoded = try? JSONDecoder().decode([FastingLog].self, from: data) {
            self.history = decoded
        }
    }
}
