//
//  XCTestCase+Extensions.swift
//  KumaLoadingSystemTests
//
//  Created by SUNG HAO LIN on 2021/10/26.
//

import XCTest

extension XCTestCase {
  func makeImageURL(withPath path: String) -> URL {
    return URL(string: "https://image.tmdb.org/t/p/w500/")!.appendingPathComponent(path)
  }

  func anyID() -> Int {
    return Int.random(in: 1...10000)
  }

  func anyNSError() -> NSError {
    return NSError(domain: "Test", code: 0)
  }

  func anyURL() -> URL {
    return URL(string: "http://any-url.com")!
  }

  func feedURL() -> URL {
    return URL(string: "https://api.themoviedb.org/3/discover/movie?api_key=61c433b8fef1ba8a3d8a518ce6f02576&language=zh-TW&page=1&sort_by=popularity.desc")!
  }
  
  func anyData() -> Data {
    return Data("any data".utf8)
  }
}
