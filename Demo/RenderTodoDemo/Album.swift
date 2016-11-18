//
//  Album.swift
//  RenderTodoDemo
//
//  Created by Alex Usbergo on 03/05/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import Foundation

private let covers = [UIImage(named: "1")!, UIImage(named: "2")!, UIImage(named: "3")!, UIImage(named: "4")!]
private let titles = ["t e l e p a t h テレパシー能力者", "alexdrone", "oOoOO", "ÚLFUR"]
private let artits = ["私の夢の女性との時空間連続体の外側の内部の心の肉体ビジョン", "Stockholm", "Burnout Eyes", "hvað"]

func ==(lhs: Album, rhs: Album) -> Bool {
  return lhs.id == rhs.id
}

class Album: Equatable {

  let id = UUID().uuidString
  let title: String
  let artist: String
  let cover: UIImage
  var featured: Bool

  init(featured: Bool = false) {
    let idx = randomInt(0, max: covers.count-1)
    self.title = titles[idx]
    self.artist = artits[idx]
    self.cover = covers[idx]
    self.featured = randomInt(0, max:1) % 2 == 0
  }
}
