//
//  RemoteFeedLoaderTests.swift
//  KumaLoadingSystemTests
//
//  Created by SUNG HAO LIN on 2021/10/26.
//

import XCTest
import KumaLoadingSystem

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

  func test_loadTwice_requestsDataFromTmdbAPITwice() {
    let feedAPI: TmdbAPI = .feed
    let (sut, client) = makeSUT(api: feedAPI)

    sut.load { _ in }
    sut.load { _ in }

    XCTAssertEqual(client.requestedAPIs, [feedAPI, feedAPI])
  }

  // MARK: - Helpers

  private func makeSUT(api: TmdbAPI) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
    let client = HTTPClientSpy()
    let sut = RemoteFeedLoader(api: api, client: client)
    return (sut, client)
  }

  private class HTTPClientSpy: HTTPClient {
    var requestedAPIs = [TmdbAPI]()

    func get(from api: TmdbAPI, completion: @escaping (HTTPClientResult) -> Void) {
      requestedAPIs.append(api)
    }
  }
}
