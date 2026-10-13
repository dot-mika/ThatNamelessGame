import Flutter
import UIKit

/// Flutter's game view controller.
///
/// iPad declares every orientation in Info.plist for App Store validation. The
/// game itself still requests its orientation through Flutter, while this lets
/// UIKit keep that interface orientation locked when the API is available.
class GameViewController: FlutterViewController {
  @available(iOS 16.0, *)
  override var prefersInterfaceOrientationLocked: Bool {
    // Do not lock the launch-time portrait interface before Flutter has had a
    // chance to request landscape. Once the game is landscape, keep it there.
    viewIfLoaded?.window?.windowScene?.interfaceOrientation.isLandscape ?? false
  }

  override func viewWillTransition(
    to size: CGSize,
    with coordinator: UIViewControllerTransitionCoordinator
  ) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: nil) { _ in
      if #available(iOS 16.0, *) {
        self.setNeedsUpdateOfSupportedInterfaceOrientations()
      }
    }
  }
}

class SceneDelegate: FlutterSceneDelegate {
}
