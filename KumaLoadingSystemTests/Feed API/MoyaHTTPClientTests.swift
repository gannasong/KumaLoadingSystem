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

  func test_getFromTarget_performsGETRequestWithEndpoint() {
    let endpoint = makeEndpointClosure(target: .feed, data: anyData())
    let (sut, interceptingSpy) = makeSUT(endpointClosure: endpoint)
    let feedURL = feedURL()
    let exp = expectation(description: "Wait for request")

    interceptingSpy.observeRequests { request in
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

    // responseError
    XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
    XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: nil))
    XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil))
    // responseError
    XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: nil))
    XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
  }

  // MARK: - Helpers

  private func makeSUT(endpointClosure: @escaping ((TmdbAPI) -> Endpoint), file: StaticString = #file, line: UInt = #line) -> (sut: HTTPClient, interceptingSpy: MoyaInterceptingSpy) {
    let interceptingSpy = MoyaInterceptingSpy()
    let provider = MoyaProvider<TmdbAPI>(endpointClosure: endpointClosure, stubClosure: MoyaProvider.immediatelyStub, plugins: [interceptingSpy])
    let sut = MoyaHTTPClient(provider: provider)
    trackForMemoryLeaks(sut, file: file, line: line)
    trackForMemoryLeaks(interceptingSpy, file: file, line: line)
    return (sut, interceptingSpy)
  }

  private func makeEndpointClosure(target: TmdbAPI = .feed, statusCode: Int = 200, data: Data) -> (TmdbAPI) -> Endpoint {
    return { (target: TmdbAPI) -> Endpoint in
      return Endpoint(url: URL(target: target).absoluteString,
                      sampleResponseClosure: { .networkResponse(statusCode , data) },
                      method: target.method,
                      task: target.task,
                      httpHeaderFields: target.headers)
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

  private func resultFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> HTTPClientResult {
    let endpoint = makeEndpointClosure(target: .feed, data: anyData())
    let (sut, interceptingSpy) = makeSUT(endpointClosure: endpoint)
    interceptingSpy.stub(data: data, response: response, error: error)
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

  private class MoyaInterceptingSpy: PluginType {
    private var stub: Stub?
    private var requestObserver: ((URLRequest) -> Void)?

    private struct Stub {
      let data: Data?
      let response: URLResponse?
      let error: Error?
    }

    func stub(data: Data?, response: URLResponse?, error: Error?) {
      stub = Stub(data: data, response: response, error: error)
    }

    func observeRequests(observer: @escaping (URLRequest) -> Void) {
      requestObserver = observer
    }

    // 發送請求前調用，可以用來對 URLRequest 進行修改
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
      return request
    }

    // 發送請求前最後調用的方法，不管是插樁測試還是真正的網絡請求都會調用這個方法
    func willSend(_ request: RequestType, target: TargetType) {
      if let request = request.request {
        requestObserver?(request)
      }
    }

    // 接收到響應結果時調用，會先調用該方法後再調用 MoyaProvider 調用自己的 completionHandler
    func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {}

    // 響應結果的預處理器
    func process(_ result: Result<Response, MoyaError>, target: TargetType) -> Result<Response, MoyaError> {
      if let error = stub?.error {
        return .failure(.underlying(error, nil))
      }

      return result
    }
  }
}
