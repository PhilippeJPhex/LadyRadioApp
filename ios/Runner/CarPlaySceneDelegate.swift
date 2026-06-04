import AVFoundation
import CarPlay
import Foundation
import MediaPlayer
import UIKit

private struct CarPlayProgram {
  let title: String
  let category: String
  let feedURL: URL
  let artwork: String?
  let isPodcast: Bool
  let podcastCategory: String
}

private struct CarPlayEpisode {
  let title: String
  let program: String
  let audioURL: URL
  let detail: String?
  let artwork: String?
  let isLiveStream: Bool
}

private final class CarPlayAudioController {
  static let shared = CarPlayAudioController()

  private var player: AVPlayer?
  private var currentEpisode: CarPlayEpisode?
  private var playbackRequestID = 0

  private init() {
    configureSession()
    configureRemoteCommands()
  }

  func playLive() {
    let requestID = beginPlaybackRequest()
    prepareForPlaybackRequest(requestID)
    CarPlayDataService.fetchLiveStreamURL { [weak self] url in
      let episode = CarPlayEpisode(
        title: "Lady Radio Live",
        program: "Lady Radio",
        audioURL: url,
        detail: "Diretta",
        artwork: "LadyRadioCarCover",
        isLiveStream: true
      )
      self?.play(episode, requestID: requestID)
    }
  }

  func play(_ episode: CarPlayEpisode) {
    let requestID = beginPlaybackRequest()
    prepareForPlaybackRequest(requestID)
    play(episode, requestID: requestID)
  }

  private func play(_ episode: CarPlayEpisode, requestID: Int) {
    DispatchQueue.main.async {
      guard requestID == self.playbackRequestID else { return }
      self.configureSession()
      self.currentEpisode = episode
      self.player = AVPlayer(url: episode.audioURL)
      self.player?.play()
      self.updateNowPlaying(isPlaying: true)
    }
  }

  func pause() {
    player?.pause()
    updateNowPlaying(isPlaying: false)
  }

  func resume() {
    player?.play()
    updateNowPlaying(isPlaying: true)
  }

  private func beginPlaybackRequest() -> Int {
    playbackRequestID += 1
    return playbackRequestID
  }

  private func prepareForPlaybackRequest(_ requestID: Int) {
    DispatchQueue.main.async {
      guard requestID == self.playbackRequestID else { return }
      self.stopCurrentPlayer()
      self.updateNowPlaying(isPlaying: false)
    }
  }

  private func stopCurrentPlayer() {
    player?.pause()
    player?.replaceCurrentItem(with: nil)
    player = nil
  }

  private func configureSession() {
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .default)
      try session.setActive(true)
    } catch {
      print("[CarPlay] AVAudioSession error: \(error)")
    }
  }

  private func configureRemoteCommands() {
    let commandCenter = MPRemoteCommandCenter.shared()
    commandCenter.playCommand.isEnabled = true
    commandCenter.pauseCommand.isEnabled = true
    commandCenter.togglePlayPauseCommand.isEnabled = true

    commandCenter.playCommand.addTarget { [weak self] _ in
      self?.resume()
      return .success
    }

    commandCenter.pauseCommand.addTarget { [weak self] _ in
      self?.pause()
      return .success
    }

    commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
      guard let self else { return .commandFailed }
      if self.player?.timeControlStatus == .playing {
        self.pause()
      } else {
        self.resume()
      }
      return .success
    }
  }

  private func updateNowPlaying(isPlaying: Bool) {
    guard let currentEpisode else { return }

    var nowPlayingInfo: [String: Any] = [
      MPMediaItemPropertyTitle: currentEpisode.title,
      MPMediaItemPropertyArtist: currentEpisode.program,
      MPNowPlayingInfoPropertyIsLiveStream: currentEpisode.isLiveStream,
      MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
    ]

    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo

    let episode = currentEpisode

    loadArtwork(for: episode) { [weak self] artwork in
      guard
        let self,
        let latestEpisode = self.currentEpisode,
        latestEpisode.audioURL == episode.audioURL,
        let artwork
      else {
        return
      }

      nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
      MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
  }

  private func loadArtwork(for episode: CarPlayEpisode, completion: @escaping (MPMediaItemArtwork?) -> Void) {
    guard let artworkSource = episode.artwork, !artworkSource.isEmpty else {
      completion(nil)
      return
    }

    if artworkSource.hasPrefix("http"), let url = URL(string: artworkSource) {
      URLSession.shared.dataTask(with: url) { data, _, _ in
        guard let data, let image = UIImage(data: data) else {
          completion(nil)
          return
        }

        completion(self.makeMediaArtwork(from: image))
      }.resume()
      return
    }

    guard let image = loadFlutterAssetImage(named: artworkSource) else {
      completion(nil)
      return
    }

    completion(makeMediaArtwork(from: image))
  }

  private func makeMediaArtwork(from image: UIImage) -> MPMediaItemArtwork {
    MPMediaItemArtwork(boundsSize: image.size) { _ in image }
  }

  private func loadFlutterAssetImage(named assetPath: String) -> UIImage? {
    if let image = UIImage(named: assetPath) {
      return image.withRenderingMode(.alwaysOriginal)
    }

    let candidates = [
      Bundle.main.bundleURL.appendingPathComponent("Frameworks/App.framework/flutter_assets/\(assetPath)").path,
      Bundle.main.bundleURL.appendingPathComponent(assetPath).path
    ]

    for path in candidates {
      if let image = UIImage(contentsOfFile: path) {
        return image
      }
    }

    return nil
  }
}

