//
//  TmdbAPI+TargetType.swift
//  KumaLoadingSystem
//
//  Created by SUNG HAO LIN on 2021/10/28.
//

import Foundation
import Moya

extension TmdbAPI: TargetType {
  public var baseURL: URL {
    return URL(string: "https://api.themoviedb.org")!
  }

  public var path: String {
    switch self {
    case .feed:
      return "/3/discover/movie"
    }
  }

  public var method: Moya.Method {
    return .get
  }

  private var parameters: [String: Any] {
    var parameters: [String: Any] = [:]
    switch self {
    case .feed:
      parameters = [
        "language": "zh-TW",
        "page": 1,
        "sort_by": "popularity.desc",
        "api_key": "61c433b8fef1ba8a3d8a518ce6f02576"
      ]
    }
    return parameters
  }

  public var task: Task {
    switch self {
    case .feed:
      return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
    }
  }

  public var headers: [String : String]? {
    return ["Content-type": "application/json"]
  }
}
