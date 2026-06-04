import SwiftUI

/// The phone-style control panel in a floating window.
struct ControlWindow: View {
    @EnvironmentObject var server: ServerProcess

    private let controlURL = URL(string: "http://localhost:3000/control")!

    var body: some View {
        ZStack {
            if server.isReady {
                WebView(url: controlURL)
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(.circular)
                    Text("Starting…")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 360, minHeight: 640)
    }
}
