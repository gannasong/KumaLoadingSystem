//
//  TmdbAPI.swift
//  KumaLoadingSystem
//
//  Created by SUNG HAO LIN on 2021/10/26.
//

import Foundation
import Moya

public enum TmdbAPI {
  case feed
}

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

  public var sampleData: Data {
    return "{}".data(using: String.Encoding.utf8)!
  }
  
  private var parameters: [String: Any]? {
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
    guard let parameters = parameters else {
      return .requestPlain
    }

    switch self {
    case .feed:
      return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
    }
  }

  public var headers: [String : String]? {
    return ["Content-type": "application/json"]
  }
}
