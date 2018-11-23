//
//  PPURLConvertible.swift
//  ads
//
//  Created by dulingkang on 2018/8/2.
//  Copyright © 2018年 lukou. All rights reserved.
//

import Foundation

public protocol PPURLConvertible {
  var urlValue: URL? { get }
  var urlStringValue: String { get }
  var queryParameters: [String: String] { get }
  var queryItems: [URLQueryItem]? { get }
  var isValidURL: Bool { get }
}

extension PPURLConvertible {
  public var queryParameters: [String: String] {
    var parameters = [String: String]()
    self.urlValue?.query?.components(separatedBy: "&").forEach{
      let keyAndValue = $0.components(separatedBy: "=")
      if keyAndValue.count == 2 {
        let key = keyAndValue[0]
        let value = keyAndValue[1].removingPercentEncoding ?? keyAndValue[1]
        if key != "" && value != "" {
          parameters[key] = value
        }
      }
    }
    return parameters
  }
  
  public var queryItems: [URLQueryItem]? {
    return URLComponents(string: self.urlStringValue)?.queryItems
  }
  
  public var isValidURL: Bool {
    if let url = self.urlValue, let _ = url.scheme, let _ = url.host {
      return true
    }
    return false
  }
}

extension String: PPURLConvertible {
  public var urlValue: URL?  {
    if let url = URL(string: self) {
      return url
    }
    var set = CharacterSet()
    set.formUnion(.urlHostAllowed)
    set.formUnion(.urlPathAllowed)
    set.formUnion(.urlQueryAllowed)
    set.formUnion(.urlFragmentAllowed)
    return self.addingPercentEncoding(withAllowedCharacters: set).flatMap { URL(string: $0) }
  }
  
  public var urlStringValue: String {
    return self
  }
}

extension URL: PPURLConvertible {
  public var urlValue: URL? {
    return self
  }
  
  public var urlStringValue: String {
    return self.absoluteString
  }
}
