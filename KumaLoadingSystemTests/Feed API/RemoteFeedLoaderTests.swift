//
//  RemoteFeedLoaderTests.swift
//  KumaLoadingSystemTests
//
//  Created by SUNG HAO LIN on 2021/10/26.
//

import XCTest
import KumaLoadingSystem

class RemoteFeedLoader {
  let api: TmdbAPI
  let client: HTTPClient

  init(api: TmdbAPI, client: HTTPClient) {
    self.api = api
    self.client = client
  }
}

class RemoteFeedLoaderTests: XCTestCase {

  func test_init_doesNotRequestDataFromTmdbAPI() {
    let feedAPI: TmdbAPI = .feed
    let client = HTTPClientSpy()
    _ = RemoteFeedLoader(api: feedAPI, client: client)

    XCTAssertTrue(client.requestedAPIs.isEmpty)
  }

  private class HTTPClientSpy: HTTPClient {
    var requestedAPIs = [TmdbAPI]()

    func get(from api: TmdbAPI, completion: @escaping (HTTPClientResult) -> Void) {
      requestedAPIs.append(api)
    }
  }
}
