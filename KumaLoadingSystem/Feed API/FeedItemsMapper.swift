//
//  FeedItemsMapper.swift
//  KumaLoadingSystem
//
//  Created by SUNG HAO LIN on 2021/10/26.
//

import Foundation

final class FeedItemsMapper {
  static var OK_200: Int { return 200 }

  static func map(_ data: Data, from response: HTTPURLResponse) -> RemoteFeedLoader.Result {
    guard response.statusCode == OK_200, let root = try? JSONDecoder().decode(Root.self, from: data) else {
      return .failure(RemoteFeedLoader.Error.invalidData)
    }

    return .success(root.feed)
  }

  // Make the initializer private that FeedItemMapper is just a namespace for static methods, with no instance-specific behavior.
  private init() {}

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
