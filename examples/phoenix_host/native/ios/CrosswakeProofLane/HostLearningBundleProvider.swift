import AVFoundation
import CryptoKit
import Foundation

/// The physical host's single private authority for its complete foreground learning bundle.
/// Crosswake receives only a requirement-bound installed record; asset locations and digests stay
/// inside this host adapter.
actor HostLearningBundleProvider: PackProvider {
  typealias Source = @Sendable (String) -> Data?
  static let requirement = PackRequirement(
    packID: "reference-learning-bundle",
    requiredVersion: "v1",
    expectedByteCount: 35_003,
    expectedSHA256: "27cdcb23c04aacd628490bccf0b609e438ecbc75c68ca135fb4932fdc531c68e"
  )

  private struct Asset {
    let filename: String
    let byteCount: Int
    let sha256: String
  }

  private let assets = [
    Asset(filename: "manifest.json", byteCount: 373, sha256: "64e9fa6e3e31e9d05b8ecad369750d654952fb15b4f5ac00cce4eee3867e21ca"),
    Asset(filename: "card-image.png", byteCount: 924, sha256: "47b23c6102091d68642e1f0eb00414f1bb0d9780fe596685685173a6d77d0260"),
    Asset(filename: "pronunciation.aiff", byteCount: 33_706, sha256: "5d8b3f72beb26205032d764bc7979f5658c7c9f262427bce2d814f2bf0fabf5b")
  ]

  private let storageRoot: URL
  private let fileManager: FileManager
  private let sourceBundle: Bundle
  private let source: Source?

  init(
    storageRoot: URL? = nil,
    sourceBundle: Bundle = .main,
    fileManager: FileManager = .default,
    source: Source? = nil
  ) {
    self.storageRoot = storageRoot ?? ((try? fileManager.url(
      for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
    ))?.appendingPathComponent("CrosswakeReferenceLearning", isDirectory: true) ?? URL(fileURLWithPath: "/dev/null"))
    self.sourceBundle = sourceBundle
    self.fileManager = fileManager
    self.source = source
  }

  func status(for requirement: PackRequirement) async -> PackProviderResult {
    guard accepts(requirement) else { return .failure(.versionMismatch) }
    let root = installedRoot()
    guard fileManager.fileExists(atPath: root.path) else { return .notInstalled }
    return await validatedRecord(at: root, requirement: requirement)
  }

  func install(_ requirement: PackRequirement) async -> PackProviderResult {
    guard accepts(requirement) else { return .failure(.versionMismatch) }
    let destination = installedRoot()
    let parent = destination.deletingLastPathComponent()
    let staging = parent.appendingPathComponent(".staging-\(UUID().uuidString)", isDirectory: true)
    let retained = parent.appendingPathComponent(".previous-\(UUID().uuidString)", isDirectory: true)

    do {
      try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
      try fileManager.createDirectory(at: staging, withIntermediateDirectories: false)
      defer { try? fileManager.removeItem(at: staging) }

      for asset in assets {
        guard let bytes = sourceBytes(for: asset), matches(bytes, asset) else {
          return .failure(.digestMismatch)
        }
        try bytes.write(to: staging.appendingPathComponent(asset.filename), options: .atomic)
      }

      guard case .installed = await validatedRecord(at: staging, requirement: requirement) else {
        return .failure(.atomicInstallFailed)
      }

      let hadPrevious = fileManager.fileExists(atPath: destination.path)
      if hadPrevious { try fileManager.moveItem(at: destination, to: retained) }
      do {
        try fileManager.moveItem(at: staging, to: destination)
        guard case .installed(let record) = await validatedRecord(at: destination, requirement: requirement) else {
          throw CocoaError(.fileReadCorruptFile)
        }
        if fileManager.fileExists(atPath: retained.path) { try fileManager.removeItem(at: retained) }
        return .installed(record)
      } catch {
        if fileManager.fileExists(atPath: destination.path) { try? fileManager.removeItem(at: destination) }
        if hadPrevious, fileManager.fileExists(atPath: retained.path) { try? fileManager.moveItem(at: retained, to: destination) }
        return .failure(.atomicInstallFailed)
      }
    } catch {
      return .failure(.atomicInstallFailed)
    }
  }

  func invalidate(_ requirement: PackRequirement) async -> PackProviderResult {
    guard accepts(requirement) else { return .failure(.versionMismatch) }
    let destination = installedRoot()
    guard fileManager.fileExists(atPath: destination.path) else { return .notInstalled }
    do {
      try fileManager.removeItem(at: destination)
      return .notInstalled
    } catch {
      return .failure(.invalidationFailed)
    }
  }

  func installedAssetURL(named filename: String, requirement: PackRequirement) async -> URL? {
    guard case .installed = await status(for: requirement), assets.contains(where: { $0.filename == filename }) else {
      return nil
    }
    return installedRoot().appendingPathComponent(filename)
  }

  static func resetForTests(fileManager: FileManager = .default) {
    guard let support = try? fileManager.url(
      for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false
    ) else { return }
    try? fileManager.removeItem(at: support.appendingPathComponent("CrosswakeReferenceLearning", isDirectory: true))
  }

  private func accepts(_ requirement: PackRequirement) -> Bool {
    requirement == Self.requirement
  }

  private func installedRoot() -> URL { storageRoot.appendingPathComponent("learning-bundle", isDirectory: true) }

  private func sourceURL(for asset: Asset) -> URL? {
    let components = asset.filename.split(separator: ".", maxSplits: 1).map(String.init)
    guard components.count == 2 else { return nil }
    return ([sourceBundle] + Bundle.allBundles)
      .compactMap { $0.url(forResource: components[0], withExtension: components[1]) }
      .first
  }

  private func sourceBytes(for asset: Asset) -> Data? {
    if let source { return source(asset.filename) }
    guard let url = sourceURL(for: asset) else { return nil }
    return try? Data(contentsOf: url)
  }

  private func validatedRecord(at root: URL, requirement: PackRequirement) async -> PackProviderResult {
    for asset in assets {
      let url = root.appendingPathComponent(asset.filename)
      guard let bytes = try? await readBytes(from: url), matches(bytes, asset) else { return .failure(.digestMismatch) }
    }
    return .installed(PackInstalledRecord(
      contractVersion: requirement.contractVersion,
      packID: requirement.packID,
      installedVersion: requirement.requiredVersion,
      byteCount: requirement.expectedByteCount,
      integrityVerified: true,
      atomicPromotionCompleted: true
    ))
  }

  private func matches(_ bytes: Data, _ asset: Asset) -> Bool {
    bytes.count == asset.byteCount && SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined() == asset.sha256
  }

  private func readBytes(from url: URL) async throws -> Data {
    try await Task.detached(priority: .utility) { try Data(contentsOf: url) }.value
  }
}
