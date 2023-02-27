import MEGADomain

@objc final class SharedItemsViewModel: NSObject {
    
    private let router = SharedItemsViewRouter()
    private let shareUseCase: ShareUseCaseProtocol
    
    init(shareUseCase: ShareUseCaseProtocol) {
        self.shareUseCase = shareUseCase
    }

    func openShareFolderDialog(forNodes nodes: [MEGANode]) {
        Task { @MainActor [shareUseCase] in
            do {
                let _ = try await shareUseCase.createShareKeys(forNodes: nodes.toNodeEntities())
                router.showShareFoldersContactView(withNodes: nodes)
            } catch {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
        }
    }
    
    @objc func showPendingOutShareModal(for email: String) {
        router.showPendingOutShareModal(for: email)
    }
}