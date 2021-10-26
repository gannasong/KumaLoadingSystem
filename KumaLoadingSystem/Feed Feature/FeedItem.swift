//
//  FeedItem.swift
//  KumaLoadingSystem
//
//  Created by SUNG HAO LIN on 2021/10/26.
//

import Foundation

public struct FeedItem: Equatable {
  public let id: Int
  public let title: String
  public let average: Double
  public let url: URL

  public init(id: Int, title: String, average: Double, url: URL) {
    self.id = id
    self.title = title
    self.average = average
    self.url = url
  }
}
