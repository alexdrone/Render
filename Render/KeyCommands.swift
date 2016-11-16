//
//  KeyCommands.swift
//  Render
//
//  Created by Alex Usbergo on 30/03/16.
//
//  Copyright (c) 2016 Alex Usbergo.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//  forked from: Augustyniak/KeyCommands / Created by Rafal Augustyniak

import UIKit

#if (arch(i386) || arch(x86_64)) && (os(iOS))
  struct KeyActionableCommand {
    fileprivate let keyCommand: UIKeyCommand
    fileprivate let actionBlock: () -> ()

    func matches(_ input: String, modifierFlags: UIKeyModifierFlags) -> Bool {
      return keyCommand.input == input && keyCommand.modifierFlags == modifierFlags
    }
  }

  func == (lhs: KeyActionableCommand, rhs: KeyActionableCommand) -> Bool {
    return lhs.keyCommand.input == rhs.keyCommand.input
          && lhs.keyCommand.modifierFlags == rhs.keyCommand.modifierFlags
  }


  public enum KeyCommands {
    private static var __once: () = {
      exchangeImplementations(class: UIApplication.self, originalSelector: #selector(getter: UIResponder.keyCommands), swizzledSelector: #selector(UIApplication.KYC_keyCommands));
    }()
    fileprivate struct Static {
      static var token: Int = 0
    }


    struct KeyCommandsRegister {
      static var sharedInstance = KeyCommandsRegister()
      fileprivate var actionableKeyCommands = [KeyActionableCommand]()
    }


    /// Registers key command for specified input and modifier flags. Unregisters previously
    /// registered key commands matching provided input and modifier flags. Does nothing when 
    /// application runs on actual device.
    public static func register(input: String,
                                modifierFlags: UIKeyModifierFlags,
                                action: @escaping () -> ()) {
      _ = KeyCommands.__once
      let keyCommand = UIKeyCommand(input: input,
                                    modifierFlags: modifierFlags,
                                    action: #selector(UIApplication.KYC_handleKeyCommand(_:)),
                                    discoverabilityTitle: "")
      let actionableKeyCommand = KeyActionableCommand(keyCommand: keyCommand, actionBlock: action)
      let index = KeyCommandsRegister.sharedInstance.actionableKeyCommands.index(
          where: { return $0 == actionableKeyCommand })
      if let index = index {
        KeyCommandsRegister.sharedInstance.actionableKeyCommands.remove(at: index)
      }
      KeyCommandsRegister.sharedInstance.actionableKeyCommands.append(actionableKeyCommand)
    }

    /// Unregisters key command matching specified input and modifier flags. 
    /// Does nothing when application runs on actual device.
    public static func unregister(input: String, modifierFlags: UIKeyModifierFlags) {
      let index = KeyCommandsRegister.sharedInstance.actionableKeyCommands.index(
          where: { return $0.matches(input, modifierFlags: modifierFlags) })
      if let index = index {
        KeyCommandsRegister.sharedInstance.actionableKeyCommands.remove(at: index)
      }
    }
  }

  extension UIApplication {
    dynamic func KYC_keyCommands() -> [UIKeyCommand] {
      return KeyCommands.KeyCommandsRegister.sharedInstance.actionableKeyCommands.map({
        return $0.keyCommand
      })
    }

    func KYC_handleKeyCommand(_ keyCommand: UIKeyCommand) {
      for command in KeyCommands.KeyCommandsRegister.sharedInstance.actionableKeyCommands {
        if command.matches(keyCommand.input, modifierFlags: keyCommand.modifierFlags) {
          command.actionBlock()
        }
      }
    }
  }


  func exchangeImplementations(class classs: AnyClass,
                               originalSelector: Selector,
                               swizzledSelector: Selector ){
    let originalMethod = class_getInstanceMethod(classs, originalSelector)
    let originalMethodImplementation = method_getImplementation(originalMethod)
    let originalMethodTypeEncoding = method_getTypeEncoding(originalMethod)
    let swizzledMethod = class_getInstanceMethod(classs, swizzledSelector)
    let swizzledMethodImplementation = method_getImplementation(swizzledMethod)
    let swizzledMethodTypeEncoding = method_getTypeEncoding(swizzledMethod)
    let didAddMethod = class_addMethod(classs, originalSelector, swizzledMethodImplementation, swizzledMethodTypeEncoding)
    if didAddMethod {
      class_replaceMethod(classs,
                          swizzledSelector,
                          originalMethodImplementation,
                          originalMethodTypeEncoding)
    } else {
      method_exchangeImplementations(originalMethod, swizzledMethod)
    }
  }

#else

  public enum KeyCommands {
    public static func registerKeyCommand(input: String,
                                          modifierFlags: UIKeyModifierFlags,
                                          action: () -> ()) {}

    public static func unregisterKeyCommand(input: String, modifierFlags: UIKeyModifierFlags) {}
  }

#endif
