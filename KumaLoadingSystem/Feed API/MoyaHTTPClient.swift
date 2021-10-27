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

  private struct UnexpectedValuesRepresentation: Error {}

  public func get(from api: TmdbAPI, completion: @escaping (HTTPClientResult) -> Void) {
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
