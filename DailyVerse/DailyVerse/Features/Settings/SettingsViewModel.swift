import SwiftUI
import Combine
// TODO: Implement in Sprint 5
@MainActor
class SettingsViewModel: ObservableObject {
    @Published var isLoading: Bool = false
}
