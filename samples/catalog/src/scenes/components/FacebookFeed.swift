import UIKit
import RenderNeutrino

struct Feed {

  class FeedState: UIState { }

  class FeedProps: UIProps {
    var posts: [Post.PostProps] = []
  }

  class FeedComponent: UIComponent<FeedState, FeedProps> {
    /// Builds the node hierarchy for this component.
    override func render(context: UIContextProtocol) -> UINodeProtocol {
      // Retrieve the table component with the given key.
      let table = childComponent(UIDefaultTableComponent.self, key: childKey("feed"))
      // Configure the table.
      table.props.configuration = { config in
        config.set(\UITableView.backgroundColor, Palette.white.color)
      }
      // Builds the section.
      let cells = props.posts.map { post in
        return table.cell(Post.PostComponent.self,
                          key: cellKey(for: post.id.hashValue),
                          props: post)
      }
      let section = UITableComponentProps.Section(cells: cells)
      table.props.sections = [section]
 
      // Returns the component node.
      return table.asNode()
    }

    // Helper function that returns the key for a cell at a given index.
    private func cellKey(for index: Int) -> String {
      return childKey("postcell-\(index)")
    }
  }
}
