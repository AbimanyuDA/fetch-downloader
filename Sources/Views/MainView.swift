import SwiftUI

public enum NavigationSection: String, CaseIterable, Identifiable {
    case download = "Download"
    case queue = "Queue"
    case history = "History"
    case settings = "Settings"
    case logs = "Activity Log"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .download: return "arrow.down.circle"
        case .queue: return "tray.full"
        case .history: return "clock"
        case .settings: return "gearshape"
        case .logs: return "terminal"
        }
    }
}

public struct MainView: View {
    @State private var selectedSection: NavigationSection = .download
    @ObservedObject var queueManager = DownloadQueueManager.shared
    @ObservedObject var dependencyManager = DependencyManager.shared
    @State private var showOnboarding: Bool = false

    public init() {}

    public var body: some View {
        NavigationSplitView {
            List(selection: $selectedSection) {
                Section("MediaFetch") {
                    ForEach(NavigationSection.allCases) { section in
                        NavigationLink(value: section) {
                            HStack {
                                Label(section.rawValue, systemImage: section.iconName)
                                Spacer()
                                if section == .queue && queueManager.activeRunningCount > 0 {
                                    Text("\(queueManager.activeRunningCount)")
                                        .font(.system(size: 11, weight: .semibold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.accentColor)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 180, idealWidth: 200, maxWidth: 240)
        } detail: {
            Group {
                switch selectedSection {
                case .download:
                    DownloadView()
                case .queue:
                    QueueView()
                case .history:
                    HistoryView()
                case .settings:
                    SettingsView()
                case .logs:
                    LogView()
                }
            }
            .frame(minWidth: 700, idealWidth: 850, minHeight: 560, idealHeight: 680)
        }
        .onAppear {
            if !dependencyManager.isFullyReady {
                showOnboarding = true
            }
        }
        .sheet(isPresented: $showOnboarding) {
            DependencyOnboardingSheet()
        }
    }
}