private final class CarPlayDataService {
  static let fallbackLiveURL = URL(string: "https://stream4.xdevel.com/audio0s978435-2634/stream/icecast.audio")!
  static let configURL = URL(string: "https://ladyradio.it/stream_conf/config.json")!
  static let scheduleURL = URL(string: "https://www.ladyradio.it/wp-json/ladyapp/v1/schedule")!

  static let programs: [CarPlayProgram] = [
    CarPlayProgram(title: "Radio Viola", category: "Sport", feedURL: URL(string: "https://www.spreaker.com/show/6929484/episodes/feed")!, artwork: "cover/radioviola.jpg", isPodcast: false, podcastCategory: ""),
    CarPlayProgram(title: "GR del Mattino", category: "Cronaca", feedURL: URL(string: "https://www.spreaker.com/show/6927806/episodes/feed")!, artwork: "cover/grdelmattino.jpg", isPodcast: false, podcastCategory: ""),
    CarPlayProgram(title: "Artemio", category: "Sport", feedURL: URL(string: "https://www.spreaker.com/show/6864279/episodes/feed")!, artwork: "cover/artemio.jpg", isPodcast: false, podcastCategory: ""),
    CarPlayProgram(title: "Il quotidiano dei quartieri", category: "Cronaca", feedURL: URL(string: "https://www.spreaker.com/show/6927829/episodes/feed")!, artwork: "cover/quotidianodeiquartieri.jpg", isPodcast: false, podcastCategory: ""),
    CarPlayProgram(title: "50100 - Le vie di Firenze", category: "Cronaca", feedURL: URL(string: "https://www.spreaker.com/show/6927797/episodes/feed")!, artwork: "https://d3wo5wojvuv7l.cloudfront.net/t_rss_itunes_square_1400/images.spreaker.com/original/df20a029014a2ab1c15bd673b09ce967.jpg", isPodcast: false, podcastCategory: ""),
    CarPlayProgram(title: "Caffe Viola", category: "Sport", feedURL: URL(string: "https://www.spreaker.com/show/6927772/episodes/feed")!, artwork: "cover/caffeviola.jpg", isPodcast: false, podcastCategory: ""),
    CarPlayProgram(title: "Le bombe delle sei", category: "Sport", feedURL: URL(string: "https://www.spreaker.com/show/6927819/episodes/feed")!, artwork: "cover/lebombedellesei.jpg", isPodcast: false, podcastCategory: ""),
    CarPlayProgram(title: "Prima Pagina Viola", category: "Sport", feedURL: URL(string: "https://www.spreaker.com/show/6927825/episodes/feed")!, artwork: "cover/primapaginaviola.jpg", isPodcast: false, podcastCategory: "")
  ]

  static func fetchPrograms(completion: @escaping ([CarPlayProgram]) -> Void) {
    var components = URLComponents(url: scheduleURL, resolvingAgainstBaseURL: false)
    components?.queryItems = [URLQueryItem(name: "_", value: "\(Int(Date().timeIntervalSince1970))")]
    var request = URLRequest(url: components?.url ?? scheduleURL)
    request.timeoutInterval = 10
    request.setValue("LadyRadioApp/1.0", forHTTPHeaderField: "User-Agent")
    request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

    URLSession.shared.dataTask(with: request) { data, _, _ in
      guard
        let data,
        let rawItems = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
      else {
        DispatchQueue.main.async { completion(programs) }
        return
      }

      var seen = Set<String>()
      let parsedPrograms: [CarPlayProgram] = rawItems.compactMap { item in
        let postId = stringValue(item["postId"]) ?? stringValue(item["id"]) ?? UUID().uuidString
        guard !seen.contains(postId) else { return nil }
        seen.insert(postId)

        guard
          let title = stringValue(item["title"]),
          let feed = stringValue(item["rssFeed"]),
          let feedURL = URL(string: feed),
          !title.isEmpty,
          !feed.isEmpty
        else {
          return nil
        }

        return CarPlayProgram(
          title: title,
          category: stringValue(item["category"]) ?? "",
          feedURL: feedURL,
          artwork: stringValue(item["imageUrl"]) ?? stringValue(item["image"]),
          isPodcast: boolValue(item["isPodcast"]) || boolValue(item["is_podcast"]),
          podcastCategory: stringValue(item["podcastCategory"]) ?? stringValue(item["podcast_category"]) ?? ""
        )
      }

      DispatchQueue.main.async { completion(parsedPrograms.isEmpty ? programs : parsedPrograms) }
    }.resume()
  }

