import Foundation
import SwiftUI

@MainActor
public final class AppState: ObservableObject {
    public static let shared = AppState()

    @Published public var currentSection: NavigationSection = .download

    private init() {}
}
