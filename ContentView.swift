import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = FastingViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TimerTabView(viewModel: viewModel)
                .tabItem {
                    Label("Cronometru", systemImage: "timer")
                }
                .tag(0)
            
            PlansTabView(viewModel: viewModel)
                .tabItem {
                    Label("Planuri", systemImage: "list.bullet.clipboard")
                }
                .tag(1)
            
            HistoryTabView(viewModel: viewModel)
                .tabItem {
                    Label("Istoric", systemImage: "clock.arrow.circlepath")
                }
                .tag(2)
        }
        .accentColor(.orange)
    }
}

// MARK: - Timer Tab
struct TimerTabView: View {
    @ObservedObject var viewModel: FastingViewModel
    @State private var showCancelAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                // Card Plan Curent
                VStack(spacing: 4) {
                    Text("Plan curent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    Text(viewModel.currentPlan.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(20)
                
                Spacer()
                
                // Circular Progress
                CircularProgressView(
                    progress: viewModel.progress,
                    formattedElapsed: viewModel.formattedElapsed,
                    formattedRemaining: viewModel.formattedRemaining,
                    isFasting: viewModel.isFasting
                )
                
                Spacer()
                
                // Start / Stop Buttons
                if !viewModel.isFasting {
                    Button(action: {
                        viewModel.startFasting()
                    }) {
                        Text("Începe Postul")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(28)
                            .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 32)
                } else {
                    VStack(spacing: 12) {
                        Button(action: {
                            viewModel.endFasting()
                        }) {
                            Text("Finalizează Postul")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.green)
                                .cornerRadius(28)
                                .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        
                        Button(action: {
                            showCancelAlert = true
                        }) {
                            Text("Anulează Postul")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                                .padding()
                        }
                    }
                    .padding(.horizontal, 32)
                }
                
                Spacer()
                
                // Start & End Date Labels
                if viewModel.isFasting, let start = viewModel.startTime, let end = viewModel.endTime {
                    HStack(spacing: 40) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ÎNCEPUT")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(formatTimeOnly(start))
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("SFÂRȘIT ESTIMAT")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(formatTimeOnly(end))
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Post Intermitent")
            .alert(isPresented: $showCancelAlert) {
                Alert(
                    title: Text("Anulezi postul curent?"),
                    message: Text("Progresul tău de până acum nu va fi salvat în istoric."),
                    primaryButton: .destructive(Text("Da, anulează")) {
                        viewModel.cancelFasting()
                    },
                    secondaryButton: .cancel(Text("Înapoi"))
                )
            }
        }
    }
    
    private func formatTimeOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ro_RO")
        return formatter.string(from: date)
    }
}

// MARK: - Plans Tab
struct PlansTabView: View {
    @ObservedObject var viewModel: FastingViewModel
    @State private var showingPlanActiveAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Alege un plan care se potrivește stilului tău de viață:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        
                    ForEach(FastingPlan.allCases) { plan in
                        PlanCard(
                            plan: plan,
                            isSelected: viewModel.currentPlan == plan,
                            isActiveFasting: viewModel.isFasting
                        ) {
                            if viewModel.isFasting {
                                showingPlanActiveAlert = true
                            } else {
                                viewModel.currentPlan = plan
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Planuri de Post")
            .alert(isPresented: $showingPlanActiveAlert) {
                Alert(
                    title: Text("Post Activ"),
                    message: Text("Trebuie să finalizați sau să anulați postul activ înainte de a schimba planul."),
                    dismissButton: .default(Text("Am înțeles"))
                )
            }
        }
    }
}

struct PlanCard: View {
    let plan: FastingPlan
    let isSelected: Bool
    let isActiveFasting: Bool
    let action: () -> Void
    
    var backgroundColor: Color {
        #if canImport(UIKit)
        return Color(UIColor.secondarySystemBackground)
        #elseif canImport(AppKit)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color.gray.opacity(0.15)
        #endif
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(plan.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if isSelected {
                            Text("Activ")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange)
                                .cornerRadius(8)
                        }
                    }
                    
                    Text(plan.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                            Text("\(plan.fastingHours) ore post")
                        }
                        .font(.caption)
                        .foregroundColor(.orange)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "fork.knife")
                            Text("\(plan.eatingHours) ore masă")
                        }
                        .font(.caption)
                        .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .orange : .gray)
                    .font(.title2)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
                    )
            )
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - History Tab
struct HistoryTabView: View {
    @ObservedObject var viewModel: FastingViewModel
    @State private var showingClearAlert = false
    
    var completedFastsCount: Int {
        viewModel.history.filter { $0.completedSuccessfully }.count
    }
    
    var successRate: Double {
        guard !viewModel.history.isEmpty else { return 0.0 }
        return Double(completedFastsCount) / Double(viewModel.history.count) * 100
    }
    
    @ViewBuilder
    private var emptyHistoryView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text("Nu ai încă posturi salvate")
                .font(.headline)
            Text("Pornește primul post pentru a începe să îți urmărești evoluția.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 40)
        .listRowBackground(Color.clear)
    }
    
    @ViewBuilder
    private var statsSection: some View {
        Section(header: Text("Statistici")) {
            HStack {
                Group {
                    Spacer()
                    StatView(title: "Total", value: "\(viewModel.history.count)")
                    Spacer()
                    Divider()
                    Spacer()
                    StatView(title: "Reușite", value: "\(completedFastsCount)")
                    Spacer()
                    Divider()
                    Spacer()
                }
                Group {
                    StatView(title: "Rată Succes", value: String(format: "%.0f%%", successRate))
                    Spacer()
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    @ViewBuilder
    private var historyListSection: some View {
        Section(header: Text("Posturi anterioare")) {
            ForEach(viewModel.history) { log in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(log.plan.title)
                            .font(.headline)
                        Text(log.formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(log.formattedDuration)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(log.completedSuccessfully ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(log.completedSuccessfully ? "Finalizat" : "Incomplet")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.history.isEmpty {
                    emptyHistoryView
                } else {
                    statsSection
                    historyListSection
                }
            }
            #if os(iOS)
            .listStyle(InsetGroupedListStyle())
            #else
            .listStyle(InsetListStyle())
            #endif
            .navigationTitle("Istoricul Tău")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if !viewModel.history.isEmpty {
                        Button("Șterge tot") {
                            showingClearAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .alert(isPresented: $showingClearAlert) {
                Alert(
                    title: Text("Ștergi tot istoricul?"),
                    message: Text("Această acțiune este permanentă și nu poate fi anulată."),
                    primaryButton: .destructive(Text("Șterge")) {
                        viewModel.history.removeAll()
                        UserDefaults.standard.removeObject(forKey: "fasting_history")
                    },
                    secondaryButton: .cancel(Text("Anulează"))
                )
            }
        }
    }
}

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.orange)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}
