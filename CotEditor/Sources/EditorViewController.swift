//
//  EditorViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by nakamuxu on 2006-03-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2018 1024jp
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Cocoa

fileprivate extension Selector {
  static let unPackAll = #selector(EditorViewController.unPackAll)
  static let unPackJce = #selector(EditorViewController.unPackJce)
  static let unPackTlv = #selector(EditorViewController.unPackTlv)
  static let unPackPb = #selector(EditorViewController.unPackPb)
}

enum MenuTitle: String {
  case unPackAll, unPackJce, unPackTlv, unPackPb
  func action() -> Selector {
    switch self {
    case .unPackAll:
      return Selector.unPackAll
    case .unPackJce:
      return Selector.unPackJce
    case .unPackTlv:
      return Selector.unPackTlv
    case .unPackPb:
      return Selector.unPackPb
    }
  }
}



final class EditorViewController: NSSplitViewController {
  
  // MARK: Public Properties
  
  var textStorage: NSTextStorage? {
    
    didSet {
      guard let textStorage = textStorage else { return }
      
      self.textView?.layoutManager?.replaceTextStorage(textStorage)
      self.textView?.didChangeText()  // notify to lineNumberView
    }
  }
  
  var textView: EditorTextView? {
    
    return self.textViewController?.textView
  }
  
  var navigationBarController: NavigationBarController? {
    
    return self.navigationBarItem?.viewController as? NavigationBarController
  }
  
  
  // MARK: Private Properties
  
  @IBOutlet private weak var navigationBarItem: NSSplitViewItem?
  @IBOutlet private weak var textViewItem: NSSplitViewItem?
  
  
  
  // MARK: -
  // MARK: Split View Controller Methods
  
  /// setup UI
  override func viewDidLoad() {
    
    super.viewDidLoad()
    
    self.navigationBarController?.textView = self.textView
    
    // set accessibility
    self.view.setAccessibilityElement(true)
    self.view.setAccessibilityRole(.group)
    self.view.setAccessibilityLabel("editor".localized)
    self.textView?.menu = rightMenu()
  }
  
  /// avoid showing draggable cursor
  override func splitView(_ splitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect, forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex: Int) -> NSRect {
    
    // -> must call super's delegate method anyway.
    super.splitView(splitView, effectiveRect: proposedEffectiveRect, forDrawnRect: drawnRect, ofDividerAt: dividerIndex)
    
    return .zero
  }
  
  
  /// validate actions
  override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
    
    switch item.action {
    case #selector(selectPrevItemOfOutlineMenu)?:
      return self.navigationBarController?.canSelectPrevItem ?? false
      
    case #selector(selectNextItemOfOutlineMenu)?:
      return self.navigationBarController?.canSelectNextItem ?? false
      
    default: break
    }
    
    return super.validateUserInterfaceItem(item)
  }
  
  
  
  // MARK: Public Methods
  
  /// Whether line number view is visible
  var showsLineNumber: Bool {
    
    get {
      return self.textViewController?.showsLineNumber ?? false
    }
    
    set {
      self.textViewController?.showsLineNumber = newValue
    }
  }
  
  
  /// Whether navigation bar is visible
  var showsNavigationBar: Bool {
    
    get {
      return !(self.navigationBarItem?.isCollapsed ?? true)
    }
    
    set {
      self.navigationBarItem?.isCollapsed = !newValue
    }
  }
  
  
  /// apply syntax style to inner text view
  func apply(syntax: SyntaxStyle) {
    
    self.textViewController?.syntaxStyle = syntax
  }
  
  // MARK: Private Methods
  
  /// split view item to view controller
  private var textViewController: EditorTextViewController? {
    
    return self.textViewItem?.viewController as? EditorTextViewController
  }
  
}

// MARK: action
extension EditorViewController {
  @objc func unPackAll() {
    guard let textView = self.textView else {
      return
    }
    let rangeValue = textView.selectedRanges[0] as! NSRange
    let range = textView.string.toRange(rangeValue)
    let selectedString = String(textView.string[range!])
    Net.post(Api.all.rawValue, params: ["sessionKey": KeyManager.shared.shareKey, "qq": "421629992", "text": selectedString]) { [weak self] model in
      guard let strongSelf = self, let textView = strongSelf.textView else {
        return
      }
      textView.insertText(model.msg, replacementRange: NSRange(location: textView.string.lengthOfBytes(using: .utf8), length: 0))
    }
  }
  @objc func unPackJce() {
    
  }
  
  @objc func unPackTlv() {
    
  }
  
  @objc func unPackPb() {
    
  }
  
  /// select previous outline menu item (bridge action from menu bar)
  @IBAction func selectPrevItemOfOutlineMenu(_ sender: Any?) {
    
    self.navigationBarController?.selectPrevItemOfOutlineMenu(sender)
  }
  
  
  /// select next outline menu item (bridge action from menu bar)
  @IBAction func selectNextItemOfOutlineMenu(_ sender: Any?) {
    
    self.navigationBarController?.selectNextItemOfOutlineMenu(sender)
  }
}

fileprivate extension EditorViewController {
  func rightMenu() -> NSMenu {
    let menu = NSMenu(title: "")
    
    //增加item
    var item = createItem(title: MenuTitle.unPackAll.rawValue, action: MenuTitle.unPackAll.action())
    print(MenuTitle.unPackAll.rawValue)
    menu.addItem(item)
    item = createItem(title: MenuTitle.unPackJce.rawValue, action: MenuTitle.unPackJce.action())
    menu.addItem(item)
    item = createItem(title: MenuTitle.unPackTlv.rawValue, action: MenuTitle.unPackTlv.action())
    menu.addItem(item)
    item = createItem(title: MenuTitle.unPackPb.rawValue, action: MenuTitle.unPackPb.action())
    menu.addItem(item)
    return menu
  }
  
  func createItem(title: String, action: Selector) -> NSMenuItem {
    let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
    item.isEnabled = true
    item.target = self
    return item
  }
}
