import UIKit

@available(iOS 14.0, *)
protocol AlbumToolbarProvider {
    var isToolbarShown: Bool { get }
    
    func showToolbar()
    func hideToolbar()
    func configureToolbarButtons(albumType: AlbumToolbarConfigurator.AlbumType)
    func downloadButtonPressed(_ button: UIBarButtonItem)
    func shareLinkButtonPressed(_ button: UIBarButtonItem)
    func favouriteButtonPressed(_ button: UIBarButtonItem)
    func deleteButtonPressed(_ button: UIBarButtonItem)
    func moreButtonPressed(_ button: UIBarButtonItem)
}

@available(iOS 14.0, *)
extension AlbumContentViewController: AlbumToolbarProvider {
    var isToolbarShown: Bool {
        return toolbar.superview != nil
    }
    
    func showToolbar() {
        toolbar.alpha = 0.0
        view.addSubview(toolbar)
        
        let bottomAnchor: NSLayoutYAxisAnchor = view.safeAreaLayoutGuide.bottomAnchor
        let leadingAnchor: NSLayoutXAxisAnchor = view.safeAreaLayoutGuide.leadingAnchor
        let trailingAnchor: NSLayoutXAxisAnchor = view.safeAreaLayoutGuide.trailingAnchor
        
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.backgroundColor = UIColor.mnz_mainBars(for: traitCollection)
        toolbar.heightAnchor.constraint(equalToConstant: 64.0).isActive = true
        toolbar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
        toolbar.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        toolbar.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        UIView.animate(withDuration: 0.3) {
            self.toolbar.alpha = 1.0
        }
    }
    
    func hideToolbar() {
        guard toolbar.superview != nil else { return }
        UIView.animate(withDuration: 0.3) {
            self.toolbar.alpha = 0.0
        } completion: { _ in
            self.toolbar.removeFromSuperview()
        }
    }
    
    func configureToolbarButtons(albumType: AlbumToolbarConfigurator.AlbumType) {
        if albumToolbarConfigurator == nil {
            albumToolbarConfigurator = AlbumToolbarConfigurator(
                downloadAction: downloadButtonPressed,
                shareLinkAction: shareLinkButtonPressed,
                moveAction: moveBarButtonPressed,
                copyAction: copyBarButtonPressed,
                deleteAction: deleteButtonPressed,
                favouriteAction: favouriteButtonPressed,
                removeToRubbishBinAction: deleteButtonPressed,
                moreAction: moreButtonPressed,
                albumType: albumType
            )
        }
        
        toolbar.items = albumToolbarConfigurator?.toolbarItems(forNodes: selectedNodes())
    }
    
    // MARK:- Toolbar Button actions
    func downloadButtonPressed(_ button: UIBarButtonItem) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty else {
                  return
              }
        
        TransfersWidgetViewController.sharedTransfer().bringProgressToFrontKeyWindowIfNeeded()
        
        SVProgressHUD.show(Asset.Images.Hud.hudDownload.image,
                           status: Strings.Localizable.downloadStarted)
        
        selectedNodes.forEach { node in
            if node.mnz_downloadNode() {
                downloadStarted(forNode: node)
            }
        }
        
