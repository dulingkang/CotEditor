//
//  KeyManager.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by dulingkang on 2018/11/10.
//

import Foundation

struct KeyEnum {
  static let nameKey = "nameKey"
  static let passwordKey = "passwordKey"
  static let shareKey = "shareKey"
  static let tokenKey = "tokenKey"
  static let tgtKey = "tgtKey"
  static let priKey = "priKey"
}

final class KeyManager: NSObject {
  static let shared: KeyManager = KeyManager()
  var name: String {
    get {
      return UserDefaults.standard.string(forKey: KeyEnum.nameKey) ?? ""
    }
    set {
      if !newValue.isEmpty {
        UserDefaults.standard.set(newValue, forKey: KeyEnum.nameKey)
      }
    }
  }
  var password: String {
    get {
      return UserDefaults.standard.string(forKey: KeyEnum.passwordKey) ?? ""
    }
    set {
      if !newValue.isEmpty {
        UserDefaults.standard.set(newValue, forKey: KeyEnum.passwordKey)
      }
    }
    
  }
  var shareKey: String {
    get {
      return UserDefaults.standard.string(forKey: KeyEnum.shareKey) ?? ""
    }
    set {
      if !newValue.isEmpty {
        UserDefaults.standard.set(newValue, forKey: KeyEnum.shareKey)
      }
    }
    
  }
  var token: String {
    get {
      return UserDefaults.standard.string(forKey: KeyEnum.tokenKey) ?? ""
    }
    set {
      if !newValue.isEmpty {
        UserDefaults.standard.set(newValue, forKey: KeyEnum.tokenKey)
      }
    }
    
  }
  var tgtKey: String {
    get {
      return UserDefaults.standard.string(forKey: KeyEnum.tgtKey) ?? ""
    }
    set {
      if !newValue.isEmpty {
        UserDefaults.standard.set(newValue, forKey: KeyEnum.tgtKey)
      }
    }
  }
  var priKey: String {
    get {
      return UserDefaults.standard.string(forKey: KeyEnum.priKey) ?? ""
    }
    set {
      if !newValue.isEmpty {
        UserDefaults.standard.set(newValue, forKey: KeyEnum.priKey)
      }
    }
  }
  
}
