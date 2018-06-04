import UIKit
import RenderNeutrino

class CustomNavigationBarViewController: UITableComponentViewController {
  /// The model props to pass down to the component.
  lazy var tracks: [Track.TrackProps] = {
   return Array(0...100).map { _ in return Track.TrackProps() }
  }()

  /// Tells the data source to return the number of rows in a given section of a table view.
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return tracks.count
  }

  override func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let component = context.component(Track.TrackComponent.self,
                                      key: tracks[indexPath.row].id,
                                      props: tracks[indexPath.row],
                                      parent: nil)
    return dequeueCell(forComponent: component)
  }

  /// Called after the controller's view is loaded into memory.
  override func viewDidLoad() {
    // Instantiate the custom navigation bar component.
    navigationBarManager.component = context.component(Track.NavigationBar.self)
    // User info is a special dictionary-like object used to passed additional custom properties
    // to the navigation bar subclass.
    navigationBarManager.props.userInfo = Track.NavigationBar.UserInfo()
    super.viewDidLoad()
  }
}


