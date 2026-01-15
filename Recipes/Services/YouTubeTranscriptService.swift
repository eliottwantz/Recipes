//
//  YouTubeTranscriptService.swift
//  Recipes
//
//  Created by Eliott on 2025-01-14.
//

import Dependencies
import Foundation
import os

nonisolated struct YouTubeTranscriptService: Sendable {

  // MARK: - Types

  nonisolated struct InnertubeRequest: Encodable, Sendable {
    let context: Context
    let videoId: String

    struct Context: Encodable, Sendable {
      let client: Client

      struct Client: Encodable, Sendable {
        let clientName: String
        let clientVersion: String
      }
    }
  }

  nonisolated struct InnertubeResponse: Decodable, Sendable {
    let captions: Captions?

    struct Captions: Decodable, Sendable {
      let playerCaptionsTracklistRenderer: PlayerCaptionsTracklistRenderer?

      struct PlayerCaptionsTracklistRenderer: Decodable, Sendable {
        let captionTracks: [CaptionTrack]?

        struct CaptionTrack: Decodable, Sendable {
          let baseUrl: String
          let languageCode: String
        }
      }
    }
  }

  // MARK: - Errors

  enum TranscriptError: Error, LocalizedError, Sendable {
    case invalidURL
    case notYouTubeURL
    case videoIDNotFound
    case networkError(String)
    case htmlFetchFailed
    case apiKeyNotFound
    case innertubeRequestFailed
    case captionsNotAvailable
    case captionsNotAvailableInLanguage(String)
    case transcriptFetchFailed
    case transcriptParsingFailed

    nonisolated var errorDescription: String? {
      switch self {
      case .invalidURL:
        return "Invalid URL provided."
      case .notYouTubeURL:
        return "URL is not a YouTube video."
      case .videoIDNotFound:
        return "Could not extract video ID from YouTube URL."
      case .networkError(let message):
        return "Network error: \(message)"
      case .htmlFetchFailed:
        return "Failed to fetch YouTube video page."
      case .apiKeyNotFound:
        return "Could not extract YouTube API key from page."
      case .innertubeRequestFailed:
        return "Failed to fetch video caption information."
      case .captionsNotAvailable:
        return "No captions available for this video."
      case .captionsNotAvailableInLanguage(let lang):
        return
          "Captions not available in '\(lang)'. Please check the video's available caption languages."
      case .transcriptFetchFailed:
        return "Failed to fetch transcript data."
      case .transcriptParsingFailed:
        return "Failed to parse transcript."
      }
    }
  }

  // MARK: - Constants

  private static let watchURLTemplate = "https://www.youtube.com/watch?v=%@"
  private static let innertubeAPIURLTemplate = "https://www.youtube.com/youtubei/v1/player?key=%@"
  private static let apiKeyPattern = #""INNERTUBE_API_KEY":\s*"([a-zA-Z0-9_-]+)""#

  // MARK: - Public Methods

  static func isYouTubeURL(_ url: URL) -> Bool {
    guard let host = url.host()?.lowercased() else { return false }
    return host.contains("youtube.com") || host == "youtu.be" || host == "www.youtu.be"
  }

  static func extractVideoID(from url: URL) -> String? {
    let host = url.host()?.lowercased() ?? ""
    let path = url.path()

    // youtu.be/VIDEO_ID
    if host == "youtu.be" || host == "www.youtu.be" {
      let videoID = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
      return videoID.isEmpty ? nil : videoID
    }

    // youtube.com/watch?v=VIDEO_ID
    if host.contains("youtube.com") {
      if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
        let videoID = components.queryItems?.first(where: { $0.name == "v" })?.value
      {
        return videoID
      }

      // youtube.com/shorts/VIDEO_ID or youtube.com/embed/VIDEO_ID
      let pathComponents = path.split(separator: "/")
      if pathComponents.count >= 2,
        pathComponents[0] == "shorts" || pathComponents[0] == "embed"
      {
        return String(pathComponents[1])
      }
    }

    return nil
  }

  @concurrent
  func fetchTranscript(videoID: String, language: String) async throws -> String {
    // Step 1: Fetch the YouTube watch page HTML
    let watchURL = String(format: Self.watchURLTemplate, videoID)
    guard let url = URL(string: watchURL) else {
      throw TranscriptError.invalidURL
    }

    @Dependency(\.urlSession) var session

    let (htmlData, htmlResponse): (Data, URLResponse)
    do {
      (htmlData, htmlResponse) = try await session.data(from: url)
    } catch {
      logger.error("Failed to fetch YouTube HTML: \(error.localizedDescription)")
      throw TranscriptError.networkError(error.localizedDescription)
    }

    guard let httpResponse = htmlResponse as? HTTPURLResponse,
      (200...299).contains(httpResponse.statusCode)
    else {
      throw TranscriptError.htmlFetchFailed
    }

    guard let html = String(data: htmlData, encoding: .utf8) else {
      throw TranscriptError.htmlFetchFailed
    }

    // Step 2: Extract Innertube API key from HTML
    guard let apiKey = extractAPIKey(from: html) else {
      logger.error("Could not find INNERTUBE_API_KEY in HTML")
      throw TranscriptError.apiKeyNotFound
    }

    logger.debug("Extracted YouTube API key: \(apiKey)")

    // Step 3: Call Innertube player API
    let innertubeURLString = String(format: Self.innertubeAPIURLTemplate, apiKey)
    guard let innertubeURL = URL(string: innertubeURLString) else {
      throw TranscriptError.invalidURL
    }

    var innertubeRequest = URLRequest(url: innertubeURL)
    innertubeRequest.httpMethod = "POST"
    innertubeRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let requestBody = InnertubeRequest(
      context: InnertubeRequest.Context(
        client: InnertubeRequest.Context.Client(
          clientName: "ANDROID",
          clientVersion: "20.10.38"
        )
      ),
      videoId: videoID
    )

    innertubeRequest.httpBody = try JSONEncoder().encode(requestBody)

    let (innertubeData, innertubeResponse): (Data, URLResponse)
    do {
      (innertubeData, innertubeResponse) = try await session.data(for: innertubeRequest)
    } catch {
      logger.error("Innertube request failed: \(error.localizedDescription)")
      throw TranscriptError.networkError(error.localizedDescription)
    }

    guard let innertubeHTTPResponse = innertubeResponse as? HTTPURLResponse,
      (200...299).contains(innertubeHTTPResponse.statusCode)
    else {
      throw TranscriptError.innertubeRequestFailed
    }

    // Step 4: Parse Innertube response to get caption tracks
    let innertubeResponseData: InnertubeResponse
    do {
      innertubeResponseData = try JSONDecoder().decode(InnertubeResponse.self, from: innertubeData)
    } catch {
      logger.error("Failed to decode Innertube response: \(error.localizedDescription)")
      throw TranscriptError.innertubeRequestFailed
    }

    guard
      let captionTracks = innertubeResponseData.captions?.playerCaptionsTracklistRenderer?
        .captionTracks,
      !captionTracks.isEmpty
    else {
      throw TranscriptError.captionsNotAvailable
    }

    // Step 5: Find caption track matching the requested language
    guard
      let captionTrack = captionTracks.first(where: { $0.languageCode == language })
    else {
      logger.error(
        "Captions not available in language '\(language)'. Available: \(captionTracks.map { $0.languageCode })"
      )
      throw TranscriptError.captionsNotAvailableInLanguage(language)
    }

    logger.debug("Found caption track for language '\(language)': \(captionTrack.baseUrl)")

    // Step 6: Fetch transcript XML
    guard let transcriptURL = URL(string: captionTrack.baseUrl) else {
      throw TranscriptError.invalidURL
    }

    let (transcriptData, transcriptResponse): (Data, URLResponse)
    do {
      (transcriptData, transcriptResponse) = try await session.data(from: transcriptURL)
    } catch {
      logger.error("Failed to fetch transcript: \(error.localizedDescription)")
      throw TranscriptError.networkError(error.localizedDescription)
    }

    guard let transcriptHTTPResponse = transcriptResponse as? HTTPURLResponse,
      (200...299).contains(transcriptHTTPResponse.statusCode)
    else {
      throw TranscriptError.transcriptFetchFailed
    }

    guard let transcriptXML = String(data: transcriptData, encoding: .utf8) else {
      throw TranscriptError.transcriptFetchFailed
    }

    // Step 7: Parse XML to extract text
    let transcript = try parseTranscriptXML(transcriptXML)

    logger.debug("Successfully fetched transcript (\(transcript.count) characters)")

    return transcript
  }

  // MARK: - Private Methods

  nonisolated private func extractAPIKey(from html: String) -> String? {
    guard let regex = try? NSRegularExpression(pattern: Self.apiKeyPattern, options: []) else {
      return nil
    }

    let nsString = html as NSString
    let range = NSRange(location: 0, length: nsString.length)

    guard let match = regex.firstMatch(in: html, options: [], range: range),
      match.numberOfRanges > 1
    else {
      return nil
    }

    let apiKeyRange = match.range(at: 1)
    return nsString.substring(with: apiKeyRange)
  }

  nonisolated private func parseTranscriptXML(_ xml: String) throws -> String {
    // YouTube returns timedtext format:
    // <timedtext><body><p t="50" d="3303">Text here</p>...</body></timedtext>

    let pattern = #"<p[^>]*>(.*?)</p>"#
    guard
      let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
    else {
      throw TranscriptError.transcriptParsingFailed
    }

    let nsString = xml as NSString
    let range = NSRange(location: 0, length: nsString.length)
    let matches = regex.matches(in: xml, options: [], range: range)

    var textSegments: [String] = []

    for match in matches {
      guard match.numberOfRanges > 1 else { continue }
      let textRange = match.range(at: 1)
      let text = nsString.substring(with: textRange)

      // Decode HTML entities
      let decodedText = decodeHTMLEntities(text)
      textSegments.append(decodedText)
    }

    guard !textSegments.isEmpty else {
      throw TranscriptError.transcriptParsingFailed
    }

    return textSegments.joined(separator: " ")
  }

  nonisolated private func decodeHTMLEntities(_ text: String) -> String {
    var result = text
    result = result.replacingOccurrences(of: "&amp;", with: "&")
    result = result.replacingOccurrences(of: "&lt;", with: "<")
    result = result.replacingOccurrences(of: "&gt;", with: ">")
    result = result.replacingOccurrences(of: "&quot;", with: "\"")
    result = result.replacingOccurrences(of: "&#39;", with: "'")
    result = result.replacingOccurrences(of: "&apos;", with: "'")
    return result
  }
}

nonisolated private let logger = Logger(
  subsystem: Constants.bundleID, category: "YouTubeTranscriptService"
)
