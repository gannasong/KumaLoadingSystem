//
//  MoyaHTTPClientTests.swift
//  KumaLoadingSystemTests
//
//  Created by SUNG HAO LIN on 2021/10/26.
//

import XCTest
import KumaLoadingSystem
import Moya

class MoyaHTTPClientTests: XCTestCase {

  override func tearDown() {
    super.tearDown()
    MoyaInterceptingStub.stopInterceptingRequests()
  }

  func test_getFromTarget_performsGETRequestWithEndpoint() {
    let endpoint = makeEndpointClosure(data: anyData(), response: anyHTTPURLResponse(), error: nil)
    let sut = makeSUT(endpointClosure: endpoint)
    let feedURL = feedURL()
    let exp = expectation(description: "Wait for request")

    MoyaInterceptingStub.observeRequests { request in
      XCTAssertEqual(request.url, feedURL)
      XCTAssertEqual(request.httpMethod, "GET")
      exp.fulfill()
    }

    sut.get(from: .feed) { _ in }

    wait(for: [exp], timeout: 1.0)
  }

  func test_getFromTarget_failsOnRequestError() {
    let requestError = anyNSError()

    let receivedError = resultErrorFor(data: nil, response: nil, error: requestError)

    XCTAssertNotNil(receivedError)
  }

  func test_getFromTarget_failsOnAllInvalidRepresentationCases() {
    /*
     These cases should *never* happen, however as `URLSession` represents these fields as optional
     it is possible in some obscure way that this state _could_ exist.
     |-----------------------------------------|
     | Data?    | URLResponse?      | Error?   |
     |----------|-------------------|----------|
     | nil      | nil               | nil      |
     | nil      | URLResponse       | nil      |
     | value    | nil               | nil      |
     | value    | nil               | value    |
     | nil      | URLResponse       | value    |
     | nil      | HTTPURLResponse   | value    |
     | value    | HTTPURLResponse   | value    |
     | value    | URLResponse       | nil      |
     |-----------------------------------------|
     */

    XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
    XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: nil))
    XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil))
    XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: nil))
    XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
  }

  func test_getFromTarget_succeedsOnHTTPURLResponseWithData() {
    let data = anyData()
    let response = anyHTTPURLResponse()

    let receivedValues = resultValuesFor(data: data, response: response, error: nil)

    XCTAssertEqual(receivedValues?.data, data)
    XCTAssertEqual(receivedValues?.response.url, response.url)
    XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
  }

  func test_getFromURL_succeedsWithEmptyDataOnHTTPURLResponseWithNilData() {
    let response = anyHTTPURLResponse()
    let emptyData = Data()

    let receivedValues = resultValuesFor(data: emptyData, response: response, error: nil)

    XCTAssertEqual(receivedValues?.data, emptyData)
    XCTAssertEqual(receivedValues?.response.url, response.url)
    XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
  }

  // MARK: - Helpers

  private func makeSUT(endpointClosure: @escaping ((TmdbAPI) -> Endpoint), file: StaticString = #file, line: UInt = #line) -> HTTPClient {
    let provider = MoyaProvider<TmdbAPI>(endpointClosure: endpointClosure, stubClosure: MoyaProvider.immediatelyStub, plugins: [MoyaInterceptingStub()])
    let sut = MoyaHTTPClient(provider: provider)
    trackForMemoryLeaks(sut, file: file, line: line)
    return sut
  }

  private func makeEndpointClosure(target: TmdbAPI = .feed, data: Data?, response: URLResponse?, error: Error?) -> (TmdbAPI) -> Endpoint {
    let sampleResponse = makeSampleResponse(data: data, response: response, error: error)

    return { (target: TmdbAPI) -> Endpoint in
      return Endpoint(url: URL(target: target).absoluteString,
                      sampleResponseClosure: { sampleResponse },
                      method: target.method,
                      task: target.task,
                      httpHeaderFields: target.headers)
    }
  }

  private func resultValuesFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> (data: Data, response: HTTPURLResponse)? {
    let result = resultFor(data: data, response: response, error: error, file: file, line: line)

    switch result {
    case let .success(data, response):
      return (data, response)
    default:
      XCTFail("Expected success, got \(result) instead", file: file, line: line)
      return nil
    }
  }

  private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> Error? {
    let result = resultFor(data: data, response: response, error: error, file: file, line: line)

    switch result {
    case let .failure(error):
      return error
    default:
      XCTFail("Expected failure, got \(result) instead", file: file, line: line)
      return nil
    }
  }

  private func makeSampleResponse(data: Data?, response: URLResponse?, error: Error?) -> EndpointSampleResponse {
    switch (data, response, error) {
    case let (.some(data), .none, .none):
      return .networkResponse(200, data)
    case let (.some(data), .some(response as HTTPURLResponse), .none):
      return .response(response, data)
    case let (_, _, .some(error)):
      return .networkError(error as NSError)
    default:
      return .networkError(anyNSError())
    }
  }

  private func resultFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> HTTPClientResult {
    let endpoint = makeEndpointClosure(data: data, response: response, error: error)
    let sut = makeSUT(endpointClosure: endpoint)
    let exp = expectation(description: "Wait for completion")

    var receivedResult: HTTPClientResult!
    sut.get(from: .feed) { result in
      receivedResult = result
      exp.fulfill()
    }

    wait(for: [exp], timeout: 1.0)
    return receivedResult
  }

  private func nonHTTPURLResponse() -> URLResponse {
    return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
  }

  private func anyHTTPURLResponse() -> HTTPURLResponse {
    return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
  }
}
