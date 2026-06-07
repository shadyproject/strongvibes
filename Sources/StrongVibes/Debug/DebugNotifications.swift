import Foundation

// Notification names used by the debug developer menu.
// Defined at module level so all files can reference them;
// the actual senders and receivers are guarded by #if DEBUG.
extension Notification.Name {
    static let deviceDidShake = Notification.Name("net.shadyproject.strongvibes.deviceDidShake")
    static let devMenuDidChange = Notification.Name("net.shadyproject.strongvibes.devMenuDidChange")
}
