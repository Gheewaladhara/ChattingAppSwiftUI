//
//  RecentUser.swift
//  SwiftUIChat
//
//  Created by GHEEWALA DHARA on 03/06/24.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

struct RecentMessage: Codable, Identifiable {
    
//    var id: String { documentId }
    @DocumentID var id: String?
    
//    let documentId : String
    let text, email : String
    let fromId, toId : String
    let profileImageUrl: String
    let timestamp: Date
    
//    init(documentId: String, data: [String : Any]) {
//        self.documentId = documentId
//        self.text = data["text"] as? String ?? ""
//        self.email = data["email"] as? String ?? ""
//        self.fromId = data["fromId"] as? String ?? ""
//        self.toId = data["toId"] as? String ?? ""
//        self.profileImageUrl = data["profileImageUrl"] as? String ?? ""
//        self.timestamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date())
//    }
    
    var username: String{
        email.components(separatedBy: "@").first ?? email
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    
}

