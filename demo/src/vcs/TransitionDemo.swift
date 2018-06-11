import UIKit
import RenderNeutrino

// MARK: - FromViewController

class TransitionFromDemoViewController: UIComponentViewController<TransitionFromComponent>,
  UIViewControllerTransitioningDelegate,
  UINavigationControllerDelegate {

  override func viewDidLoad() {
    styleNavigationBarComponent(title: "From")
    super.viewDidLoad()
  }

  override func buildRootComponent() -> TransitionFromComponent {
    let props = TransitionDemoProps()
    props.onTapAction = {
      let vc = TransitionToDemoViewController()
      vc.transitioningDelegate = self
      self.present(vc, animated: true, completion: nil)
    }
    return context.transientComponent(TransitionFromComponent.self, props: props)
  }

  func animationController(forPresented presented: UIViewController,
                           presenting: UIViewController,
                           source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    return Transition()
  }
}

// MARK: - ToViewController

class TransitionToDemoViewController: UIComponentViewController<TransitionToComponent> {
  override func viewDidLoad() {
    view.backgroundColor = S.palette.primary.color
    canvasView.backgroundColor = view.backgroundColor
    super.viewDidLoad()
  }

  override func buildRootComponent() -> TransitionToComponent {
    let props = TransitionDemoProps()
    props.onTapAction = {
      self.dismiss(animated: false, completion: nil)
    }
    return context.transientComponent(TransitionToComponent.self, props: props)
  }
}

// MARK: - Transition

class Transition: UISceneTransition {

  override func transitionDuration(context: UIViewControllerContextTransitioning?) -> TimeInterval {
    return 1
  }

  override func transition(context: UIViewControllerContextTransitioning?) {
    super.transition(context: context)
    setupAutoTransition(context: context)

    let targets = transitioningTargets(context: context)
    let navigationBar = fromNavigationBarSnapshot(context: context)
    let duration = transitionDuration(context: context)

    UIView.animate(withDuration: duration/2,
                   delay: 0,
                   usingSpringWithDamping: 0.5,
                   initialSpringVelocity: 0, options: [], animations: {
      navigationBar.frame.origin.y -= navigationBar.frame.size.height
      for target in targets {
        guard let from = target.0.view else { return }
        guard let to = target.1.view else { return }

        switch target.0.key {
        case "image":
          from.cornerRadius = 0
          from.frame = to.frame
        case "title":
          from.alpha = 0
        default:
          break
        }
      }
    }) { (_) in
      UIView.animate(withDuration: duration/2,
                     delay: 0,
                     usingSpringWithDamping: 0.9,
                     initialSpringVelocity: 0,
                     options: [],
                     animations: {

        for target in targets {
          guard let to = target.1.view else { return }
          switch target.0.key {
          case "title":
            to.alpha = 1
          default:
            break
          }
        }
      }, completion: { (_) in
        self.completeTransition(context: context)
      })
    }
  }
}
