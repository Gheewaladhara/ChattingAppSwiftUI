//
//  ChatMessage.swift
//  SwiftUIChat
//
//  Created by GHEEWALA DHARA on 03/06/24.
//

import Foundation

struct ChatMessage: Codable, Identifiable {
    
    var id: String { documentId }
    
    let documentId : String
    let fromId, toId, text: String
    
    init(documentId : String, data : [String : Any]) {
        self.documentId = documentId
        self.fromId = data[FireBaseConstants.fromId] as? String ?? ""
        self.toId = data[FireBaseConstants.toId] as? String ?? ""
        self.text = data[FireBaseConstants.text ] as? String ?? ""
        
    }
    
}
