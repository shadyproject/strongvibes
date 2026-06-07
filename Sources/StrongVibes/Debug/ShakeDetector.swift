#if DEBUG
import SwiftUI
import UIKit

// MARK: - UIKit Bridge

/// UIViewController subclass that intercepts motion events and broadcasts a notification.
final class ShakeDetectorController: UIViewController {

    override var canBecomeFirstResponder: Bool { true }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }
        NotificationCenter.default.post(name: .deviceDidShake, object: nil)
    }
}

private struct ShakeDetectorRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ShakeDetectorController { ShakeDetectorController() }
    func updateUIViewController(_ controller: ShakeDetectorController, context: Context) {}
}

// MARK: - SwiftUI Modifier

/// Attaches a zero-size shake detector and presents the dev menu on shake.
private struct DevMenuOnShakeModifier: ViewModifier {

    @State private var showingDevMenu = false

    func body(content: Content) -> some View {
        content
            .background(
                ShakeDetectorRepresentable().frame(width: 0, height: 0)
            )
            .onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in
                showingDevMenu = true
            }
            .sheet(isPresented: $showingDevMenu) {
                DevMenuView()
            }
    }
}

extension View {
    /// Presents the developer menu when the device is shaken. No-op in release builds.
    func devMenuOnShake() -> some View {
        modifier(DevMenuOnShakeModifier())
    }
}
#endif
