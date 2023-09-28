struct ChatRoomsEmptyViewState {
    let contactsOnMega: ChatRoomsTopRowViewState?
    let archivedChats: ChatRoomsTopRowViewState?
    
    let centerImageResource: ImageResource
    let centerTitle: String
    let centerDescription: String?

    let bottomButtonTitle: String?
    let bottomButtonAction: (() -> Void)?
    
    let bottomButtonMenus: [ChatRoomsEmptyBottomButtonMenu]?
}

struct ChatRoomsEmptyBottomButtonMenu {
    let name: String
    let image: ImageResource
    let action: () -> Void
}

extension ChatRoomsEmptyBottomButtonMenu: Identifiable {
    var id: String {
        name
    }
}
