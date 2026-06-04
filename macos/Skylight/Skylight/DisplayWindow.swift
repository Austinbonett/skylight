import SwiftUI

/// The main projector display — borderless, always-on-top, black background.
struct DisplayWindow: View {
    @EnvironmentObject var server: ServerProcess

    private let displayURL = URL(string: "http://localhost:3000/")!

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if server.isReady {
                WebView(url: displayURL)
                    .ignoresSafeArea()
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                    Text("Starting Skylight…")
                        .foregroundStyle(.white.opacity(0.5))
                        .font(.system(.caption, design: .monospaced))
                }
            }
        }
        .background(Color.black)
    }
}
