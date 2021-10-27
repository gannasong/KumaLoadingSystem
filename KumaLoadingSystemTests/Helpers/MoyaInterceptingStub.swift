//
//  MoyaInterceptingStub.swift
//  KumaLoadingSystemTests
//
//  Created by SUNG HAO LIN on 2021/10/27.
//

import Foundation
import Moya

final class MoyaInterceptingStub: PluginType {
  private static var requestObserver: ((URLRequest) -> Void)?

  static func observeRequests(observer: @escaping (URLRequest) -> Void) {
    requestObserver = observer
  }

  static func stopInterceptingRequests() {
    requestObserver = nil
  }

  // 發送請求前調用，可以用來對 URLRequest 進行修改
  func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
    return request
  }

  // 發送請求前最後調用的方法，不管是插樁測試還是真正的網絡請求都會調用這個方法
  func willSend(_ request: RequestType, target: TargetType) {
    if let request = request.request {
      MoyaInterceptingStub.requestObserver?(request)
    }
  }

  // 接收到響應結果時調用，會先調用該方法後再調用 MoyaProvider 調用自己的 completionHandler
  func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {}

  // 響應結果的預處理器
  func process(_ result: Result<Response, MoyaError>, target: TargetType) -> Result<Response, MoyaError> {
    return result
  }
}
