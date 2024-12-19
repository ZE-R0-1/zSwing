//
//  ReviewDTO.swift
//  zSwing
//
//  Created by USER on 12/19/24.
//

import Foundation
import FirebaseCore

struct ReviewDTO: Decodable {
    let id: String
    let playgroundId: String
    let userId: String
    let content: String
    let rating: Double
    let imageUrls: [String]
    let createdAt: Timestamp
    let updatedAt: Timestamp
    let likeCount: Int
    let userName: String
    let userProfileUrl: String?
    
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
        case userName
        case userProfileUrl
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(String.self, forKey: .id)
        self.playgroundId = try container.decode(String.self, forKey: .playgroundId)
        self.userId = try container.decode(String.self, forKey: .userId)
        self.content = try container.decode(String.self, forKey: .content)
        self.rating = try container.decode(Double.self, forKey: .rating)
        self.imageUrls = try container.decode([String].self, forKey: .imageUrls)
        self.createdAt = try container.decode(Timestamp.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Timestamp.self, forKey: .updatedAt)
        self.likeCount = try container.decode(Int.self, forKey: .likeCount)
        self.userName = try container.decode(String.self, forKey: .userName)
        self.userProfileUrl = try container.decodeIfPresent(String.self, forKey: .userProfileUrl)
    }
    
    func toDomain() -> Review {
        return Review(
            id: id,
            playgroundId: playgroundId,
            userId: userId,
            content: content,
            rating: rating,
            imageUrls: imageUrls,
            createdAt: createdAt.dateValue(),
            updatedAt: updatedAt.dateValue(),
            likeCount: likeCount,
            isLiked: false,  // Firebase에서 별도로 조회 필요
            userName: userName,
            userProfileUrl: userProfileUrl
        )
    }
}
