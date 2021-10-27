//
//  MoyaHTTPClient.swift
//  KumaLoadingSystem
//
//  Created by SUNG HAO LIN on 2021/10/27.
//

import Foundation
import Moya

public final class MoyaHTTPClient: HTTPClient {
  private let provider: MoyaProvider<TmdbAPI>

  public init(provider: MoyaProvider<TmdbAPI>) {
    self.provider = provider
  }

  public enum Error: Swift.Error {
    case requestError
    case responseError
  }

  public func get(from api: TmdbAPI, completion: @escaping (HTTPClientResult) -> Void) {
    // provider return cancelable
    provider.request(api) { result in
      switch result {
      case let .success(moyaResponse):
        if let response = moyaResponse.response {
          completion(.success(moyaResponse.data, response))
        } else {
          // Moya 先處理好 Error，所以當 statusCode 是 200 時，Stub Error case 會走這邊
          completion(.failure(Error.responseError))
        }
      case .failure:
        completion(.failure(Error.requestError))
      }
    }
  }
}
