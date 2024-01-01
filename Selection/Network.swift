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
    case getUsers(gender: ViewControllerReactor.Gender)
}

extension RandomUserService: TargetType {
    var baseURL: URL { return URL(string: "https://randomuser.me")! }
    
    var path: String {
        switch self {
        case .getUsers:
            return "/api/?results=14"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .getUsers:
            return .get
        }
    }
    
    var task: Task {
            switch self {
            case .getUsers(let gender):
                return .requestParameters(
                    parameters: ["gender": gender.stringValue, "inc": "gender,name,email,location","results":"14"],
                    encoding: URLEncoding.queryString
                )
            }
        }
    var headers: [String : String]? {
        return ["Content-type": "application/json"]
    }
}

