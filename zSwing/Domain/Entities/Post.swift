//
//  Post.swift
//  zSwing
//
//  Created by USER on 1/10/25.
//

import Foundation

struct Post: Codable {
    let id: String
    let content: String
    let createdAt: Date
    let imageUrls: [String]
    var likeCount: Int
    let rating: Double
    let updatedAt: Date
    let userId: String
    let userName: String
    var isLiked: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case content
        case createdAt
        case imageUrls
        case likeCount
        case rating
        case updatedAt
        case userId
        case userName
        case isLiked
    }
}