  private static func stringValue(_ value: Any?) -> String? {
    guard let value else { return nil }
    if let string = value as? String {
      let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
      return trimmed.isEmpty ? nil : trimmed
    }
    if let number = value as? NSNumber {
      return number.stringValue
    }
    return nil
  }

  private static func boolValue(_ value: Any?) -> Bool {
    if let bool = value as? Bool { return bool }
    if let number = value as? NSNumber { return number.boolValue }
    guard let string = value as? String else { return false }
    return ["1", "true", "yes", "si", "sì"].contains(string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
  }

  static func fetchLiveStreamURL(completion: @escaping (URL) -> Void) {
    var request = URLRequest(url: configURL)
    request.timeoutInterval = 8

    URLSession.shared.dataTask(with: request) { data, _, _ in
      guard
        let data,
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let radio = json["radio"] as? [String: Any],
        let urlString = radio["url"] as? String,
        let url = URL(string: urlString)
      else {
        DispatchQueue.main.async { completion(fallbackLiveURL) }
        return
      }

      DispatchQueue.main.async { completion(url) }
    }.resume()
  }

  static func fetchEpisodes(for program: CarPlayProgram, completion: @escaping ([CarPlayEpisode]) -> Void) {
    var request = URLRequest(url: program.feedURL)
    request.timeoutInterval = 12
    request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")

    URLSession.shared.dataTask(with: request) { data, _, _ in
      guard let data else {
        DispatchQueue.main.async { completion([]) }
        return
      }

      let parser = CarPlayRSSParser(programTitle: program.title, fallbackArtwork: program.artwork, data: data)
      DispatchQueue.main.async { completion(parser.parse()) }
    }.resume()
  }

  static func loadFavorites() -> [CarPlayEpisode] {
    let defaults = UserDefaults.standard
    let jsonString = defaults.string(forKey: "flutter.favorite_episodes")
      ?? defaults.string(forKey: "favorite_episodes")

    guard
      let jsonString,
      let data = jsonString.data(using: .utf8),
      let rawItems = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
    else {
      return []
    }

    return rawItems.compactMap { item in
      guard
        let audio = item["audioUrl"] as? String,
        let audioURL = URL(string: audio)
      else {
        return nil
      }

      return CarPlayEpisode(
        title: item["title"] as? String ?? "Puntata",
        program: item["program"] as? String ?? item["album"] as? String ?? "Lady Radio",
        audioURL: audioURL,
        detail: item["date"] as? String ?? item["duration"] as? String,
        artwork: item["image"] as? String,
        isLiveStream: false
      )
    }
  }
}

private final class CarPlayRSSParser: NSObject, XMLParserDelegate {
  private let programTitle: String
  private let fallbackArtwork: String?
  private let parser: XMLParser
  private var episodes: [CarPlayEpisode] = []

  private var isInsideItem = false
  private var currentElement = ""
  private var currentTitle = ""
  private var currentDate = ""
  private var currentDuration = ""
  private var currentAudioURL = ""
  private var currentImageURL = ""

  init(programTitle: String, fallbackArtwork: String?, data: Data) {
    self.programTitle = programTitle
    self.fallbackArtwork = fallbackArtwork
    self.parser = XMLParser(data: data)
    super.init()
    parser.delegate = self
  }

  func parse() -> [CarPlayEpisode] {
    parser.parse()
    return episodes
  }

  func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
    currentElement = elementName.lowercased()

    if currentElement == "item" {
      isInsideItem = true
      currentTitle = ""
      currentDate = ""
      currentDuration = ""
      currentAudioURL = ""
      currentImageURL = ""
    }

    if isInsideItem, currentElement == "enclosure", currentAudioURL.isEmpty {
      currentAudioURL = attributeDict["url"] ?? ""
    }

