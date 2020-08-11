import MessageKit

struct User: SenderType {
    var senderId: String
    var displayName: String
}

struct ChatMessage {
    let message: MEGAChatMessage
    let chatRoom: MEGAChatRoom
    var transfer: MEGATransfer?
    init(message: MEGAChatMessage, chatRoom: MEGAChatRoom) {
        self.message = message
        self.chatRoom = chatRoom
    }
    
    init(transfer: MEGATransfer, chatRoom: MEGAChatRoom) {
        self.message = MEGAChatMessage()
        self.transfer = transfer
        self.chatRoom = chatRoom
    }
    
 
}

extension ChatMessage: MessageType {
    var sender: SenderType {
        return self
    }

    var messageId: String {
        return String(format: "%llu", message.messageId)
    }

    var sentDate: Date {
        guard let timestamp = message.timestamp else {
            return Date()
        }
        return timestamp
    }
    
    var kind: MessageKind {
        
        message.generateAttributedString()
        
        switch message.type {
        case .callEnded, .callStarted, .attachment, .containsMeta, .contact, .voiceClip, .normal:
            return .custom(message)
        default:
            break
        }
        
        if message.isManagementMessage {
            return .custom(message)
        }
        
        if transfer?.transferChatMessageType() == .voiceClip || transfer?.transferChatMessageType() == .attachment {
            return .custom(message)
        }
        
        return .text("")
    }
}

extension ChatMessage: SenderType {
    var senderId: String {
        if message.isManagementMessage {
            return "0"
        }
        if transfer != nil {
            return String(format: "%llu", MEGASdkManager.sharedMEGAChatSdk()!.myUserHandle)
        }
        
        return String(format: "%llu", message.userHandle)
    }

    var displayName: String {
        //        fix me

        return ""
//        return chatRoom.userDisplayName(forUserHandle: message.userHandle) ?? chatRoom.peerEmail(byHandle: message.userHandle) ?? ""
    }
}

extension ChatMessage: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(message.messageId)
    }
}

extension ChatMessage: Comparable {
    static func < (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.message.messageIndex < rhs.message.messageIndex
    }
}
