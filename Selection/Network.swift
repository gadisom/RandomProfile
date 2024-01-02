//
//  Network.swift
//  Selection
//
//  Created by 김정원 on 12/28/23.
//


import RxCocoa
import RxSwift
import Foundation
import Moya

enum RandomUserService {
    case getMenUsers
    case getWomenUsers
}

extension RandomUserService: TargetType {
    var baseURL: URL { return URL(string: "https://randomuser.me")! }
    
    var path: String {
        return "/api"
    }
    
    var method: Moya.Method {
        return .get
    }
    
    var task: Task {
        switch self {
        case .getMenUsers:
            return .requestParameters(
                parameters: ["gender": "male", "inc": "gender,name,email,location,picture", "results": 14],
                encoding: URLEncoding.queryString
            )
        case .getWomenUsers:
            return .requestParameters(
                parameters: ["gender": "female", "inc": "gender,name,email,location,picture", "results": 14],
                encoding: URLEncoding.queryString
            )
        }
    }
    
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}
