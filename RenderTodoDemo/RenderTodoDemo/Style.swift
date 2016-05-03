//
//  Style.swift
//  RenderTodoDemo
//
//  Created by Alex Usbergo on 25/04/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import UIKit
import Render

struct Style {
    
    struct Color {
        static let DarkPrimary = UIColor(hex6: 0x0097a7)
        static let Primary = UIColor(hex6: 0x00bcD4)
        static let LightPrimary = UIColor(hex6: 0xb2ebf2)
        static let Text = UIColor(hex6: 0xffffff)
        static let Accent = UIColor(hex6: 0xcddc39)
        static let PrimaryText = UIColor(hex6: 0x212121)
        static let SecondaryText = UIColor(hex6: 0x727272)
        static let Divider = UIColor(hex6: 0xb6b6b6)
    }
    
    struct Typography {
        static let SmallBold = UIFont.systemFontOfSize(14.0, weight: UIFontWeightBold)
        static let SmallRegular = UIFont.systemFontOfSize(14.0, weight: UIFontWeightRegular)
        static let MediumBold = UIFont.systemFontOfSize(24.0, weight: UIFontWeightBold)
        static let MediumSemibold = UIFont.systemFontOfSize(16.0, weight: UIFontWeightSemibold)
        static let MediumRegular = UIFont.systemFontOfSize(16.0, weight: UIFontWeightRegular)
    }
    
    struct Metrics {
        static let DefaultMargin: Inset = (8, 8, 8, 8, 8, 8)
    }
    
}