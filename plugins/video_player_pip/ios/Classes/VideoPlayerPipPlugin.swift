import Flutter
import UIKit
import AVFoundation
import AVKit
import MediaPlayer

public class VideoPlayerPipPlugin: NSObject, FlutterPlugin, AVPictureInPictureControllerDelegate {
  private var channel: FlutterMethodChannel?
  private var pipController: AVPictureInPictureController?
  private weak var currentPlayer: AVPlayer?
  private var currentMetadata: [String: String] = [:]
  private var isInPipMode = false
  private var userPausedWhileInPip = false
  private var observationToken: NSKeyValueObservation?
  private var playerStatusObservationToken: NSKeyValueObservation?
  private var playerRateObservationToken: NSKeyValueObservation?
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "video_player_pip", binaryMessenger: registrar.messenger())
    let instance = VideoPlayerPipPlugin(channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
    NSLog("VideoPlayerPip: Plugin registered")
  }
  
  init(channel: FlutterMethodChannel) {
    self.channel = channel
    super.init()
    NSLog("VideoPlayerPip: Plugin initialized")
  }

  private func nowPlayingMetadata(from args: [String: Any]) -> [String: String] {
    return [
      "title": args["title"] as? String ?? "Lady Radio Live",
      "artist": args["artist"] as? String ?? "Lady Radio",
      "artwork": args["artwork"] as? String ?? "LadyRadioCover"
    ]
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    NSLog("VideoPlayerPip: Received method call: \(call.method)")
    switch call.method {
    case "isPipSupported":
      let supported = isPipSupported()
      NSLog("VideoPlayerPip: isPipSupported = \(supported)")
      result(supported)
      
    case "enterPipMode":
      guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int else {
        NSLog("VideoPlayerPip: enterPipMode failed - Invalid arguments")
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing playerId", details: nil))
        return
      }
      
      NSLog("VideoPlayerPip: Attempting to enter PiP mode for playerId: \(playerId)")
      enterPipMode(playerId: playerId, metadata: nowPlayingMetadata(from: args), completion: result)

    case "preparePipMode":
      guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int else {
        NSLog("VideoPlayerPip: preparePipMode failed - Invalid arguments")
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing playerId", details: nil))
        return
      }

      NSLog("VideoPlayerPip: Attempting to prepare PiP mode for playerId: \(playerId)")
      preparePipMode(playerId: playerId, metadata: nowPlayingMetadata(from: args), completion: result)
      
    case "exitPipMode":
      NSLog("VideoPlayerPip: Attempting to exit PiP mode, current isInPipMode = \(isInPipMode), pipController exists: \(pipController != nil)")
      exitPipMode(completion: result)
      
    case "isInPipMode":
      NSLog("VideoPlayerPip: isInPipMode query = \(isInPipMode)")
      result(isInPipMode)
      
    default:
      NSLog("VideoPlayerPip: Method not implemented: \(call.method)")
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func isPipSupported() -> Bool {
    if #available(iOS 14.0, *) {
      let supported = AVPictureInPictureController.isPictureInPictureSupported()
      NSLog("VideoPlayerPip: PiP supported by system: \(supported)")
      return supported
    }
    NSLog("VideoPlayerPip: PiP not supported (iOS < 14.0)")
    return false
  }

  private func updateNowPlayingInfo(metadata: [String: String], isPlaying: Bool) {
    var nowPlayingInfo: [String: Any] = [
      MPMediaItemPropertyTitle: metadata["title"] ?? "Lady Radio Live",
      MPMediaItemPropertyArtist: metadata["artist"] ?? "Lady Radio",
      MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
      MPNowPlayingInfoPropertyIsLiveStream: true
    ]

    if let image = loadArtworkImage(named: metadata["artwork"] ?? "LadyRadioCover") {
      nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in
        image
      }
    }

    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
  }

  private func loadArtworkImage(named assetPath: String) -> UIImage? {
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

  private func updateNowPlayingPlaybackRate(_ rate: Double) {
    var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = rate
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
  }

  private func clearNowPlayingInfo() {
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
  }

  private func isCurrentPlayerPlaying() -> Bool {
    guard let player = currentPlayer else { return false }
    return player.timeControlStatus == .playing
  }

  private func handlePlayerPlaybackChanged(isPlaying: Bool) {
    NSLog("VideoPlayerPip: Player playback changed. isPlaying=\(isPlaying), isInPipMode=\(isInPipMode), userPausedWhileInPip=\(userPausedWhileInPip), appState=\(UIApplication.shared.applicationState.rawValue)")

    if isInPipMode && !isPlaying {
      userPausedWhileInPip = true
      clearNowPlayingInfo()
      if #available(iOS 14.2, *) {
        pipController?.canStartPictureInPictureAutomaticallyFromInline = false
      }
      return
    }

    if isInPipMode && isPlaying {
      userPausedWhileInPip = false
      updateNowPlayingInfo(metadata: currentMetadata, isPlaying: true)
      return
    }

    updateNowPlayingPlaybackRate(isPlaying ? 1.0 : 0.0)
  }

  private func observePlayerPlaybackState(_ player: AVPlayer) {
    playerStatusObservationToken?.invalidate()
    playerRateObservationToken?.invalidate()
    playerStatusObservationToken = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
      self?.handlePlayerPlaybackChanged(isPlaying: player.timeControlStatus == .playing)
    }
    playerRateObservationToken = player.observe(\.rate, options: [.new]) { [weak self] player, _ in
      self?.handlePlayerPlaybackChanged(isPlaying: player.rate > 0 && player.timeControlStatus == .playing)
    }
  }
  
  private func enterPipMode(playerId: Int, metadata: [String: String], completion: @escaping FlutterResult) {
    NSLog("VideoPlayerPip: enterPipMode called for playerId: \(playerId)")
    configurePipMode(playerId: playerId, shouldStartImmediately: true, metadata: metadata, completion: completion)
  }

  private func preparePipMode(playerId: Int, metadata: [String: String], completion: @escaping FlutterResult) {
    NSLog("VideoPlayerPip: preparePipMode called for playerId: \(playerId)")
    configurePipMode(playerId: playerId, shouldStartImmediately: false, metadata: metadata, completion: completion)
  }

  private func configurePipMode(playerId: Int, shouldStartImmediately: Bool, metadata: [String: String], completion: @escaping FlutterResult) {
    if !isPipSupported() {
      NSLog("VideoPlayerPip: PiP not supported by the device")
      completion(false)
      return
    }
    
    // Find the AVPlayerLayer
    NSLog("VideoPlayerPip: Searching for AVPlayerLayer for playerId: \(playerId)")
    guard let playerLayer = findAVPlayerLayer(playerId: playerId) else {
      NSLog("VideoPlayerPip: Could not find player layer for ID: \(playerId)")
      completion(false)
      return
    }
    
    NSLog("VideoPlayerPip: Found AVPlayerLayer: \(playerLayer)")
    
    // Check if player is ready
    if let player = playerLayer.player {
      currentPlayer = player
      currentMetadata = metadata
      observePlayerPlaybackState(player)
      updateNowPlayingInfo(metadata: metadata, isPlaying: player.timeControlStatus == .playing)
      NSLog("VideoPlayerPip: Player status: \(player.status.rawValue), currentItem: \(player.currentItem != nil ? "exists" : "nil"), error: \(player.error?.localizedDescription ?? "none")")
      
      // Wait a moment to ensure player is properly prepared
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
        self?.continueConfigurePipMode(
          playerLayer: playerLayer,
          shouldStartImmediately: shouldStartImmediately,
          completion: completion
        )
      }
    } else {
      NSLog("VideoPlayerPip: AVPlayerLayer has no player set")
      completion(false)
    }
  }
  
  private func continueConfigurePipMode(
    playerLayer: AVPlayerLayer,
    shouldStartImmediately: Bool,
    completion: @escaping FlutterResult
  ) {
    // Create and configure the PiP controller
    if #available(iOS 14.0, *) {
      NSLog("VideoPlayerPip: Creating AVPictureInPictureController with playerLayer")
      
      // Check if we can create a PiP controller with this layer
      if AVPictureInPictureController.isPictureInPictureSupported() && playerLayer.player != nil {
        // Clean up any existing controller and observations
        cleanupPipController()

        currentPlayer = playerLayer.player
        if let player = currentPlayer {
          observePlayerPlaybackState(player)
        }
        
        pipController = AVPictureInPictureController(playerLayer: playerLayer)
        pipController?.delegate = self
        userPausedWhileInPip = false
        
        // Enable PiP to start from inline (foreground)
        if #available(iOS 14.2, *) {
          NSLog("VideoPlayerPip: Setting canStartPictureInPictureAutomaticallyFromInline to true")
          pipController?.canStartPictureInPictureAutomaticallyFromInline = true
        }
        
        // Allow PiP during interactive playback
        if #available(iOS 15.0, *) {
          NSLog("VideoPlayerPip: Setting requiresLinearPlayback to false")
          pipController?.requiresLinearPlayback = false
        }
        
        NSLog("VideoPlayerPip: PiP controller created successfully: \(String(describing: pipController))")
        
        // Set up observation for the possible PiP state
        if #available(iOS 14.0, *) {
          observationToken = pipController?.observe(\.isPictureInPictureActive, options: [.new]) { [weak self] (controller, change) in
            guard let self = self, let newValue = change.newValue else { return }
            NSLog("VideoPlayerPip: isPictureInPictureActive changed to \(newValue)")
            self.isInPipMode = newValue
            self.channel?.invokeMethod("pipModeChanged", arguments: ["isInPipMode": newValue])
          }
        }
        
        if !shouldStartImmediately {
          NSLog("VideoPlayerPip: PiP prepared for automatic inline start")
          completion(true)
          return
        }

        // Start PiP - Try to start it more forcefully
        NSLog("VideoPlayerPip: Attempting to start PiP")
        
        if #available(iOS 15.0, *) {
          // On iOS 15+, we can try a slightly more direct approach
          pipController?.startPictureInPicture()
          
          // Also try after a short delay as a fallback
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self, !(self.pipController?.isPictureInPictureActive ?? false) else { return }
            NSLog("VideoPlayerPip: Trying to start PiP again after delay (iOS 15+)")
            self.pipController?.startPictureInPicture()
          }
          
        } else {
          // On iOS 14, just use the regular API
          pipController?.startPictureInPicture()
        }
        
        completion(true)
      } else {
        NSLog("VideoPlayerPip: Cannot create PiP controller - either not supported or player is nil")
        completion(false)
      }
    } else {
      NSLog("VideoPlayerPip: iOS version < 14.0, cannot create PiP controller")
      completion(false)
    }
  }
  
  private func cleanupPipController() {
    observationToken?.invalidate()
    observationToken = nil
    playerStatusObservationToken?.invalidate()
    playerStatusObservationToken = nil
    playerRateObservationToken?.invalidate()
    playerRateObservationToken = nil
    
    if isInPipMode && pipController != nil {
      pipController?.stopPictureInPicture()
    }
    
    pipController = nil
    currentPlayer = nil
    currentMetadata = [:]
  }
  
  private func exitPipMode(completion: @escaping FlutterResult) {
    NSLog("VideoPlayerPip: exitPipMode called, isInPipMode: \(isInPipMode), pipController: \(String(describing: pipController))")
    if isInPipMode, pipController != nil {
      NSLog("VideoPlayerPip: Stopping picture-in-picture")
      pipController?.stopPictureInPicture()
      completion(true)
    } else {
      NSLog("VideoPlayerPip: Cannot stop PiP - either not in PiP mode or controller is nil")
      completion(false)
    }
  }
  
  /**
   * Find the AVPlayerLayer for the specified player ID.
   * This searches through the view hierarchy to find the platform view created by video_player.
   */
  private func findAVPlayerLayer(playerId: Int) -> AVPlayerLayer? {
    NSLog("VideoPlayerPip: Finding AVPlayerLayer for playerId: \(playerId)")
    // Use a more modern approach to get the active window
    let keyWindow = getKeyWindow()
    NSLog("VideoPlayerPip: keyWindow found: \(keyWindow != nil)")
    if let rootViewController = keyWindow?.rootViewController {
      NSLog("VideoPlayerPip: Starting search from rootViewController: \(type(of: rootViewController))")
      // Start with the root view and search recursively
      return findAVPlayerLayerInView(rootViewController.view, depth: 0)
    }
    NSLog("VideoPlayerPip: No rootViewController found")
    return nil
  }
  
  /**
   * Get the key window using a more modern approach that works on iOS 13+
   */
  private func getKeyWindow() -> UIWindow? {
    if #available(iOS 13.0, *) {
      let scenes = UIApplication.shared.connectedScenes
        .filter {
          $0.activationState == .foregroundActive ||
          $0.activationState == .foregroundInactive
        }
        .compactMap { $0 as? UIWindowScene }
      
      NSLog("VideoPlayerPip: Found \(scenes.count) active window scenes")
      
      if let windowScene = scenes.first {
        let windows = windowScene.windows.filter { $0.isKeyWindow }
        NSLog("VideoPlayerPip: Found \(windows.count) key windows in the first scene")
        return windows.first
      }
      return nil
    } else {
      let window = UIApplication.shared.keyWindow
      NSLog("VideoPlayerPip: Using legacy keyWindow approach: \(window != nil)")
      return window
    }
  }
  
  /**
   * Recursively search for an AVPlayerLayer in the view hierarchy.
   */
  private func findAVPlayerLayerInView(_ view: UIView, depth: Int) -> AVPlayerLayer? {
    let indentation = String(repeating: "  ", count: depth)
    let className = NSStringFromClass(type(of: view))
    NSLog("\(indentation)VideoPlayerPip: Checking view: \(className)")
    
    // Check if this view's layer is an AVPlayerLayer
    if let playerLayer = view.layer as? AVPlayerLayer {
      NSLog("\(indentation)VideoPlayerPip: Found AVPlayerLayer directly as view's layer")
      // Check if the player is set
      if let player = playerLayer.player {
        NSLog("\(indentation)VideoPlayerPip: AVPlayerLayer has player: \(player)")
        return playerLayer
      } else {
        NSLog("\(indentation)VideoPlayerPip: AVPlayerLayer has no player set")
      }
    }
    
    // Check for class name matching FVPPlayerView which has an AVPlayerLayer as its layer
    if className.contains("FVPPlayerView") {
      NSLog("\(indentation)VideoPlayerPip: Found FVPPlayerView")
      if let playerLayer = view.layer as? AVPlayerLayer {
        NSLog("\(indentation)VideoPlayerPip: FVPPlayerView's layer is AVPlayerLayer")
        if let player = playerLayer.player {
          NSLog("\(indentation)VideoPlayerPip: FVPPlayerView's AVPlayerLayer has player: \(player)")
        } else {
          NSLog("\(indentation)VideoPlayerPip: FVPPlayerView's AVPlayerLayer has no player set")
        }
        return playerLayer
      } else {
        NSLog("\(indentation)VideoPlayerPip: FVPPlayerView's layer is not AVPlayerLayer: \(type(of: view.layer))")
      }
    }
    
    // Check sublayers directly in case AVPlayerLayer is a sublayer
    if let sublayers = view.layer.sublayers {
      NSLog("\(indentation)VideoPlayerPip: Checking \(sublayers.count) sublayers")
      for sublayer in sublayers {
        if let playerLayer = sublayer as? AVPlayerLayer {
          NSLog("\(indentation)VideoPlayerPip: Found AVPlayerLayer as a sublayer")
          if let player = playerLayer.player {
            NSLog("\(indentation)VideoPlayerPip: Sublayer AVPlayerLayer has player: \(player)")
            return playerLayer
          } else {
            NSLog("\(indentation)VideoPlayerPip: Sublayer AVPlayerLayer has no player set")
          }
        }
      }
    }
    
    // Recursively check subviews
    NSLog("\(indentation)VideoPlayerPip: Checking \(view.subviews.count) subviews")
    for subview in view.subviews {
      if let layer = findAVPlayerLayerInView(subview, depth: depth + 1) {
        return layer
      }
    }
    
    return nil
  }
  
  // MARK: - AVPictureInPictureControllerDelegate
  
  public func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    NSLog("VideoPlayerPip: PiP started successfully")
    updateNowPlayingPlaybackRate(isCurrentPlayerPlaying() ? 1.0 : 0.0)
    isInPipMode = true
    channel?.invokeMethod("pipModeChanged", arguments: ["isInPipMode": true])
  }
  
  public func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    NSLog("VideoPlayerPip: PiP stopped")
    userPausedWhileInPip = false
    updateNowPlayingPlaybackRate(0.0)
    isInPipMode = false
    channel?.invokeMethod("pipModeChanged", arguments: ["isInPipMode": false])
    // Explicitly release the controller when PiP is stopped
    if #available(iOS 14.0, *) {
        if self.pipController == pictureInPictureController {
            NSLog("VideoPlayerPip: Releasing pipController reference")
            self.pipController = nil
        } else {
            NSLog("VideoPlayerPip: Stopped PiP controller doesn't match current pipController")
        }
    } else {
        if self.pipController === pictureInPictureController {
            NSLog("VideoPlayerPip: Releasing pipController reference (using identity check)")
            self.pipController = nil
        } else {
            NSLog("VideoPlayerPip: Stopped PiP controller doesn't match current pipController (using identity check)")
        }
    }
  }
  
  public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
    NSLog("VideoPlayerPip: Failed to start PiP: \(error.localizedDescription)")
    NSLog("VideoPlayerPip: Error details: \(error)")
    channel?.invokeMethod("pipError", arguments: ["error": error.localizedDescription])
  }
  
  public func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    NSLog("VideoPlayerPip: PiP will start")
    updateNowPlayingPlaybackRate(isCurrentPlayerPlaying() ? 1.0 : 0.0)
  }
  
  public func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    NSLog("VideoPlayerPip: PiP will stop")
  }
  
  deinit {
    NSLog("VideoPlayerPip: Plugin being deallocated")
    cleanupPipController()
  }
}
