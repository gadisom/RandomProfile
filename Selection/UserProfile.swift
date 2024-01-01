//
//  UserProfile.swift
//  Selection
//
//  Created by 김정원 on 12/29/23.
//

import Foundation
import UIKit
import Moya

struct RandomUserResponse: Decodable {
    let results: [RandomUser]
}

struct RandomUser: Decodable, Hashable {
    let gender: String
    let email: String
    let name: Name
    let location: Location

    struct Name: Decodable, Hashable {
        let title: String
        let first: String
        let last: String

        var fullName: String {
            return "\(title) \(first) \(last)"
        }
    }

    struct Location: Decodable, Hashable {
        let country: String
    }
}
