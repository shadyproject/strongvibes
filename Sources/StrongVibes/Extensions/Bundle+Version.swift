import Foundation

extension Bundle {

    /// The marketing version string set by the "Version from Git" build phase, e.g. "1.0.15".
    var shortVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    /// The build number (git commit count), e.g. "15".
    var buildNumber: String {
        object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }

    /// The short git hash recorded at build time, e.g. "2822f0c".
    var gitCommitHash: String {
        object(forInfoDictionaryKey: "GitCommitHash") as? String ?? "—"
    }

    /// A single display string combining version, build, and hash, e.g. "1.0.15 (15) 2822f0c".
    var fullVersionString: String {
        "\(shortVersion) (\(buildNumber)) \(gitCommitHash)"
    }
}