        endEditingMode()
    }
    
    func shareLinkButtonPressed(_ button: UIBarButtonItem) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty else {
                  return
              }
        
        if MEGAReachabilityManager.isReachableHUDIfNot() {
            CopyrightWarningViewController.presentGetLinkViewController(
                for: selectedNodes,
                in: UIApplication.mnz_presentingViewController()
            )
            endEditingMode()
        }
    }
    
    func moveBarButtonPressed(_ button: UIBarButtonItem) {
        openBrowserViewController(withAction: .move)
    }
    
    func copyBarButtonPressed(_ button: UIBarButtonItem) {
        openBrowserViewController(withAction: .copy)
    }
    
    func deleteButtonPressed(_ button: UIBarButtonItem) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty,
              let rubbishBinNode = MEGASdkManager.sharedMEGASdk().rubbishNode else {
                  return
              }
        
        let moveRequestDelegate = MEGAMoveRequestDelegate(
            toMoveToTheRubbishBinWithFiles: UInt(selectedNodes.count),
            folders: 0) { [weak self] in
                self?.endEditingMode()
            }
        
        selectedNodes.forEach {
            MEGASdkManager.sharedMEGASdk().move(
                $0,
                newParent: rubbishBinNode,
                delegate: moveRequestDelegate
            ) }
    }
    
    func moreButtonPressed(_ button: UIBarButtonItem) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty else {
            return
        }
        
        let nodeActionsViewController = NodeActionViewController(nodes: selectedNodes, delegate: self, displayMode: .favouriteAlbumSelectionToolBar, sender: button)
        present(nodeActionsViewController, animated: true, completion: nil)
    }
    
    func didPressedExportFile(_ button: UIBarButtonItem) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty else {
            return
        }
        
        let entityNodes = selectedNodes.map { NodeEntity(node: $0) }
        ExportFileRouter(presenter: self, sender: button).export(nodes: entityNodes)
        endEditingMode()
    }
    
    func didPressedSendToChat(_ button: UIBarButtonItem) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty else {
            return
        }
        guard let navigationController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "SendToNavigationControllerID") as? MEGANavigationController,
              let sendToViewController = navigationController.viewControllers.first as? SendToViewController else {
            return
        }
        
        sendToViewController.nodes = selectedNodes
        sendToViewController.sendMode = .cloud
        present(navigationController, animated: true)
        endEditingMode()
    }
    
    func favouriteButtonPressed(_ button: UIBarButtonItem) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty
        else {
            return
        }
        
        let favoriteUseCase = NodeFavouriteActionUseCase(
            nodeFavouriteRepository: NodeFavouriteActionRepository(
                sdk: MEGASdkManager.sharedMEGASdk()
            )
        )
        
        selectedNodes.forEach { node in
            if node.isFavourite {
                favoriteUseCase.removeNodeFromFavourite(nodeHandle: node.handle) { _ in }
            }
            else {
                favoriteUseCase.addNodeToFavourite(nodeHandle: node.handle) { _ in }
            }
        }
        
        endEditingMode()
    }
    
    // MARK: - Private
    private func openBrowserViewController(withAction action: BrowserAction) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty,
              let navigationController = UIStoryboard(name: "Cloud", bundle: nil).instantiateViewController(withIdentifier: "BrowserNavigationControllerID") as? MEGANavigationController,
              let browserVC = navigationController.viewControllers.first as? BrowserViewController else {
                  return
              }
        
        browserVC.selectedNodesArray = selectedNodes
        browserVC.browserAction = action
        browserVC.browserViewControllerDelegate = self
        present(navigationController, animated: true)
    }
    
    private func downloadStarted(forNode node: MEGANode) { }
}

//MARK: - NodeActionViewControllerDelegate
@available(iOS 14.0, *)
extension AlbumContentViewController: NodeActionViewControllerDelegate {
    func nodeAction(
        _ nodeAction: NodeActionViewController,
        didSelect action: MegaNodeActionType,
        forNodes nodes: [MEGANode],
        from sender: Any
    ) {
        handleNodesAction(action: action, nodes: nodes, sender: sender)
    }
    
    func nodeAction(
        _ nodeAction: NodeActionViewController,
        didSelect action: MegaNodeActionType,
        for node: MEGANode,
        from sender: Any
    ) {
        handleNodesAction(action: action, nodes: [node], sender: sender)
    }

    private func handleNodesAction(
        action: MegaNodeActionType,
        nodes: [MEGANode],
        sender: Any
    ) {
        guard let sender = sender as? UIBarButtonItem else { return }
        switch action {
        case .download:
            downloadButtonPressed(sender)
        case .copy:
            copyBarButtonPressed(sender)
        case .move:
            moveBarButtonPressed(sender)
        case .shareLink:
            shareLinkButtonPressed(sender)
        case .moveToRubbishBin:
            deleteButtonPressed(sender)
        case .exportFile:
            didPressedExportFile(sender)
        case .sendToChat:
            didPressedSendToChat(sender)
        case .favourite:
            favouriteButtonPressed(sender)
        default:
            break
        }
    }
}

//MARK: - BrowserViewControllerDelegate
@available(iOS 14.0, *)
extension AlbumContentViewController: BrowserViewControllerDelegate {
    func nodeEditCompleted(_ complete: Bool) {
        endEditingMode()
    }
}