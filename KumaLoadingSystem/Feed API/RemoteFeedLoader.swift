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

  public typealias Result = LoadFeedResult
  
  public enum Error: Swift.Error {
    case connectivity
    case invalidData
  }

  public init(api: TmdbAPI, client: HTTPClient) {
    self.api = api
    self.client = client
  }

  public func load(completion: @escaping (Result) -> Void) {
    client.get(from: api) { result in
      switch result {
      case let .success(data, response):
        if response.statusCode == 200, let _ = try? JSONSerialization.jsonObject(with: data) {
          completion(.success([]))
        } else {
          completion(.failure(Error.invalidData))
        }
      case .failure:
        completion(.failure(Error.connectivity))
      }
    }
  }
}
