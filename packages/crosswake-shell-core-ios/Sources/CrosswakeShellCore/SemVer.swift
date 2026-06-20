import Foundation

/// Minimal semver floor-comparison helper, ported from Elixir's
/// `compatible_version?/2` + `normalize_version/1` in
/// `lib/crosswake/compatibility/compatibility.ex`.
///
/// Provides the single public entry point `SemVer.compatible(provides:demands:)`
/// which returns `true` when `provides >= demands` (i.e. the shell satisfies the
/// requested floor), mirroring Elixir's `Version.compare != :lt` semantics.
///
/// Zero third-party dependencies — do NOT add swift-semver or any other package (D-04).
public enum SemVer {

    /// Returns `true` when `provides` satisfies the minimum floor of `demands`
    /// (i.e. `provides >= demands`).
    ///
    /// - Nil or empty input → `false` (fail-closed, deny).
    /// - Unparseable version string → falls back to raw `==` comparison (Elixir
    ///   fail-closed fallback: deny on mismatch, never allow or throw).
    public static func compatible(provides: String?, demands: String?) -> Bool {
        guard let p = provides, !p.isEmpty,
              let d = demands, !d.isEmpty else {
            return false
        }
        guard let pComponents = parse(normalize(p)),
              let dComponents = parse(normalize(d)) else {
            // Fail-closed fallback: raw equality (same as Elixir's `available == required`)
            return p == d
        }
        return compare(pComponents, dComponents) != .orderedAscending
    }

    // MARK: - Private helpers

    /// Zero-pads a version string to MAJOR.MINOR.PATCH.
    /// "1" → "1.0.0", "1.1" → "1.1.0", "1.0.0" → unchanged.
    private static func normalize(_ value: String) -> String {
        let parts = value.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        switch parts.count {
        case 1: return "\(parts[0]).0.0"
        case 2: return "\(parts[0]).\(parts[1]).0"
        default: return value
        }
    }

    /// Parses a "MAJOR.MINOR.PATCH" string into numeric components.
    /// Returns `nil` if any component is non-numeric.
    private static func parse(_ version: String) -> [Int]? {
        let parts = version.split(separator: ".").map(String.init)
        guard parts.count == 3 else { return nil }
        let ints = parts.compactMap { Int($0) }
        guard ints.count == 3 else { return nil }
        return ints
    }

    /// Compares two parsed [major, minor, patch] arrays.
    private static func compare(_ a: [Int], _ b: [Int]) -> ComparisonResult {
        for i in 0..<3 {
            if a[i] < b[i] { return .orderedAscending }
            if a[i] > b[i] { return .orderedDescending }
        }
        return .orderedSame
    }
}
