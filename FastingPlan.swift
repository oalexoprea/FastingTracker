import Foundation

enum FastingPlan: String, CaseIterable, Identifiable, Codable {
    case classic16 = "16:8"
    case advanced18 = "18:6"
    case warrior20 = "20:4"
    case circadian12 = "12:12"
    
    var id: String { self.rawValue }
    
    var fastingHours: Int {
        switch self {
        case .classic16: return 16
        case .advanced18: return 18
        case .warrior20: return 20
        case .circadian12: return 12
        }
    }
    
    var eatingHours: Int {
        return 24 - fastingHours
    }
    
    var title: String {
        switch self {
        case .classic16: return "Clasic (16:8)"
        case .advanced18: return "Avansat (18:6)"
        case .warrior20: return "Războinic (20:4)"
        case .circadian12: return "Ritmic (12:12)"
        }
    }
    
    var description: String {
        switch self {
        case .classic16: return "Cel mai popular plan. Ideal pentru începători și sustenabilitate pe termen lung."
        case .advanced18: return "Pentru cei care doresc un stimulent suplimentar pentru arderea grăsimilor și autofagie."
        case .warrior20: return "O singură masă principală pe zi. Pentru practicanți experimentați."
        case .circadian12: return "Aliniat cu ritmul circadian natural al corpului. Excelent pentru acomodare."
        }
    }
}
