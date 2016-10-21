/*
 
 ScriptManager.swift
 
 CotEditor
 https://coteditor.com
 
 Created by nakamuxu on 2005-03-12.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

final class ScriptManager: NSObject, NSFilePresenter {
    
    // MARK: Public Properties
    
    static let shared = ScriptManager()
    
    
    // MARK: Private Properties
    
    private let scriptsDirectoryURL: URL
    
    /// file extensions for UNIX scripts
    private let scriptExtensions: [String] = ["sh", "pl", "php", "rb", "py", "js"]
    
    /// file extensions for AppleScript
    private let AppleScriptExtensions = ["applescript", "scpt"]
    
    private var didChangeFolder = false
    
    
    
    // MARK: Private Enum
    
    private enum OutputType: String, ScriptToken {
        
        case replaceSelection = "ReplaceSelection"
        case replaceAllText = "ReplaceAllText"
        case insertAfterSelection = "InsertAfterSelection"
        case appendToAllText = "AppendToAllText"
        case pasteBoard = "Pasteboard"
        
        static var token = "CotEditorXOutput"
    }
    
    
    private enum InputType: String, ScriptToken {
        
        case selection = "Selection"
        case allText = "AllText"
        
        static var token = "CotEditorXInput"
    }
    
    
    private enum MenuItemTag: Int {
        case scriptsDefault = 8001  // not to list up in context menu
    }
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    private override init() {
        
        // find Application Scripts folder
        do {
            self.scriptsDirectoryURL = try FileManager.default.url(for: .applicationScriptsDirectory,
                                                                   in: .userDomainMask, appropriateFor: nil, create: true)
        } catch _ {
            // fallback directory creation for in case the app is not Sandboxed
            let bundleIdentifier = Bundle.main.bundleIdentifier!
            let libraryURL = try! FileManager.default.url(for: .libraryDirectory,
                                                          in: .userDomainMask, appropriateFor: nil, create: false)
            self.scriptsDirectoryURL = libraryURL.appendingPathComponent("Application Scripts").appendingPathComponent(bundleIdentifier, isDirectory: true)
            
            if !self.scriptsDirectoryURL.isReachable {
                try! FileManager.default.createDirectory(at: self.scriptsDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            }
        }
        
        super.init()
        
        self.buildScriptMenu()
        
        // observe for script folder change
        NSFileCoordinator.addFilePresenter(self)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: .NSApplicationDidBecomeActive, object: NSApp)
        
        // run dummy AppleScript once for quick script launch
        DispatchQueue.main.async {
            NSAppleScript(source: "tell application \"CotEditor\" to name")?.executeAndReturnError(nil)
        }
    }
    
    
    deinit {
        NSFileCoordinator.removeFilePresenter(self)
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
    // MARK: File Presenter Protocol
    
    var presentedItemOperationQueue = OperationQueue.main
    
    
    var presentedItemURL: URL? {
        
        return self.scriptsDirectoryURL
    }
    
    
    /// script folder did change
    func presentedSubitemDidChange(at url: URL) {
        
        self.didChangeFolder = true
        
        if NSApp.isActive {
            self.buildScriptMenu()
        }
    }
    
    
    /// update script menu if needed
    func applicationDidBecomeActive(_ notification: Notification) {
        
        if self.didChangeFolder {
            self.buildScriptMenu()
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// return menu for context menu
    var contexualMenu: NSMenu? {
        
        let menu = NSMenu()
        
        for item in MainMenu.script.menu!.items {
            guard item.tag != MenuItemTag.scriptsDefault.rawValue else { continue }
            
            menu.addItem(item.copy() as! NSMenuItem)
        }
        
        return (menu.numberOfItems > 0) ? menu : nil
    }
    
    
    /// build Script menu
    func buildScriptMenu() {
        
        let menu = MainMenu.script.menu!
        
        menu.removeAllItems()
        
        self.addChildFileItem(to: menu, fromDirctory: self.scriptsDirectoryURL)
        
        if !menu.items.isEmpty {
            menu.addItem(NSMenuItem.separator())
        }
        
        let openMenuItem = NSMenuItem(title: NSLocalizedString("Open Scripts Folder", comment: ""),
                                      action: #selector(openScriptFolder), keyEquivalent: "")
        openMenuItem.target = self
        openMenuItem.tag = MenuItemTag.scriptsDefault.rawValue
        menu.addItem(openMenuItem)
        
        self.didChangeFolder = false
    }
    
    
    
    // MARK: Action Message
    
    /// launch script (invoked by menu item)
    @IBAction func launchScript(_ sender: AnyObject?) {
        
        guard let url = sender?.representedObject as? URL else { return }
        
        do {
            try self.runScript(url: url)
        } catch let error {
            NSApp.presentError(error)
        }
    }
    
    
    /// open Script Menu folder in Finder
    @IBAction func openScriptFolder(_ sender: Any?) {
        
        NSWorkspace.shared().activateFileViewerSelecting([self.scriptsDirectoryURL])
    }
    
    
    // MARK: Private Methods
    
    /// return document content conforming to the input type
    /// - throws: ScriptError
    private func inputString(type: InputType, editor: Editable?) throws -> String {
    
        guard let editor = editor else {
            // on no document found
            throw ScriptError.noInputTarget
        }
        
        switch type {
        case .selection:
            return editor.selectedString
            
        case .allText:
            return editor.string
        }
    }
    
    
    /// apply results conforming to the output type to the frontmost document
    /// - throws: ScriptError
    private func applyOutput(_ output: String, editor: Editable?, type: OutputType) throws {
        
        guard editor != nil || type == .pasteBoard else {
            throw ScriptError.noOutputTarget
        }
        
        switch type {
        case .replaceSelection:
            editor!.insert(string: output)
            
        case .replaceAllText:
            editor!.replaceAllString(with: output)
            
        case .insertAfterSelection:
            editor!.insertAfterSelection(string: output)
            
        case .appendToAllText:
            editor!.append(string: output)
            
        case .pasteBoard:
            let pasteboard = NSPasteboard.general()
            pasteboard.declareTypes([NSStringPboardType], owner: nil)
            guard pasteboard.setString(output, forType: NSStringPboardType) else {
                NSBeep()
                return
            }
        }
    }
    
    
    /// read files and create/add menu items
    private func addChildFileItem(to menu: NSMenu, fromDirctory directoryURL: URL) {
        
        guard let fileURLs = try? FileManager.default.contentsOfDirectory(at: directoryURL,
                                                                          includingPropertiesForKeys: [.fileResourceTypeKey],
                                                                          options: [.skipsPackageDescendants, .skipsHiddenFiles])
            else { return }
        
        for fileURL in fileURLs {
            // ignore files/folders of which name starts with "_"
            if fileURL.lastPathComponent.hasPrefix("_") { continue }
        
            let title = self.scriptName(from: fileURL)
            
            if title == String.separator {
                menu.addItem(NSMenuItem.separator())
                continue
            }
            
            guard let resourceType = (try? fileURL.resourceValues(forKeys: [.fileResourceTypeKey]))?.fileResourceType else { continue }
            
            switch resourceType {
            case URLFileResourceType.directory:
                let submenu = NSMenu(title: title)
                let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                item.tag = MainMenu.MenuItemTag.scriptDirectory.rawValue
                menu.addItem(item)
                item.submenu = submenu
                self.addChildFileItem(to: submenu, fromDirctory: fileURL)
                
            case URLFileResourceType.regular:
                guard (self.AppleScriptExtensions + self.scriptExtensions).contains(fileURL.pathExtension) else { continue }
                
                let shortcut = self.shortcut(from: fileURL)
                let item = NSMenuItem(title: title, action: #selector(launchScript), keyEquivalent: shortcut.keyEquivalent)
                item.keyEquivalentModifierMask = shortcut.modifierMask
                item.representedObject = fileURL
                item.target = self
                item.toolTip = NSLocalizedString("“Option + click” to open script in editor.", comment: "")
                menu.addItem(item)
                
            default: break
            }
        }
    }
    
    
    /// build menu item title from file/folder name
    private func scriptName(from url: URL) -> String {
        
        let filename = url.deletingPathExtension().lastPathComponent
        
        // remove the number prefix ordering
        var scriptName = filename.replacingOccurrences(of: "^[0-9]+\\)", with: "", options: .regularExpression)
        
        // remove keyboard shortcut definition
        let specChars = ModifierKey.all.map { $0.keySpecChar }
        if let firstExtensionChar = scriptName.components(separatedBy: ".").last?.characters.first,
            specChars.contains(String(firstExtensionChar))
        {
            scriptName = scriptName.components(separatedBy: ".").first!
        }
        
        return scriptName
    }
    
    
    /// get keyboard shortcut from file name
    private func shortcut(from fileURL: URL) -> Shortcut {
        
        let keySpecChars = fileURL.deletingPathExtension().pathExtension
        let shortcut = Shortcut(keySpecChars: keySpecChars)
        
        guard shortcut.modifierMask.contains(.command) else { return .none }
        
        return shortcut
    }
    
    
    /// read content of script file
    private func contentStringOfScript(url: URL) -> String? {
        
        guard let data = try? Data(contentsOf: url) else { return nil }
        
        for encoding in EncodingManager.shared.defaultEncodings {
            guard let encoding = encoding else { continue }
            
            if let contentString = String(data: data, encoding: encoding) {
                return contentString
            }
        }
        
        return nil
    }
    
    
    /// run script file at url
    /// - throws: ScriptFileError
    private func runScript(url fileURL: URL) throws {
        
        // display alert and endup if file not exists
        guard fileURL.isReachable else {
            throw ScriptFileError(kind: .existance, url: fileURL)
        }
        
        let pathExtension = fileURL.pathExtension
        
        // change behavior if modifier key is pressed
        let modifierFlags = NSEvent.modifierFlags()
        if modifierFlags == .option {  // open script file in editor if the Option key is pressed
            let identifier = self.AppleScriptExtensions.contains(pathExtension) ? BundleIdentifier.ScriptEditor : Bundle.main.bundleIdentifier!
            guard NSWorkspace.shared().open([fileURL], withAppBundleIdentifier: identifier, additionalEventParamDescriptor: nil, launchIdentifiers: nil) else {
                // display alert if cannot open/select the script file
                throw ScriptFileError(kind: .open, url: fileURL)
            }
            return
            
        } else if modifierFlags == [.option, .shift] {  // reveal on Finder if the Option+Shift keys are pressed
            NSWorkspace.shared().activateFileViewerSelecting([fileURL])
            return
        }
        
        // run AppleScript
        if self.AppleScriptExtensions.contains(pathExtension) {
            try self.runAppleScript(url: fileURL)
            
            // run Shell Script
        } else if self.scriptExtensions.contains(pathExtension) {
            try self.runShellScript(url: fileURL)
        }
    }
    
    
    /// run AppleScriptrunAppleScript
    /// - throws: Error by NSUserScriptTask
    private func runAppleScript(url: URL) throws {
        
        let task = try NSUserAppleScriptTask(url: url)
        
        task.execute(withAppleEvent: nil, completionHandler: { [weak self] (result: NSAppleEventDescriptor?, error: Error?) in
            if let error = error {
                self?.writeToConsole(message: error.localizedDescription, scriptURL: url)
            }
        })
    }
    
    
    /// run UNIX script
    /// - throws: ScriptFileError or Error by NSUserScriptTask
    private func runShellScript(url: URL) throws {
        
        // display alert if script file doesn't have execution permission
        guard url.isExecutable ?? false else {
            throw ScriptFileError(kind: .permission, url: url)
        }
        
        // show an alert and endup if script file cannot read
        guard let script = self.contentStringOfScript(url: url), !script.isEmpty else {
            throw ScriptFileError(kind: .read, url: url)
        }
        
        // hold target document
        weak var document = NSDocumentController.shared().currentDocument as? Document
        
        // read input
        var input: String?
        if let inputType = InputType(scanning: script) {
            do {
                input = try self.inputString(type: inputType, editor: document)
            } catch let error {
                self.writeToConsole(message: error.localizedDescription, scriptURL: url)
                return
            }
        }
        
        // get output type
        let outputType = OutputType(scanning: script)
        
        // prepare file path as argument if available
        let arguments: [String] = {
            guard let path = document?.fileURL?.path else { return [] }
            return [path]
        }()
        
        // create task
        let task = try NSUserUnixTask(url: url)
        
        // set pipes
        let inPipe = Pipe()
        let outPipe = Pipe()
        let errPipe = Pipe()
        task.standardInput = inPipe.fileHandleForReading
        task.standardOutput = outPipe.fileHandleForWriting
        task.standardError = errPipe.fileHandleForWriting
        
        // set input data asynchronously if available
        if let input = input, !input.isEmpty {
            inPipe.fileHandleForWriting.writeabilityHandler = { (handle: FileHandle) in
                let data = input.data(using: .utf8)!
                handle.write(data)
                handle.closeFile()
            }
        }
        
        var isCancelled = false  // user cancel state
        
        // read output asynchronously for safe with huge output
        outPipe.fileHandleForReading.readToEndOfFileInBackgroundAndNotify()
        var observer: NSObjectProtocol?
        observer = NotificationCenter.default.addObserver(forName: .NSFileHandleReadToEndOfFileCompletion, object: outPipe.fileHandleForReading, queue: nil) { [weak self] (note: Notification) in
            NotificationCenter.default.removeObserver(observer!)
            
            guard !isCancelled else { return }
            guard let outputType = outputType else { return }
            
            guard let data = note.userInfo?[NSFileHandleNotificationDataItem] as? Data else { return }
            if let output = String(data: data, encoding: .utf8) {
                do {
                    try self?.applyOutput(output, editor: document, type: outputType)
                } catch let error {
                    self?.writeToConsole(message: error.localizedDescription, scriptURL: url)
                }
            }
        }
        
        // execute
        task.execute(withArguments: arguments) { [weak self] error in
            // on user cancel
            if let error = error as? POSIXError, error.code == .ENOTBLK {
                isCancelled = true
                return
            }
            
            //set error message to the sconsole
            let errorData = errPipe.fileHandleForReading.readDataToEndOfFile()
            if let message = String(data: errorData, encoding: .utf8), !message.isEmpty {
                self?.writeToConsole(message: message, scriptURL: url)
            }
        }
    }
    
    
    /// append message to console panel and show it
    private func writeToConsole(message: String, scriptURL: URL) {
        
        let scriptName = self.scriptName(from: scriptURL)
        
        DispatchQueue.main.async {
            ConsolePanelController.shared.showWindow(nil)
            ConsolePanelController.shared.append(message: message, title: scriptName)
        }
    }

}



// MARK: - Error

private enum ScriptError: Error {
    
    case noInputTarget
    case noOutputTarget
    
    
    var localizedDescription: String {
        
        switch self {
        case .noInputTarget:
            return NSLocalizedString("No document to get input.", comment: "")
        case .noOutputTarget:
            return NSLocalizedString("No document to put output.", comment: "")
        }
    }
    
}


private struct ScriptFileError: LocalizedError {
    
    enum ErrorKind {
        case existance
        case read
        case open
        case permission
    }
    
    let kind: ErrorKind
    let url: URL
    
    
    var errorDescription: String? {
        
        switch self.kind {
        case .existance:
            return String(format: NSLocalizedString("The script “%@” does not exist.", comment: ""), self.url.lastPathComponent)
        case .read:
            return String(format: NSLocalizedString("The script “%@” couldn’t be read.", comment: ""), self.url.lastPathComponent)
        case .open:
            return String(format: NSLocalizedString("The script file “%@” couldn’t be opened.", comment: ""), self.url.path)
        case .permission:
            return String(format: NSLocalizedString("The script “%@” can’t be executed because you don’t have the execute permission.", comment: ""), self.url.lastPathComponent)
        }
    }
    
    
    var recoverySuggestion: String? {
        
        switch self.kind {
        case .permission:
            return NSLocalizedString("Check permission of the script file.", comment: "")
        default:
            return NSLocalizedString("Check the script file.", comment: "")
        }
    }
    
}


// MARK: - ScriptToken

private protocol ScriptToken {
    
    static var token: String { get }
    
    init?(rawValue: String)
    
}

private extension ScriptToken {
    
    /// read type from script
    init?(scanning script: String) {
        
        let pattern = "%%%\\{" + Self.token + "=" + "(.+)" + "\\}%%%"
        let regex = try! NSRegularExpression(pattern: pattern)
        
        guard let result = regex.firstMatch(in: script, range: script.nsRange) else { return nil }
        
        let type = (script as NSString).substring(with: result.rangeAt(1))
        
        self.init(rawValue: type)
    }
}
