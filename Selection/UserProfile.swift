//
//  UserProfile.swift
//  Selection
//
//  Created by 김정원 on 12/29/23.
//

import Foundation
import UIKit
import Moya

struct UserResponse: Decodable {
    let results: [User]
}

struct User: Decodable, Hashable {
    let gender: String
    let email: String
    let name: Name
    let location: Location
    let picture : Picture

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
    struct Picture: Decodable, Hashable {
        let thumbnail: String
        let medium : String
        let large : String
    }
}
