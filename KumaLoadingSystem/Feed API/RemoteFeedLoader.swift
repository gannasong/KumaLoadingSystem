//
//  RemoteFeedLoader.swift
//  KumaLoadingSystem
//
//  Created by SUNG HAO LIN on 2021/10/26.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
  private let api: TmdbAPI
  private let client: HTTPClient

  public init(api: TmdbAPI, client: HTTPClient) {
    self.api = api
    self.client = client
  }

  public func load(completion: @escaping (LoadFeedResult) -> Void) {
    client.get(from: api) { _ in }
  }
}
