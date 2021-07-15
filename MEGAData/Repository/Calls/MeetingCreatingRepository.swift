import Foundation

final class MeetingCreatingRepository: NSObject, MEGAChatDelegate, MeetingCreatingRepositoryProtocol {
    
    private let chatSdk = MEGASdkManager.sharedMEGAChatSdk()
    private let sdk = MEGASdkManager.sharedMEGASdk()
    private var chatResultDelegate: MEGAChatResultDelegate?
    
    func getUsername() -> String {
        let user = MEGAStore.shareInstance().fetchUser(withEmail: sdk.myEmail)
        if let userName = user?.displayName,
            userName.count > 0 {
            return userName
        }
        
        return chatSdk.userFullnameFromCache(byUserHandle:  sdk.myUser?.handle ?? 0) ?? ""

    }
    
    func getCall(forChatId chatId: UInt64) -> CallEntity? {
        guard let call = chatSdk.chatCall(forChatId: chatId) else { return nil }
        return CallEntity(with: call)
    }
    
    func createChatLink(forChatId chatId: UInt64) {
        chatSdk.createChatLink(chatId)
    }
    
    func startChatCall(meetingName: String, enableVideo: Bool, enableAudio: Bool,  completion: @escaping (Result<ChatRoomEntity, CallsErrorEntity>) -> Void) {
        let delegate = MEGAChatGenericRequestDelegate { [weak self] (request, error) in
            guard let self = self else { return }
            guard let chatroom = self.chatSdk.chatRoom(forChatId: request.chatHandle) else {
                MEGALogDebug("ChatRoom not found with chat handle \(MEGASdk.base64Handle(forUserHandle: request.chatHandle) ?? "-1")")
                return
            }
            
            let startCallDelegate: MEGAChatRequestDelegate = MEGAChatStartCallRequestDelegate { [weak self] (chatError) in
                if chatError?.type == .MEGAChatErrorTypeOk {
                    guard (self?.chatSdk.chatCall(forChatId: request.chatHandle)) != nil else {
                        completion(.failure(.generic))
                        return
                    }
                    completion(.success(ChatRoomEntity(with: chatroom)))
                } else {
                    completion(.failure(.generic))
                }
            }
            
            CallActionManager.shared.startCall(chatId: chatroom.chatId, enableVideo: enableVideo, enableAudio: enableAudio, delegate: startCallDelegate)
        }
        
        chatSdk.createMeeting(withTitle: meetingName, delegate: delegate)
    }

    func joinChatCall(forChatId chatId: UInt64, enableVideo: Bool, enableAudio: Bool, userHandle: UInt64, completion: @escaping (Result<ChatRoomEntity, CallsErrorEntity>) -> Void) {
        let delegate = MEGAChatGenericRequestDelegate { [weak self] (request, error) in
            guard let self = self, let megaChatRoom = self.chatSdk.chatRoom(forChatId: request.chatHandle) else {
                MEGALogDebug("ChatRoom not found with chat handle \(MEGASdk.base64Handle(forUserHandle: request.chatHandle) ?? "-1")")
                completion(.failure(.generic))
                return
            }

            let chatRoom = ChatRoomEntity(with: megaChatRoom)
            MEGALogDebug("Create meeting: Answer call with chatroom id \(MEGASdk.base64Handle(forUserHandle: chatRoom.chatId) ?? "-1")")
            self.answerCall(for: chatRoom, enableVideo: enableVideo, enableAudio: enableAudio, completion: completion)
        }
        
        if let megaChatRoom = self.chatSdk.chatRoom(forChatId: chatId),
           !megaChatRoom.isPreview,
           !megaChatRoom.isActive {            
            chatSdk.autorejoinPublicChat(chatId, publicHandle: userHandle, delegate: delegate)
        } else {
            MEGALogDebug("Create meeting: Autojoin public chat with chatId - \(MEGASdk.base64Handle(forUserHandle: chatId) ?? "-1")")
            chatSdk.autojoinPublicChat(chatId, delegate: delegate)
        }
        
    }
    
    func checkChatLink(link: String, completion: @escaping (Result<ChatRoomEntity, CallsErrorEntity>) -> Void) {
        guard let url = URL(string: link) else {
            completion(.failure(.generic))
            return
        }
        
        MEGALogDebug("Create meeting: check chat link \(link)")
        chatSdk.checkChatLink(url, delegate: MEGAChatGenericRequestDelegate(completion: { [weak self] (request, error) in
          
            guard (error.type == .MEGAChatErrorTypeOk || error.type == .MegaChatErrorTypeExist) else {
                MEGALogDebug("Create meeting: failed to check chat link \(link)")
                completion(.failure(.generic))
                return
            }
            
            guard let chatroom = self?.chatSdk.chatRoom(forChatId: request.chatHandle) else {
                MEGALogDebug("Create meeting: ChatRoom not found with chat handle \(request.chatHandle)")
                completion(.failure(.generic))
                return
            }
            
            MEGALogDebug("Create meeting: check chat link succeded with chatroom \(chatroom)")
            completion(.success(ChatRoomEntity(with: chatroom)))
        }))
    }
    
