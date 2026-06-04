import Foundation
import Combine
import ServiceManagement

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

    // MARK: - Launch

    private func start() {
        // Production: use bundled node binary + server.cjs from app bundle Resources.
        if let nodePath = Bundle.main.path(forResource: "node", ofType: nil),
           let serverPath = Bundle.main.path(forResource: "server", ofType: "cjs") {
            launch(nodePath: nodePath, serverPath: serverPath, bundled: true)
            return
        }
        // Development fallback: use system node + repo source via tsx.
        startDev()
    }

    private func launch(nodePath: String, serverPath: String, bundled: Bool) {
        let webDist = Bundle.main.path(forResource: "web", ofType: nil) ?? ""
        let dataDir: String
        if bundled {
            // Store data next to the app in ~/Library/Application Support/Skylight
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let dir = appSupport.appendingPathComponent("Skylight/data")
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            dataDir = dir.path
        } else {
            dataDir = (serverPath as NSString).deletingLastPathComponent + "/data"
        }

        let p = Process()
        p.executableURL = URL(fileURLWithPath: nodePath)
        p.arguments = [serverPath]
        p.environment = [
            "PORT": "\(port)",
            "DATA_SOURCE": "api",
            "WEB_DIST": webDist,
            "DATA_DIR": dataDir,
            "PATH": "/usr/local/bin:/usr/bin:/bin",
        ]
        p.terminationHandler = { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isReady = false
                try? await Task.sleep(for: .seconds(2))
                self.start()
                self.pollUntilReady()
            }
        }
        do {
            try p.run()
            process = p
        } catch {
            print("[ServerProcess] failed to launch: \(error)")
        }
    }

    private func startDev() {
        // In dev just wait for `pnpm dev:server` that the developer started.
        print("[ServerProcess] dev mode — expecting server on :\(port)")
    }

    // MARK: - Readiness polling

    private func pollUntilReady() {
        readyCancellable?.cancel()
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

    // MARK: - Launch at login

    static func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("[ServerProcess] launch-at-login error: \(error)")
        }
    }

    static var launchAtLoginEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    deinit {
        process?.terminate()
    }
}
