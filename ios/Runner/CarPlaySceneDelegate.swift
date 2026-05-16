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

  private init() {
    configureSession()
    configureRemoteCommands()
  }

  func playLive() {
    CarPlayDataService.fetchLiveStreamURL { [weak self] url in
      let episode = CarPlayEpisode(
        title: "Lady Radio Live",
        program: "Lady Radio",
        audioURL: url,
        detail: "Diretta",
        artwork: "LadyRadioCover",
        isLiveStream: true
      )
      self?.play(episode)
    }
  }

  func play(_ episode: CarPlayEpisode) {
    currentEpisode = episode
    DispatchQueue.main.async {
      self.configureSession()
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

  static let programs: [CarPlayProgram] = [
    CarPlayProgram(title: "Radio Viola", category: "Sport", feedURL: URL(string: "https://www.spreaker.com/show/6929484/episodes/feed")!, artwork: "cover/radioviola.jpg"),
    CarPlayProgram(title: "GR del Mattino", category: "Cronaca", feedURL: URL(string: "https://www.spreaker.com/show/6927806/episodes/feed")!, artwork: "cover/grdelmattino.jpg"),
    CarPlayProgram(title: "Artemio", category: "Sport", feedURL: URL(string: "https://www.spreaker.com/show/6864279/episodes/feed")!, artwork: "cover/artemio.jpg"),
    CarPlayProgram(title: "Il quotidiano dei quartieri", category: "Cronaca", feedURL: URL(string: "https://www.spreaker.com/show/6927829/episodes/feed")!, artwork: "cover/quotidianodeiquartieri.jpg"),
    CarPlayProgram(title: "50100 - Le vie di Firenze", category: "Cronaca", feedURL: URL(string: "https://www.spreaker.com/show/6927797/episodes/feed")!, artwork: "https://d3wo5wojvuv7l.cloudfront.net/t_rss_itunes_square_1400/images.spreaker.com/original/df20a029014a2ab1c15bd673b09ce967.jpg"),
    CarPlayProgram(title: "Caffe Viola", category: "Sport", feedURL: URL(string: "https://www.spreaker.com/show/6927772/episodes/feed")!, artwork: "cover/caffeviola.jpg"),
    CarPlayProgram(title: "Le bombe delle sei", category: "Sport", feedURL: URL(string: "https://www.spreaker.com/show/6927819/episodes/feed")!, artwork: "cover/lebombedellesei.jpg"),
    CarPlayProgram(title: "Prima Pagina Viola", category: "Sport", feedURL: URL(string: "https://www.spreaker.com/show/6927825/episodes/feed")!, artwork: "cover/primapaginaviola.jpg")
  ]

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
        let detail = [formatDate(currentDate), currentDuration]
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
    let items = CarPlayDataService.programs.map { program in
      let item = CPListItem(text: program.title, detailText: program.category)
      item.accessoryType = .disclosureIndicator
      item.handler = { [weak self] _, completion in
        self?.showEpisodes(for: program)
        completion()
      }
      return item
    }

    let template = CPListTemplate(title: "Podcast", sections: [CPListSection(items: items)])
    template.tabTitle = "Podcast"
    template.tabSystemItem = .mostRecent
    return template
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
      let item = CPListItem(text: episode.title, detailText: episode.detail ?? episode.program)
      item.accessoryType = .disclosureIndicator
      item.handler = { [weak self] _, completion in
        CarPlayAudioController.shared.play(episode)
        self?.showNowPlaying()
        completion()
      }
      return item
    }
  }

  private func showNowPlaying() {
    interfaceController?.pushTemplate(CPNowPlayingTemplate.shared, animated: true) { _, error in
      if let error {
        print("[CarPlay] push now playing error: \(error)")
      }
    }
  }
}
