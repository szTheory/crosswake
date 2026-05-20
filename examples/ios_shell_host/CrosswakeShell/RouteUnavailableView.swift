import SwiftUI

struct RouteUnavailableView: View {
    let denial: RouteDenialPresentation
    let onAction: (RouteUnavailableAction) -> Void

    var body: some View {
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
        .background(Color(.systemGroupedBackground))
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
