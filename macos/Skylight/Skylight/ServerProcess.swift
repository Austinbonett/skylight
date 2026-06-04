import Foundation
import Combine

/// Manages the embedded Node.js server as a child process.
/// Launches on init, restarts on unexpected exit, and terminates on app quit.
@MainActor
final class ServerProcess: ObservableObject {
    @Published var isReady = false

    private var process: Process?
    private var readyCancellable: AnyCancellable?
    private let port = 3000

    init() {
        start()
        pollUntilReady()
    }

    private func start() {
        guard let nodePath = Bundle.main.path(forResource: "node", ofType: nil),
              let serverDir = Bundle.main.path(forResource: "server", ofType: nil)
        else {
            // Development fallback: use system node + repo server.
            startDev()
            return
        }
        let serverEntry = (serverDir as NSString).appendingPathComponent("dist/index.js")
        let webDist = Bundle.main.path(forResource: "web", ofType: nil) ?? ""

        let p = Process()
        p.executableURL = URL(fileURLWithPath: nodePath)
        p.arguments = [serverEntry]
        p.environment = [
            "PORT": "\(port)",
            "DATA_SOURCE": "api",
            "WEB_DIST": webDist,
            "PATH": "/usr/local/bin:/usr/bin:/bin",
        ]
        p.terminationHandler = { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.isReady = false
                try? await Task.sleep(for: .seconds(2))
                self?.start()
            }
        }
        try? p.run()
        process = p
    }

    /// Dev mode: repo must already be running `pnpm dev:server` separately,
    /// or we launch it here if the repo is next to the app.
    private func startDev() {
        // In development just wait for the server that `pnpm dev` started.
        print("[ServerProcess] dev mode — expecting server on :\(port)")
    }

    /// Poll /api/health every 250 ms until the server responds.
    private func pollUntilReady() {
        let url = URL(string: "http://localhost:\(port)/api/health")!
        readyCancellable = Timer.publish(every: 0.25, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                URLSession.shared.dataTask(with: url) { data, resp, _ in
                    guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { return }
                    Task { @MainActor [weak self] in
                        self?.isReady = true
                        self?.readyCancellable = nil
                    }
                }.resume()
            }
    }

    deinit {
        process?.terminate()
    }
}
