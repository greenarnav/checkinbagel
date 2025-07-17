//
//  ChatStorage.swift
//  moodgpt
//
//  Created by Test on 5/27/25.
//

import SwiftUI

class ChatStorage: ObservableObject {
    @Published private var messagesByContact: [String: [ChatMessage]] = [:]
    
    func addMessage(_ message: ChatMessage, for contactName: String) {
        if messagesByContact[contactName] == nil {
            messagesByContact[contactName] = []
        }
        messagesByContact[contactName]?.append(message)
    }
    
    func getMessages(for contactName: String) -> [ChatMessage] {
        return messagesByContact[contactName] ?? []
    }
} 