    if isInsideItem, currentElement == "itunes:image", currentImageURL.isEmpty {
      currentImageURL = attributeDict["href"] ?? ""
    }
  }

  func parser(_ parser: XMLParser, foundCharacters string: String) {
    guard isInsideItem else { return }
    let value = string.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty else { return }

    switch currentElement {
    case "title":
      currentTitle += value
    case "pubdate":
      currentDate += value
    case "duration":
      currentDuration += value
    default:
      break
    }
  }

  func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
    if elementName.lowercased() == "item" {
      if let url = URL(string: currentAudioURL), !currentTitle.isEmpty {
        let detail = [formatDate(currentDate), normalizedDuration(currentDuration)]
          .compactMap { $0?.isEmpty == false ? $0 : nil }
          .joined(separator: " - ")

        episodes.append(
          CarPlayEpisode(
            title: currentTitle,
            program: programTitle,
            audioURL: url,
            detail: detail.isEmpty ? nil : detail,
            artwork: currentImageURL.isEmpty ? fallbackArtwork : currentImageURL,
            isLiveStream: false
          )
        )
      }

      isInsideItem = false
    }

    currentElement = ""
  }

  private func formatDate(_ rawValue: String) -> String? {
    guard !rawValue.isEmpty else { return nil }

    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"

    guard let date = formatter.date(from: rawValue) else {
      return rawValue
    }

    let output = DateFormatter()
    output.locale = Locale(identifier: "it_IT")
    output.dateStyle = .medium
    output.timeStyle = .none
    return output.string(from: date)
  }

  private func normalizedDuration(_ rawValue: String) -> String? {
    let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty, value != "0", value != "1" else { return nil }

    if value.contains(":") {
      return value
    }

    guard let seconds = Int(value), seconds > 59 else {
      return nil
    }

    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    let remainingSeconds = seconds % 60

    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
    }

    return String(format: "%d:%02d", minutes, remainingSeconds)
  }
}

