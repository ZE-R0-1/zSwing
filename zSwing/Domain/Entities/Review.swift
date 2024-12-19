//
//  Review.swift
//  zSwing
//
//  Created by USER on 12/19/24.
//

import Foundation

struct Review: Codable {
    let id: String
    let playgroundId: String
    let userId: String
    let content: String
    let rating: Double
    let imageUrls: [String]
    let createdAt: Date
    let updatedAt: Date
    
    var likeCount: Int
    var isLiked: Bool
    var userName: String
    var userProfileUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case playgroundId
        case userId
        case content
        case rating
        case imageUrls
        case createdAt
        case updatedAt
        case likeCount
        case isLiked
        case userName
        case userProfileUrl
    }
}
