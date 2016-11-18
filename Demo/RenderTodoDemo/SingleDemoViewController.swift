//
//  SingleViewController.swift
//  RenderTodoDemo
//
//  Created by Alex Usbergo on 14/05/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import Foundation
import Render

class SingleDemoViewController: UIViewController {

  // The item list.
  var album = Album(featured: true)

  /// The collection view component.
  lazy var component: ListComponentView = {
    let component = ListComponentView()
    component.state = self.newRandomState()
    return component
  }()

  func newRandomState() -> ListComponentState {
    var albums: [Album] = []
    for _ in 0..<randomInt(2, max: 16) {
      albums.append(Album())
    }
    return ListComponentState(albums: albums)
  }


  /// Called after the controller's view is loaded into memory.
  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.addSubview(self.component)
    self.toggleFeatured()
  }

  /// Called to notify the view controller that its view has just laid out its subviews.
  override func viewDidLayoutSubviews() {
    self.render()
  }

  func render(_ animated: Bool = false) {
    func layout() {
      self.component.renderComponent(withSize: self.view.bounds.size)
      self.component.center = self.view.center
    }
    if animated {
      UIView.animate(withDuration: 0.3, animations: {
       layout()
      })
    } else {
      layout()
    }
  }

  /// Change the component state every 2 seconds.
  func toggleFeatured() {
    delay(10) {
      self.component.state = self.newRandomState()
      self.render(true)
      self.toggleFeatured()
    }
  }
}


func delay(_ delay:Double, closure:@escaping ()->()) {
  DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() +
    Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}
