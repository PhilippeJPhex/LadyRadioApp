import AVFoundation
import AVKit
import Flutter
import MediaPlayer
import UIKit

final class LadyVideoPlayerViewController: AVPlayerViewController {
  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return .allButUpsideDown
  }

  override var shouldAutorotate: Bool {
    return true
  }
}

final class NativeVideoPlayerPlugin: NSObject, FlutterPlugin, AVPlayerViewControllerDelegate {
  private static let channelName = "it.ladyradio/native_video_player"
  private var activePlayer: AVPlayer?
  private var activeController: LadyVideoPlayerViewController?

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger()
    )
    let instance = NativeVideoPlayerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "open" else {
      result(FlutterMethodNotImplemented)
      return
    }

    guard
      let args = call.arguments as? [String: Any],
      let urlString = args["url"] as? String,
      let url = URL(string: urlString)
    else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing video URL", details: nil))
      return
    }

    let title = args["title"] as? String ?? "Lady Radio Live"
    DispatchQueue.main.async {
      self.presentPlayer(url: url, title: title)
      result(true)
    }
  }

  private func presentPlayer(url: URL, title: String) {
    configureAudioSession()

    let item = AVPlayerItem(url: url)
    item.externalMetadata = makeMetadata(title: title)

    let player = AVPlayer(playerItem: item)
    let controller = LadyVideoPlayerViewController()
    controller.player = player
    controller.delegate = self
    controller.allowsPictureInPicturePlayback = true
    controller.canStartPictureInPictureAutomaticallyFromInline = true
    controller.updatesNowPlayingInfoCenter = true
    controller.entersFullScreenWhenPlaybackBegins = false
    controller.exitsFullScreenWhenPlaybackEnds = true
    controller.modalPresentationStyle = .fullScreen

    guard let presenter = topViewController() else {
      return
    }

    activePlayer = player
    activeController = controller

    presenter.present(controller, animated: true) {
      player.play()
    }
  }

  func playerViewController(
    _ playerViewController: AVPlayerViewController,
    restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
  ) {
    guard let controller = activeController else {
      completionHandler(false)
      return
    }

    if controller.view.window != nil || controller.presentingViewController != nil {
      completionHandler(true)
      return
    }

    guard let presenter = topViewController() else {
      completionHandler(false)
      return
    }

    presenter.present(controller, animated: true) {
      completionHandler(true)
    }
  }

  func playerViewControllerDidStopPictureInPicture(_ playerViewController: AVPlayerViewController) {
    if playerViewController.view.window == nil && playerViewController.presentingViewController == nil {
      activeController = nil
      activePlayer = nil
    }
  }

  private func configureAudioSession() {
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .moviePlayback)
      try session.setActive(true)
    } catch {
      print("[NativeVideoPlayer] AVAudioSession error: \(error)")
    }
  }

  private func makeMetadata(title: String) -> [AVMetadataItem] {
    var metadata: [AVMetadataItem] = [
      makeMetadataItem(identifier: .commonIdentifierTitle, value: title as NSString),
      makeMetadataItem(identifier: .commonIdentifierArtist, value: "Lady Radio" as NSString),
    ]

    if let image = UIImage(named: "LadyRadioCover"),
       let pngData = image.pngData() {
      metadata.append(makeMetadataItem(identifier: .commonIdentifierArtwork, value: pngData as NSData))
    }

    return metadata
  }

  private func makeMetadataItem(identifier: AVMetadataIdentifier, value: NSCopying & NSObjectProtocol) -> AVMetadataItem {
    let item = AVMutableMetadataItem()
    item.identifier = identifier
    item.value = value
    item.extendedLanguageTag = "und"
    return item.copy() as! AVMetadataItem
  }

  private func topViewController() -> UIViewController? {
    let window = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }

    var controller = window?.rootViewController
    while let presented = controller?.presentedViewController {
      controller = presented
    }
    return controller
  }
}
