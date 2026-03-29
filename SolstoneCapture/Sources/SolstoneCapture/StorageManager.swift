// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (c) 2026 sol pbc

import Foundation

/// Manages file storage for capture segments
public final class StorageManager: Sendable {
    /// Base directory for all captures
    public let baseDirectory: URL

    /// Date formatter for directory names (YYYYMMDD)
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()

    /// Time formatter for segment directories (HHMMSS)
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HHmmss"
        return formatter
    }()

    public init() {
        // Use JOURNAL_PATH env var if set, otherwise ~/Documents/solstone-journal/
        if let journalPath = ProcessInfo.processInfo.environment["JOURNAL_PATH"] {
            self.baseDirectory = URL(fileURLWithPath: journalPath, isDirectory: true)
        } else {
            let home = FileManager.default.homeDirectoryForCurrentUser
            self.baseDirectory = home.appendingPathComponent("Documents/solstone-journal", isDirectory: true)
        }
    }

    /// Creates the base directory if it doesn't exist
    public func ensureBaseDirectoryExists() throws {
        try FileManager.default.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
    }

    /// Creates a new segment directory and returns its URL
    /// - Parameters:
    ///   - segmentStartTime: The time when this segment starts
    /// - Returns: URL to the segment directory (with .incomplete suffix) and time prefix (HHMMSS)
    public func createSegmentDirectory(segmentStartTime: Date) throws -> (url: URL, timePrefix: String) {
        // Create date directory: YYYY-MM-DD
        let dateString = Self.dateFormatter.string(from: segmentStartTime)
        let dateDir = baseDirectory.appendingPathComponent(dateString, isDirectory: true)

        // Create segment directory: HHMMSS.incomplete (duration added on completion)
        let timeString = Self.timeFormatter.string(from: segmentStartTime)
        let segmentDir = dateDir.appendingPathComponent("\(timeString).incomplete", isDirectory: true)

        try FileManager.default.createDirectory(at: segmentDir, withIntermediateDirectories: true)

        return (segmentDir, timeString)
    }

    /// Lists all segment directories for a given date
    public func listSegments(for date: Date) -> [URL] {
        let dateString = Self.dateFormatter.string(from: date)
        let dateDir = baseDirectory.appendingPathComponent(dateString, isDirectory: true)

        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: dateDir,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return contents.filter { url in
            var isDirectory: ObjCBool = false
            return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
        }.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
}
