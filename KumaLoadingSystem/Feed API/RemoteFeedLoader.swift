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
        completion(FeedItemsMapper.map(data, from: response))
      case .failure:
        completion(.failure(Error.connectivity))
      }
    }
  }
}

final class FeedItemsMapper {
  static var OK_200: Int { return 200 }

  static func map(_ data: Data, from response: HTTPURLResponse) -> RemoteFeedLoader.Result {
    guard response.statusCode == OK_200, let root = try? JSONDecoder().decode(Root.self, from: data) else {
      return .failure(RemoteFeedLoader.Error.invalidData)
    }

    return .success(root.feed)
  }

  private struct Root: Decodable {
    let results: [Item]

    var feed: [FeedItem] {
      return results.map { $0.item }
    }
  }

  private struct Item: Decodable {
    let id: Int
    let title: String
    let vote_average: Double
    let backdrop_path: String

    // poster_size: w92, w154, w185, w342, w500, w780, original
    func makeImageURL(withPath path: String) -> URL {
      return URL(string: "https://image.tmdb.org/t/p/w500/")!.appendingPathComponent(path)
    }

    var item: FeedItem {
      return FeedItem(id: id,
                      title: title,
                      average: vote_average,
                      url: makeImageURL(withPath: backdrop_path))
    }
  }
}
