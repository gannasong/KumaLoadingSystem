//
//  RemoteFeedLoaderTests.swift
//  KumaLoadingSystemTests
//
//  Created by SUNG HAO LIN on 2021/10/26.
//

import XCTest
import KumaLoadingSystem

class RemoteFeedLoader: FeedLoader {
  let api: TmdbAPI
  let client: HTTPClient

  init(api: TmdbAPI, client: HTTPClient) {
    self.api = api
    self.client = client
  }

  func load(completion: @escaping (LoadFeedResult) -> Void) {
    client.get(from: api) { _ in }
  }
}

class RemoteFeedLoaderTests: XCTestCase {

  func test_init_doesNotRequestDataFromTmdbAPI() {
    let feedAPI: TmdbAPI = .feed
    let client = HTTPClientSpy()
    _ = RemoteFeedLoader(api: feedAPI, client: client)

    XCTAssertTrue(client.requestedAPIs.isEmpty)
  }

  func test_load_requestsDataFromTmdbAPI() {
    let feedAPI: TmdbAPI = .feed
    let client = HTTPClientSpy()
    let sut = RemoteFeedLoader(api: feedAPI, client: client)

    sut.load { _ in }

    XCTAssertEqual(client.requestedAPIs, [feedAPI])
  }

  // MARK: - Helpers

  private class HTTPClientSpy: HTTPClient {
    var requestedAPIs = [TmdbAPI]()

    func get(from api: TmdbAPI, completion: @escaping (HTTPClientResult) -> Void) {
      requestedAPIs.append(api)
    }
  }
}
