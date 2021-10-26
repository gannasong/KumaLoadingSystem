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

  func anyError() -> NSError {
    return NSError(domain: "Test", code: 0)
  }
}
