//
//  ViewController.swift
//  RenderDemo
//
//  Created by Alex Usbergo on 12/04/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import UIKit
import Render

class TestState: ComponentStateType {
    var condition = false
    var counter = 0
    var time = 0
}

class TestComponent: ComponentView {

    override func construct() -> ComponentType {
        
        let state = self.state as! TestState
        
        return Component<UIScrollView>().configure({
            $0.backgroundColor = UIColor.redColor()
            $0.style.alignItems = .Center
            $0.style.justifyContent = .Center
        })
        .children([
            Component<UIButton>().configure({
                $0.backgroundColor = UIColor.greenColor()
                $0.setTitle("GO", forState: .Normal)
                $0.titleLabel!.textColor = UIColor.whiteColor()
                $0.titleLabel!.textAlignment = .Center
                $0.titleLabel!.font = UIFont.systemFontOfSize(12, weight: UIFontWeightLight)
                $0.style.minDimensions = (Undefined, 54)
                $0.style.margin = (8.0, 8.0, 8.0, 8.0, 8.0, 8.0)
            }),
            
            Component<UILabel>().configure({
                $0.text = "Hello \(state.time)sec"
                $0.numberOfLines = 0
                $0.backgroundColor = UIColor.whiteColor()
                $0.style.margin = (8.0, 8.0, 8.0, 8.0, 8.0, 8.0)
            }),
            
            Component<UIView>().configure({
                $0.style.flexDirection = .Row
                $0.style.alignItems = .FlexStart
                $0.style.margin = (8.0, 8.0, 8.0, 8.0, 8.0, 8.0)
                $0.style.flexWrap = .Wrap
                $0.hidden = state.counter <= 0
                
            }).each(state.counter, closure: { (component, _) in
                component.addChild(Component<UIView>().configure({
                    $0.backgroundColor = UIColor.blueColor()
                    $0.layer.cornerRadius = 16
                    $0.style.minDimensions = (32, 32)
                    $0.style.margin = (8.0, 8.0, 8.0, 8.0, 8.0, 8.0)
                }))
            })
        ])
        
    }
}


class ViewController: UIViewController {
    
    let testComponent = TestComponent()
    var testState = TestState()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.testComponent.render(self.view.bounds.size, state: testState)
        self.testComponent.clipsToBounds = true
        
        self.view.addSubview(testComponent)
        self.change()
    }
    
    override func viewDidLayoutSubviews() {
        self.testComponent.render(self.view.bounds.size, state: testState)
    }

    func change() {
        self.testState.condition = !self.testState.condition
        self.testState.counter = (self.testState.counter + 1) % 60
        self.testState.time += 1
        UIView.animateWithDuration(0) {
            self.testComponent.render(self.view.bounds.size, state: self.testState)
        }
        
        //repeats
        delay(0.5) { self.change() }
    }
}

func delay(delay: Double, closure:()->()) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), closure)
}

