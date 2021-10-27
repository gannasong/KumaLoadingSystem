//
//  MoyaHTTPClientTests.swift
//  KumaLoadingSystemTests
//
//  Created by SUNG HAO LIN on 2021/10/26.
//

import XCTest
import KumaLoadingSystem
import Moya

class MoyaHTTPClient: HTTPClient {
  private let provider: MoyaProvider<TmdbAPI>

  init(provider: MoyaProvider<TmdbAPI>) {
    self.provider = provider
  }

  private struct UnexpectedValuesRepresentation: Error {}

  func get(from api: TmdbAPI, completion: @escaping (HTTPClientResult) -> Void) {
    // provider return cancelable
    provider.request(api) { result in
      switch result {
      case let .success(moyaResponse):
        if let response = moyaResponse.response {
          completion(.success(moyaResponse.data, response))
        } else {
          completion(.failure(UnexpectedValuesRepresentation()))
        }
      case .failure:
        completion(.failure(UnexpectedValuesRepresentation()))
      }
    }
  }
}

class MoyaHTTPClientTests: XCTestCase {

  func test_getFromURL_performsGETRequestWithEndpoint() {
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

  private class MoyaInterceptingSpy: PluginType {
    private var requestObserver: ((URLRequest) -> Void)?

    func observeRequests(observer: @escaping (URLRequest) -> Void) {
      requestObserver = observer
    }

    // 發送請求前調用，可以用來對 URLRequest 進行修改
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
      print(">>>>> 11111")
      return request
    }

    // 發送請求前最後調用的方法，不管是插樁測試還是真正的網絡請求都會調用這個方法
    func willSend(_ request: RequestType, target: TargetType) {
      if let request = request.request {
        requestObserver?(request)
      }
      print(">>>>> 22222")
    }

    // 接收到響應結果時調用，會先調用該方法後再調用 MoyaProvider 調用自己的 completionHandler
    func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
      print(">>>>> 33333")
    }

    // 響應結果的預處理器
    func process(_ result: Result<Response, MoyaError>, target: TargetType) -> Result<Response, MoyaError> {
      print(">>>>> 44444")
      return result
    }
  }

  //  private class URLProtocolStub: URLProtocol {
  //    private static var stub: Stub?
  //    private static var requestObserver: ((URLRequest) -> Void)?
  //
  //    private struct Stub {
  //      let data: Data?
  //      let response: URLResponse?
  //      let error: Error?
  //    }
  //
  //    static func stub(data: Data?, response: URLResponse?, error: Error?) {
  //      stub = Stub(data: data, response: response, error: error)
  //    }
  //
  //    static func observeRequests(observer: @escaping (URLRequest) -> Void) {
  //      requestObserver = observer
  //    }
  //
  //    static func startInterceptingRequests() {
  //      URLProtocol.registerClass(URLProtocolStub.self)
  //    }
  //
  //    static func stopInterceptingRequests() {
  //      URLProtocol.unregisterClass(URLProtocolStub.self)
  //      stub = nil
  //      requestObserver = nil
  //    }
  //
  //    override class func canInit(with request: URLRequest) -> Bool {
  //      return true
  //    }
  //
  //    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
  //      return request
  //    }
  //
  //    override func startLoading() {
  //      // Finish URL loading when observing requests to make sure all URL requests are finished before the test method returns.
  //      // This way, we prevent data races with threads living longer than the test method that initiated them.
  //      if let requestObserver = URLProtocolStub.requestObserver {
  //        client?.urlProtocolDidFinishLoading(self)
  //        return requestObserver(request)
  //      }
  //
  //      if let data = URLProtocolStub.stub?.data {
  //        client?.urlProtocol(self, didLoad: data)
  //      }
  //
  //      if let response = URLProtocolStub.stub?.response {
  //        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
  //      }
  //
  //      if let error = URLProtocolStub.stub?.error {
  //        client?.urlProtocol(self, didFailWithError: error)
  //      }
  //
  //      client?.urlProtocolDidFinishLoading(self)
  //    }
  //
  //    override func stopLoading() {}
  //  }
}