    func createEphemeralAccountAndJoinChat(firstName: String, lastName: String, link: String, completion: @escaping (Result<Void, MEGASDKErrorType>) -> Void, karereInitCompletion: @escaping () -> Void) {
        MEGALogDebug("Create meeting: Now logging out of anonymous account")
        chatSdk.logout(with: MEGAChatResultRequestDelegate(completion: { (result) in
            switch result {
            case .success(_):
                self.chatSdk.initKarere(withSid: nil)
                karereInitCompletion()
                MEGALogDebug("Create meeting: Now creating ephemeral account plus plus with firstname - \(firstName) and lastname - \(lastName)")
                self.sdk.createEphemeralAccountPlusPlus(withFirstname: firstName, lastname: lastName, delegate: MEGAResultRequestDelegate { (result) in
                    switch result {
                    case .failure(let errorType):
                        MEGALogDebug("Create meeting: failed creating ephemeral account plus plus with error \(errorType)")
                        completion(.failure(errorType))
                    case .success(let request):
                        MEGALogDebug("Create meeting: success creating ephemeral account plus plus")
                        if request.paramType == AccountActionType.resumeEphemeralPlusPlus.rawValue {
                            MEGALogDebug("Create meeting: Now fetching node for ephemeral account")
                            self.sdk.fetchNodes(with: RequestDelegate(completion: { (result) in
                                switch result {
                                case .success(_):
                                    MEGALogDebug("Create meeting: success fetching node for ephemeral account and now connecting to chat")
                                    self.connectToChat(link: link, request: request, completion: completion)
                                case .failure(let error):
                                    MEGALogDebug("Create meeting: failure fetching node for ephemeral account \(error)")
                                    completion(.failure(.unexpected))
                                }
                            }))
                        } else {
                            self.connectToChat(link: link, request: request, completion: completion)
                        }
                    }
                })
            case .failure(let error):
                MEGALogDebug("Create meeting: failed to logout of anonymous account \(error)")
                completion(.failure(.unexpected))
            }
            
        }))
    }
    
    private func connectToChat(link: String, request: MEGARequest, completion: @escaping (Result<Void, MEGASDKErrorType>) -> Void) {
        guard let url = URL(string: link) else {
            MEGALogDebug("Create meeting: invalid url \(link)")
            completion(.failure(.unexpected))
            return
        }
        
        MEGALogDebug("Create meeting: connect to chat with link \(link) and request \(request)")
        self.chatSdk.connect(with: MEGAChatResultRequestDelegate(completion: { _  in
            MEGALogDebug("Create meeting: open chat preview for url \(url)")
            self.chatSdk.openChatPreview(url, delegate: MEGAChatResultRequestDelegate(completion: { [weak self] in
                switch $0 {
                case .success(let chatRequest):
                    MEGALogDebug("Create meeting: open chat preview succeeded with request \(chatRequest)")
                    self?.chatResultDelegate = MEGAChatResultDelegate(completion: { (sdk, chatId, newState) in
                        if chatRequest.chatHandle == chatId, newState == .online {
                            self?.chatSdk.remove(self?.chatResultDelegate)
                            completion(.success(()))
                        }
                    })
                    self?.chatSdk.add(self?.chatResultDelegate)
                case .failure(let error):
                    MEGALogDebug("Create meeting: open chat preview failure \(error)")
                    completion(.failure(.unexpected))
                }
            }))
        }))
    }
    
    private func answerCall(for chatRoom: ChatRoomEntity, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<ChatRoomEntity, CallsErrorEntity>) -> Void) {
        MEGALogDebug("Create meeting: Answer call with chatroom id \(MEGASdk.base64Handle(forUserHandle: chatRoom.chatId) ?? "-1")")
        let answerCallDelegate: MEGAChatRequestDelegate =  MEGAChatAnswerCallRequestDelegate { [weak self] (chatError) in
            guard let self = self else { return }
            
            if chatError?.type == .MEGAChatErrorTypeOk {
                guard self.chatSdk.chatCall(forChatId: chatRoom.chatId) != nil else {
                    MEGALogDebug("Create meeting: not able to find call with chat id \(MEGASdk.base64Handle(forUserHandle: chatRoom.chatId) ?? "-1")")
                    completion(.failure(.generic))
                    return
                }
                
                MEGALogDebug("Create meeting: success to answer call with chatroom id \(MEGASdk.base64Handle(forUserHandle: chatRoom.chatId) ?? "-1")")
                completion(.success(chatRoom))
            } else {
                MEGALogDebug("Create meeting: failed to answer call with chatroom id \(MEGASdk.base64Handle(forUserHandle: chatRoom.chatId) ?? "-1")")
                completion(.failure(.generic))
            }
        }
        
        CallActionManager.shared.answerCall(chatId: chatRoom.chatId, enableVideo: enableVideo, enableAudio: enableAudio, delegate: answerCallDelegate)
    }
}
