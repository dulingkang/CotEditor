//
//  EditorScrollView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-01-15.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2018 1024jp
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

final class EditorScrollView: NSScrollView {
    
    // MARK: Private Properties
    
    private var orientationObserver: NSKeyValueObservation?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    deinit {
        self.orientationObserver?.invalidate()
    }
    
    
    
    // MARK: Scroll View Methods
    
    /// use custom ruler view
    override class var rulerViewClass: AnyClass! {
        
        get {
            return LineNumberView.self
        }
        
        set {
            super.rulerViewClass = LineNumberView.self
        }
    }
    
    
    /// set text view
    override var documentView: NSView? {

        willSet {
            self.orientationObserver?.invalidate()
        }
        
        didSet {
            guard let textView = documentView as? NSTextView else { return assertionFailure() }
            
            self.orientationObserver = textView.observe(\.layoutOrientation, options: .initial) { [unowned self] (textView, _) in
                switch textView.layoutOrientation {
                case .horizontal:
                    self.hasVerticalRuler = true
                    self.hasHorizontalRuler = false
                case .vertical:
                    self.hasVerticalRuler = false
                    self.hasHorizontalRuler = true
                }
                
                // invalidate line number view background
                self.window?.viewsNeedDisplay = true
            }
        }
    }
    
    
    /// update layer (called also when system appearance was changed)
    override func updateLayer() {
        
        // -> super dirty workaround to update titlebar's backaround color by considering the real "current" appearance (2018-09 macOS 10.14)
        if #available(macOS 10.14, *) {
            (self.window as? DocumentWindow)?.invalidateTitlebarOpacity()
        }
    }
    
    
    
    // MARK: Public Methods
    
    func invalidateLineNumber() {
        
        self.lineNumberView?.needsDisplay = true
    }
    
    
    
    // MARK: Private Methods
    
    /// return layout orientation of document text view
    private var layoutOrientation: NSLayoutManager.TextLayoutOrientation {
        
        guard let documentView = self.documentView as? NSTextView else {
            return .horizontal
        }
        
        return documentView.layoutOrientation
    }
    
    
    /// return current line number view
    private var lineNumberView: NSRulerView? {
    
        switch self.layoutOrientation {
        case .horizontal:
            return self.verticalRulerView
        case .vertical:
            return self.horizontalRulerView
        }
    }
    
}
