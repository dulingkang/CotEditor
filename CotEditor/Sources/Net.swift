//
//  Net.swift
//  ads
//
//  Created by dulingkang on 2018/8/2.
//  Copyright © 2018年 lukou. All rights reserved.
//

import Foundation

struct BaseModel: Codable {
  let msg: String
}

enum Api: String {
  case all = "parse"
}

struct Net {
  static let basePath = "http://127.0.0.1:8887"
//  static func get<T: Codable>(_ path: String = "", params: [String: String] = [:], complete: @escaping (BaseModel<T>) -> Void) {
//    var base = basePath
//    if !path.isEmpty {
//      base = base + "/" + path
//    }
//    let url = genURL(base.urlValue!, params: params)
//    let session = URLSession.shared
//    let task = session.dataTask(with: url.urlValue!) { (data, response, error) in
//      guard let data = data else { return }
//      do {
//        let model = try JSONDecoder().decode(BaseModel<T>.self, from: data)
//        DispatchQueue.main.async {
//          complete(model)
//        }
//      } catch {
//        print(error.localizedDescription)
//      }
//    }
//    task.resume()
//  }
  
  static func post(_ path: String = "", params: [String: String] = [:], complete: @escaping (BaseModel) -> Void) {
    var url = basePath
    if !path.isEmpty {
      url = url + "/" + path
    }
    var req = URLRequest(url: url.urlValue!)
    req.httpBody = genBody(params: params)
    req.httpMethod = "POST"
    req.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
    req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    let session = URLSession.shared
    let task = session.dataTask(with: req) { (data, response, error) in
      guard let data = data else { return }
      do {
        let model = try JSONDecoder().decode(BaseModel.self, from: data)
        DispatchQueue.main.async {
          complete(model)
        }
      } catch {
        print(error.localizedDescription)
      }
    }
    task.resume()
  }
  
}

fileprivate extension Net {
  static func genURL(_ base: URL, params: [String: String]) -> URL {
    var items: [URLQueryItem] = []
    for param in params {
      let item = URLQueryItem(name: param.key, value: param.value)
      items.append(item)
    }
    var components = URLComponents(url: base, resolvingAgainstBaseURL: false)
    components?.queryItems = items
    return components?.url ?? base
  }
  
  static func genBody(params: [String: String]) -> Data? {
    var str = ""
    for param in params {
      if str.isEmpty {
        str += "\(param.key)=\(param.value)"
      } else {
        str += "&\(param.key)=\(param.value)"
      }
    }
    return str.data(using: .utf8)
  }
}
