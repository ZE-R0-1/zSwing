//
//  UserDTO.swift
//  zSwing
//
//  Created by USER on 11/5/24.
//

import Foundation
import FirebaseFirestore

struct UserDTO: Codable {
    var id: String
    let email: String
    let loginMethod: String
    let createdAt: Timestamp
    let lastAccessDate: Timestamp?
    let nickname: String?
    
    enum CodingKeys: String, CodingKey {
        case email
        case loginMethod
        case createdAt
        case lastAccessDate
        case nickname
    }
    
    // Decodable 프로토콜을 만족시키기 위한 기본 이니셜라이저
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // id는 나중에 설정할 수 있도록 임시값 할당
        self.id = ""
        self.email = try container.decode(String.self, forKey: .email)
        self.loginMethod = try container.decode(String.self, forKey: .loginMethod)
        self.createdAt = try container.decode(Timestamp.self, forKey: .createdAt)
        self.lastAccessDate = try container.decodeIfPresent(Timestamp.self, forKey: .lastAccessDate)
        self.nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
    }
    
    // ID를 설정하기 위한 mutating 메서드
    mutating func setDocumentId(_ documentId: String) {
        self.id = documentId
    }
    
    // 일반 이니셜라이저
    init(id: String, email: String, loginMethod: String, createdAt: Timestamp, lastAccessDate: Timestamp? = nil, nickname: String? = nil) {
        self.id = id
        self.email = email
        self.loginMethod = loginMethod
        self.createdAt = createdAt
        self.lastAccessDate = lastAccessDate
        self.nickname = nickname
    }
    
    func toDomain() -> User {
        return User(
            id: id,
            email: email,
            loginMethod: LoginMethod(rawValue: loginMethod) ?? .google
        )
    }
}

// MARK: - Firestore Document Initialization
extension UserDTO {
    // Firestore 문서 데이터로부터 초기화
    init?(dictionary: [String: Any]) {
        guard let email = dictionary["email"] as? String,
              let loginMethod = dictionary["loginMethod"] as? String,
              let createdAt = dictionary["createdAt"] as? Timestamp else {
            return nil
        }
        
        self.id = dictionary["id"] as? String ?? ""
        self.email = email
        self.loginMethod = loginMethod
        self.createdAt = createdAt
        self.lastAccessDate = dictionary["lastAccessDate"] as? Timestamp
        self.nickname = dictionary["nickname"] as? String
    }
    
    // Firestore 문서 데이터로 변환
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "email": email,
            "loginMethod": loginMethod,
            "createdAt": createdAt
        ]
        
        if let lastAccessDate = lastAccessDate {
            dict["lastAccessDate"] = lastAccessDate
        }
        
        if let nickname = nickname {
            dict["nickname"] = nickname
        }
        
        return dict
    }
}
