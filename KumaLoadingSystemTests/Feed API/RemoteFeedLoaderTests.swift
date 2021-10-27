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

  func test_load_deliversErrorOnClientError() {
    let (sut, client) = makeSUT()

    expect(sut, toCompleteWith: failure(.connectivity)) {
      let clientError = anyNSError()
      client.complete(with: clientError)
    }
  }

  func test_load_deliversErrorOnNon200HTTPResponse() {
    let (sut, client) = makeSUT()

    let samples = [199, 201, 300, 400, 500]

    samples.enumerated().forEach { index, code in
      expect(sut, toCompleteWith: failure(.invalidData)) {
        let json = makeItemsJSON([])
        client.complete(withStatusCode: code, data: json, at: index)
      }
    }
  }

  func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
    let (sut, client) = makeSUT()

    expect(sut, toCompleteWith: failure(.invalidData)) {
      let invalidJSON = Data("invalid json".utf8)
      client.complete(withStatusCode: 200, data: invalidJSON)
    }
  }

  func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
    let (sut, client) = makeSUT()

    expect(sut, toCompleteWith: .success([])) {
      // let emptyListJSON = Data("{\"items\": []}".utf8)
      let emptyListJSON = makeItemsJSON([])
      client.complete(withStatusCode: 200, data: emptyListJSON)
    }
  }

  func test_load_deliversItemsOn200HTTPResponseWithJSONItems() {
    let (sut, client) = makeSUT()

    let item1 = makeItem(id: anyID(),
                         title: "item1-title",
                         average: 8.1,
                         path: "http://a-url.com")

    let item2 = makeItem(id: anyID(),
                         title: "item2-title",
                         average: 8.6,
                         path: "http://another-url.com")

    let items = [item1.model, item2.model]

    expect(sut, toCompleteWith: .success(items), when: {
      // Conversion to data
      let json = makeItemsJSON([item1.json, item2.json])
      client.complete(withStatusCode: 200, data: json)
    })
  }

  func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
    let feedAPI: TmdbAPI = .feed
    let client = HTTPClientSpy()
    var sut: RemoteFeedLoader? = RemoteFeedLoader(api: feedAPI, client: client)

    var capturedResults = [RemoteFeedLoader.Result]()
    sut?.load { capturedResults.append($0) }

    sut = nil
    client.complete(withStatusCode: 200, data: makeItemsJSON([]))

    XCTAssertTrue(capturedResults.isEmpty)
  }

  // MARK: - Helpers

  private func makeSUT(api: TmdbAPI = .feed, file: StaticString = #file, line: UInt = #line) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
    let client = HTTPClientSpy()
    let sut = RemoteFeedLoader(api: api, client: client)
    trackForMemoryLeaks(client, file: file, line: line)
    trackForMemoryLeaks(sut, file: file, line: line)
    return (sut, client)
  }

  private func makeItem(id: Int, title: String, average: Double, path: String) -> (model: FeedItem, json: [String: Any]) {
    let item = FeedItem(id: id, title: title, average: average, url: makeImageURL(withPath: path))

    let json = [
      "id": id,
      "title": title,
      "vote_average": average,
      "backdrop_path": path
    ].compactMapValues { $0 }

    return (item, json)
  }

  private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
    let json = ["results": items]
    return try! JSONSerialization.data(withJSONObject: json)
  }

  private func expect(_ sut: RemoteFeedLoader, toCompleteWith expectedResult: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
    let exp = expectation(description: "Wait for load completion")

    sut.load { receivedResult in
      // 這邊對於 Result 比較只有在測試需要，在 production 是不需要的，所以不用做 Equatable
      switch (receivedResult, expectedResult) {
      case let (.success(receivedItems), .success(expectedItems)):
        XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)

      case let (.failure(receivedError as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
        XCTAssertEqual(receivedError, expectedError, file: file, line: line)

      default:
        XCTFail("Expected result \(expectedResult) got \(receivedResult) instead", file: file, line: line)
      }

      exp.fulfill()
    }

    action()

    wait(for: [exp], timeout: 1.0)
  }

  private func failure(_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
    return .failure(error)
  }

  private class HTTPClientSpy: HTTPClient {
    private var messages = [(api: TmdbAPI, completion: (HTTPClientResult) -> Void)]()

    var requestedAPIs: [TmdbAPI] {
      return messages.map { $0.api }
    }

    func get(from api: TmdbAPI, completion: @escaping (HTTPClientResult) -> Void) {
      messages.append((api, completion))
    }

    func complete(with error: Error, at index: Int = 0) {
      messages[index].completion(.failure(error))
    }

    func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
      let response = HTTPURLResponse(url: URL(string: "any-\(index)-url.com")!,
                                     statusCode: code,
                                     httpVersion: nil,
                                     headerFields: nil)!
      messages[index].completion(.success(data, response))
    }
  }
}
