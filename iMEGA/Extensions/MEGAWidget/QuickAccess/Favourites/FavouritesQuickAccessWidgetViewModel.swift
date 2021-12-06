import Foundation
import SwiftUI

final class FavouritesQuickAccessWidgetViewModel: ViewModelType {
    
    enum Command: CommandType, Equatable {
        case reloadWidget
    }

    // MARK: - Private properties
    private let authUseCase: AuthUseCaseProtocol
    private let copyDataBasesUseCase: CopyDataBasesUseCaseProtocol
    private let favouriteItemsUseCase: FavouriteItemsUseCaseProtocol
    
    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?

    init(authUseCase: AuthUseCaseProtocol, copyDataBasesUseCase: CopyDataBasesUseCaseProtocol, favouriteItemsUseCase: FavouriteItemsUseCaseProtocol) {
        self.authUseCase = authUseCase
        self.copyDataBasesUseCase = copyDataBasesUseCase
        self.favouriteItemsUseCase = favouriteItemsUseCase
    }
    
    var status: WidgetStatus = .notConnected { didSet { invokeCommand?(.reloadWidget) } }
    
    // MARK: - Dispatch action
    func dispatch(_ action: QuickAccessWidgetAction) {
        switch action {
        case .onWidgetReady:
            status = .notConnected
            connectWidgetExtension()
        }
    }
    
    func fetchFavouriteItems() -> EntryValue {
        if authUseCase.sessionId() != nil {
            let items = favouriteItemsUseCase.fetchFavouriteItems(upTo: MEGAQuickAccessWidgetMaxDisplayItems).map {
                QuickAccessItemModel(thumbnail: imageForPatExtension(URL(fileURLWithPath: $0.name).pathExtension), name: $0.name, url: URL(string: SectionDetail.favourites.link)?.appendingPathComponent($0.base64Handle), image: nil, description: nil)
            }
            return (items, .connected)
        } else {
            return ([], .noSession)
        }
    }
    
    //MARK: -Private
    
    private func imageForPatExtension(_ pathExtension: String) -> Image {
        if pathExtension != "" {
            return Image(FileTypes().allTypes[pathExtension] ?? "generic")
        } else {
            return Image("folder")
        }
    }
    
    private func updateStatus(_ newStatus: WidgetStatus) {
        if status != newStatus {
            status = newStatus
        }
    }
    
    private func connectWidgetExtension() {
        if status == .connecting {
            return
        }
        self.updateStatus(.connecting)

        copyDataBasesUseCase.copyFromMainApp { (result) in
            switch result {
            case .success(_):
                self.updateStatus(.connected)
            case .failure(_):
                self.updateStatus(.error)
            }
        }
    }
}