@available(iOS 14.0, *)
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
  private var interfaceController: CPInterfaceController?
  private var tabBarTemplate: CPTabBarTemplate?
  private var liveTemplate: CPListTemplate?
  private var podcastTemplate: CPListTemplate?
  private var favoritesTemplate: CPListTemplate?

  func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene,
    didConnect interfaceController: CPInterfaceController
  ) {
    self.interfaceController = interfaceController

    let live = makeLiveTemplate()
    let podcasts = makePodcastsTemplate()
    let favorites = makeFavoritesTemplate()
    let tabs = CPTabBarTemplate(templates: [live, podcasts, favorites])

    liveTemplate = live
    podcastTemplate = podcasts
    favoritesTemplate = favorites
    tabBarTemplate = tabs

    interfaceController.setRootTemplate(tabs, animated: true) { _, error in
      if let error {
        print("[CarPlay] setRootTemplate error: \(error)")
      }
    }
  }

  func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene,
    didDisconnect interfaceController: CPInterfaceController
  ) {
    self.interfaceController = nil
    self.tabBarTemplate = nil
  }

  private func makeLiveTemplate() -> CPListTemplate {
    let item = CPListItem(text: "Ascolta la diretta", detailText: "Lady Radio Live")
    item.accessoryType = .disclosureIndicator
    item.handler = { [weak self] _, completion in
      CarPlayAudioController.shared.playLive()
      self?.showNowPlaying()
      completion()
    }

    let template = CPListTemplate(title: "Live", sections: [CPListSection(items: [item])])
    template.tabTitle = "Live"
    template.tabSystemItem = .featured
    return template
  }

  private func makePodcastsTemplate() -> CPListTemplate {
    let loading = CPListItem(text: "Caricamento...", detailText: nil)
    let template = CPListTemplate(title: "Podcast", sections: [CPListSection(items: [loading])])
    template.tabTitle = "Podcast"
    template.tabSystemItem = .mostRecent

    CarPlayDataService.fetchPrograms { [weak self, weak template] programs in
      guard let self, let template else { return }
      template.updateSections([CPListSection(items: self.makePodcastRootItems(programs))])
    }

    return template
  }

  private func makePodcastRootItems(_ programs: [CarPlayProgram]) -> [CPListItem] {
    let replayPrograms = programs.filter { !$0.isPodcast }
    let podcastPrograms = programs.filter { $0.isPodcast }

    let replayItem = CPListItem(text: "Riascolta le trasmissioni", detailText: "Tutte le trasmissioni di Lady Radio")
    replayItem.accessoryType = .disclosureIndicator
    replayItem.handler = { [weak self] _, completion in
      self?.showPrograms(title: "Riascolta le trasmissioni", programs: replayPrograms)
      completion()
    }

    var items = [replayItem]

    if !podcastPrograms.isEmpty {
      let podcastItem = CPListItem(text: "Ascolta i nostri podcast", detailText: "Podcast e categorie")
      podcastItem.accessoryType = .disclosureIndicator
      podcastItem.handler = { [weak self] _, completion in
        self?.showPodcastPrograms(podcastPrograms)
        completion()
      }
      items.append(podcastItem)
    }

    return items
  }

  private func showPrograms(title: String, programs: [CarPlayProgram]) {
    let items = programs.map { program in
      let item = CPListItem(text: program.title, detailText: carPlayDetailText(program.category))
      item.accessoryType = .disclosureIndicator
      item.handler = { [weak self] _, completion in
        self?.showEpisodes(for: program)
        completion()
      }
      return item
    }

    let template = CPListTemplate(title: title, sections: [CPListSection(items: items)])
    template.emptyViewTitleVariants = ["Nessuna trasmissione"]
    interfaceController?.pushTemplate(template, animated: true) { _, error in
      if let error {
        print("[CarPlay] push programs error: \(error)")
      }
    }
  }

  private func showPodcastPrograms(_ programs: [CarPlayProgram]) {
    let hasCategories = programs.contains { !$0.podcastCategory.isEmpty }
    guard hasCategories else {
      showPrograms(title: "Ascolta i nostri podcast", programs: programs)
      return
    }

    var grouped: [String: [CarPlayProgram]] = [:]
    for program in programs {
      let category = program.podcastCategory.isEmpty ? "Altri podcast" : program.podcastCategory
      grouped[category, default: []].append(program)
    }

    let items = grouped.keys.sorted().map { category in
      let categoryPrograms = grouped[category] ?? []
      let item = CPListItem(text: category, detailText: nil)
      item.accessoryType = .disclosureIndicator
      item.handler = { [weak self] _, completion in
        self?.showPrograms(title: category, programs: categoryPrograms)
        completion()
      }
      return item
    }

    let template = CPListTemplate(title: "Ascolta i nostri podcast", sections: [CPListSection(items: items)])
    template.emptyViewTitleVariants = ["Nessun podcast"]
    interfaceController?.pushTemplate(template, animated: true) { _, error in
      if let error {
        print("[CarPlay] push podcast categories error: \(error)")
      }
    }
  }

  private func makeFavoritesTemplate() -> CPListTemplate {
    let favorites = CarPlayDataService.loadFavorites()
    let template = CPListTemplate(title: "Preferiti", sections: [CPListSection(items: makeEpisodeItems(favorites))])
    template.tabTitle = "Preferiti"
    template.tabSystemItem = .favorites
    template.emptyViewTitleVariants = ["Nessun preferito"]
    template.emptyViewSubtitleVariants = ["Aggiungi preferiti dall'app Lady Radio su iPhone."]
    return template
  }

  private func showEpisodes(for program: CarPlayProgram) {
    let loading = CPListItem(text: "Caricamento puntate...", detailText: nil)

    let episodesTemplate = CPListTemplate(title: program.title, sections: [CPListSection(items: [loading])])
    episodesTemplate.emptyViewTitleVariants = ["Nessuna puntata"]
    interfaceController?.pushTemplate(episodesTemplate, animated: true) { _, error in
      if let error {
        print("[CarPlay] push episodes error: \(error)")
      }
    }

    CarPlayDataService.fetchEpisodes(for: program) { episodes in
      let items = self.makeEpisodeItems(episodes)
      episodesTemplate.emptyViewSubtitleVariants = ["Controlla la connessione e riprova."]
      episodesTemplate.updateSections([CPListSection(items: items)])
    }
  }

  private func makeEpisodeItems(_ episodes: [CarPlayEpisode]) -> [CPListItem] {
    episodes.prefix(Int(CPListTemplate.maximumItemCount)).map { episode in
      let item = CPListItem(text: episode.title, detailText: carPlayDetailText(episode.detail) ?? episode.program)
      item.accessoryType = .disclosureIndicator
      item.handler = { [weak self] _, completion in
        CarPlayAudioController.shared.play(episode)
        self?.showNowPlaying()
        completion()
      }
      return item
    }
  }

  private func carPlayDetailText(_ rawValue: String?) -> String? {
    guard let rawValue else { return nil }
    let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty, Int(value) == nil else { return nil }
    return value
  }

  private func showNowPlaying() {
    interfaceController?.pushTemplate(CPNowPlayingTemplate.shared, animated: true) { _, error in
      if let error {
        print("[CarPlay] push now playing error: \(error)")
      }
    }
  }
}
