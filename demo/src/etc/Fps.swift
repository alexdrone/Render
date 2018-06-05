//
//  Forked from konoma/fps-counter
//  fps-counter
//
// The MIT License (MIT)
//
// Copyright (c) 2016 konoma GmbH
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import UIKit
import QuartzCore

/// A class that tracks the current FPS of the running application.
/// `FPSCounter` uses `CADisplayLink` updates to count the frames per second drawn.
/// Set the delegate of this class to get notified in certain intervals of the
/// current FPS.
/// If you just want to see the FPS in the application you can use the
/// `FPSCounter.showInStatusBar(_:)` convenience method.
///
public class FPSCounter: NSObject {
  /// Helper class that relays display link updates to the FPSCounter
  /// This is necessary because CADisplayLink retains its target. Thus
  /// if the FPSCounter class would be the target of the display link
  /// it would create a retain cycle. The delegate has a weak reference
  /// to its parent FPSCounter, thus preventing this.
  internal class DisplayLinkDelegate: NSObject {
    /// A weak ref to the parent FPSCounter instance.
    weak var parentCounter: FPSCounter?
    /// Notify the parent FPSCounter of a CADisplayLink update.
    @objc func updateFromDisplayLink(_ displayLink: CADisplayLink) {
      self.parentCounter?.updateFromDisplayLink(displayLink)
    }
  }

  private let displayLink: CADisplayLink
  private let displayLinkDelegate: DisplayLinkDelegate

  /// Create a new FPSCounter.
  /// To start receiving FPS updates you need to start tracking with the
  /// `startTracking(inRunLoop:mode:)` method.
  public override init() {
    self.displayLinkDelegate = DisplayLinkDelegate()
    self.displayLink = CADisplayLink(
      target: self.displayLinkDelegate,
      selector: #selector(DisplayLinkDelegate.updateFromDisplayLink(_:))
    )
    super.init()
    self.displayLinkDelegate.parentCounter = self
  }

  deinit {
    self.displayLink.invalidate()
  }

  /// The delegate that should receive FPS updates.
  public weak var delegate: FPSCounterDelegate?
  /// Delay between FPS updates. Longer delays mean more averaged FPS numbers.
  public var notificationDelay: TimeInterval = 1.0
  private var runloop: RunLoop?
  private var mode: RunLoopMode?

  /// Start tracking FPS updates.
  /// You can specify wich runloop to use for tracking, as well as the runloop modes.
  /// Usually you'll want the main runloop (default), and either the common run loop modes
  /// (default), or the tracking mode (`UITrackingRunLoopMode`).
  /// When the counter is already tracking, it's stopped first.
  public func startTracking(inRunLoop runloop: RunLoop = RunLoop.main,
                            mode: RunLoopMode = RunLoopMode.commonModes) {
    stopTracking()
    self.runloop = runloop
    self.mode = mode
    displayLink.add(to: runloop, forMode: mode)
  }

  /// Stop tracking FPS updates.
  /// This method does nothing if the counter is not currently tracking.
  public func stopTracking() {
    guard let runloop = self.runloop, let mode = self.mode else { return }
    displayLink.remove(from: runloop, forMode: mode)
    self.runloop = nil
    self.mode = nil
  }

  private var lastNotificationTime: CFAbsoluteTime = 0.0
  private var numberOfFrames: Int = 0

  private func updateFromDisplayLink(_ displayLink: CADisplayLink) {
    if lastNotificationTime == 0.0 {
      lastNotificationTime = CFAbsoluteTimeGetCurrent()
      return
    }

    numberOfFrames += 1
    let currentTime = CFAbsoluteTimeGetCurrent()
    let elapsedTime = currentTime - self.lastNotificationTime
    if elapsedTime >= self.notificationDelay {
      notifyUpdateForElapsedTime(elapsedTime)
      lastNotificationTime = 0.0
      numberOfFrames = 0
    }
  }

  private func notifyUpdateForElapsedTime(_ elapsedTime: CFAbsoluteTime) {
    let fps = Int(round(Double(self.numberOfFrames) / elapsedTime))
    delegate?.fpsCounter(self, didUpdateFramesPerSecond: fps)
  }
}

/// The delegate protocol for the FPSCounter class.
/// Implement this protocol if you want to receive updates from a `FPSCounter`.
public protocol FPSCounterDelegate: NSObjectProtocol {
  /// Called in regular intervals while the counter is tracking FPS.
  func fpsCounter(_ counter: FPSCounter, didUpdateFramesPerSecond fps: Int)
}

/// A view controller to show a FPS label in the status bar.
internal class FPSStatusBarViewController: UIViewController, FPSCounterDelegate {
  fileprivate let fpsCounter = FPSCounter()
  private let label: UILabel = UILabel()

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    self.commonInit()
  }

  required init?(coder decoder: NSCoder) {
    super.init(coder: decoder)
    self.commonInit()
  }

  private func commonInit() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(FPSStatusBarViewController.updateStatusBarFrame(_:)),
      name: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation,
      object: nil)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  override func loadView() {
    view = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 100.0, height: 100.0))
    label.frame = self.view.bounds.insetBy(dx: 32.0, dy: 0.0)
    label.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
    label.font = UIFont.boldSystemFont(ofSize: 10.0)
    label.textColor = .white
    view.addSubview(self.label)
    fpsCounter.delegate = self
  }

  @objc func updateStatusBarFrame(_ notification: Notification) {
    let application = notification.object as? UIApplication
    let frame = CGRect(x: 0.0,
                       y: 0.0,
                       width: application?.keyWindow?.bounds.width ?? 0.0,
                       height: 20.0)
    FPSStatusBarViewController.statusBarWindow.frame = frame
  }

  func fpsCounter(_ counter: FPSCounter, didUpdateFramesPerSecond fps: Int) {
    _ = 1000 / max(fps, 1)
    label.text = "\(fps) FPS"

    if fps >= 45 {
      view.backgroundColor = UIColor(red:0.55, green:0.76, blue:0.33, alpha:1.00)
    } else if fps >= 30 {
      view.backgroundColor = UIColor(red:0.99, green:0.60, blue:0.17, alpha:1.00)
    } else {
      view.backgroundColor = UIColor(red:0.99, green:0.35, blue:0.20, alpha:1.00)
    }
  }

  static var statusBarWindow: UIWindow = {
    let window = UIWindow()
    window.windowLevel = UIWindowLevelStatusBar
    window.rootViewController = FPSStatusBarViewController()
    return window
  }()
}

public extension FPSCounter {

  public class func showInStatusBar(_ application: UIApplication,
                                    runloop: RunLoop? = nil,
                                    mode: RunLoopMode? = nil) {
    let window = FPSStatusBarViewController.statusBarWindow
    window.frame = application.statusBarFrame
    window.isHidden = false

    if let controller = window.rootViewController as? FPSStatusBarViewController {
      controller.fpsCounter.startTracking(
        inRunLoop: runloop ?? RunLoop.main,
        mode: mode ?? RunLoopMode.commonModes
      )
    }
  }
}
