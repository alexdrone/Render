//
//  Album.swift
//  RenderTodoDemo
//
//  Created by Alex Usbergo on 03/05/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import Foundation

private let covers = [UIImage(data: NSData(contentsOfURL: NSURL(string: "http://www.spotifynewmusic.com/covers/13302.jpg")!)!),
              UIImage(data: NSData(contentsOfURL: NSURL(string: "http://www.spotifynewmusic.com/covers/13487.jpg")!)!),
              UIImage(data: NSData(contentsOfURL: NSURL(string: "http://www.spotifynewmusic.com/covers/13562.jpg")!)!),
              UIImage(data: NSData(contentsOfURL: NSURL(string: "http://www.spotifynewmusic.com/covers/13561.jpg")!)!),
              UIImage(data: NSData(contentsOfURL: NSURL(string: "http://www.spotifynewmusic.com/covers/13102.jpg")!)!) ]

private let titles = ["Aa",
              "EARS",
              "The Ship",
              "Waltzed in from the Rumbling",
              "Fever Dream",
              " Stelle Fisse" ]

private let artits = ["Baauer",
              "Kaitlyn Aurelia Smith",
              "Brian Eno",
              "Plants and Animals",
              "Ben Watt",
              "Aucan" ]

func ==(lhs: Album, rhs: Album) -> Bool {
    return lhs.id == rhs.id
}

class Album: Equatable {
    
    private let id = NSUUID().UUIDString
    let title: String
    let artist: String
    let cover: UIImage
    var featured: Bool
    
    init(featured: Bool = false) {
        let idx = randomInt(0, max: covers.count-1)
        self.title = titles[idx]
        self.artist = artits[idx]
        self.cover = covers[idx]!
        self.featured = featured
    }    
}
