import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct RouteUnavailableView: View {
    public let denial: RouteDenialPresentation
    public let onAction: (RouteUnavailableAction) -> Void

    public init(denial: RouteDenialPresentation, onAction: @escaping (RouteUnavailableAction) -> Void) {
        self.denial = denial
        self.onAction = onAction
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(denial.title)
                .font(.largeTitle.weight(.semibold))

            Text(denial.message)
                .font(.body)

            if let hint = denial.hint {
                Text(hint)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            if let routeID = denial.routeID {
                Text("Route: \(routeID)")
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(denial.actions.enumerated()), id: \.offset) { _, action in
                    Button(actionTitle(action)) {
                        onAction(action)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        #if canImport(UIKit)
        .background(Color(UIColor.systemGroupedBackground))
        #else
        .background(Color.gray.opacity(0.1))
        #endif
    }

    private func actionTitle(_ action: RouteUnavailableAction) -> String {
        switch action {
        case .retry:
            return "Retry"
        case .updateApp:
            return "Update app"
        case .safeFallback:
            return "Open safe fallback"
        }
    }
}
