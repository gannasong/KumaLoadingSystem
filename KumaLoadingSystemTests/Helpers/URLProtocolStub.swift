//
//  URLProtocolStub.swift
//  KumaLoadingSystemTests
//
//  Created by SUNG HAO LIN on 2021/10/27.
//

import Foundation

final class URLProtocolStub: URLProtocol {
  private static var stub: Stub?
  private static var requestObserver: ((URLRequest) -> Void)?

  private struct Stub {
    let data: Data?
    let response: URLResponse?
    let error: Error?
  }

  static func stub(data: Data?, response: URLResponse?, error: Error?) {
    stub = Stub(data: data, response: response, error: error)
  }

  static func observeRequests(observer: @escaping (URLRequest) -> Void) {
    requestObserver = observer
  }

  static func startInterceptingRequests() {
    URLProtocol.registerClass(URLProtocolStub.self)
  }

  static func stopInterceptingRequests() {
    URLProtocol.unregisterClass(URLProtocolStub.self)
    stub = nil
    requestObserver = nil
  }

  override class func canInit(with request: URLRequest) -> Bool {
    return true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    return request
  }

  override func startLoading() {
    // Finish URL loading when observing requests to make sure all URL requests are finished before the test method returns.
    // This way, we prevent data races with threads living longer than the test method that initiated them.
    if let requestObserver = URLProtocolStub.requestObserver {
      client?.urlProtocolDidFinishLoading(self)
      return requestObserver(request)
    }

    if let data = URLProtocolStub.stub?.data {
      client?.urlProtocol(self, didLoad: data)
    }

    if let response = URLProtocolStub.stub?.response {
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    }

    if let error = URLProtocolStub.stub?.error {
      client?.urlProtocol(self, didFailWithError: error)
    }

    client?.urlProtocolDidFinishLoading(self)
  }

  override func stopLoading() {}
}
