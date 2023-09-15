import MEGADomain
import MEGAL10n
import MEGASDKRepo
import SwiftUI

extension CloudDriveViewController {
    @objc func createNodeInfoViewModel(withNode node: MEGANode) -> NodeInfoViewModel {
        NodeInfoViewModel(
            withNode: node,
            shareUseCase: ShareUseCase(repo: ShareRepository.newRepo),
            shouldDisplayContactVerificationInfo: MEGASdk.shared.isContactVerificationWarningEnabled
        )
    }
    
    @objc func createCloudDriveViewModel() -> CloudDriveViewModel {
        CloudDriveViewModel(shareUseCase: ShareUseCase(repo: ShareRepository.newRepo))
    }
    
    private func updatedParentNodeIfBelongs(_ nodeList: MEGANodeList) -> MEGANode? {
        nodeList
            .toNodeArray()
            .compactMap {
                if $0.handle == parentNode?.handle { return $0 }
                return nil
            }.first
    }
    
    @IBAction func actionsTouchUpInside(_ sender: UIBarButtonItem) {
        guard let nodes = selectedNodesArray as? [MEGANode] else {
            return
        }
        
        let nodeActionsViewController = NodeActionViewController(nodes: nodes, delegate: self, displayMode: displayMode, isIncoming: isIncomingShareChildView, containsABackupNode: displayMode == .backup, sender: sender)
        present(nodeActionsViewController, animated: true, completion: nil)
    }
    
    @objc func showBrowserNavigation(for nodes: [MEGANode], action: BrowserAction) {
        guard let navigationController = storyboard?.instantiateViewController(withIdentifier: "BrowserNavigationControllerID") as? MEGANavigationController, let browserVC = navigationController.viewControllers.first as? BrowserViewController else {
            return
        }
        
        browserVC.browserViewControllerDelegate = self
        browserVC.selectedNodesArray = nodes
        browserVC.browserAction = action
        
        present(navigationController, animated: true)
    }
    
    @objc func toggledEditMode() {
        viewModel.dispatch(.toggleEditMode)
    }
    
    @IBAction func editTapped(_ sender: UIBarButtonItem) {
        toggledEditMode()
    }
    
    @objc func showShareFolderForNodes(_ nodes: [MEGANode]) {
        guard let navigationController =
                UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "ContactsNavigationControllerID") as? MEGANavigationController, let contactsVC = navigationController.viewControllers.first as? ContactsViewController else {
            return
        }
        
        contactsVC.contatctsViewControllerDelegate = self
        contactsVC.nodesArray = nodes
        contactsVC.contactsMode = .shareFoldersWith
        
        present(navigationController, animated: true)
    }
    
    @objc func showSendToChat(_ nodes: [MEGANode]) {
        guard let navigationController =
                UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "SendToNavigationControllerID") as? MEGANavigationController, let sendToViewController = navigationController.viewControllers.first as? SendToViewController else {
            return
        }
        
        sendToViewController.nodes = nodes
        sendToViewController.sendMode = .cloud
        
        present(navigationController, animated: true)
    }
    
    @objc func prepareToMoveNodes(_ nodes: [MEGANode]) {
        showBrowserNavigation(for: nodes, action: .move)
    }
    
    func createTextFileAlert() {
        guard let parentNode = parentNode else { return }
        CreateTextFileAlertViewRouter(presenter: navigationController, parentHandle: parentNode.handle).start()
    }
    
    private func shareType(for nodes: [MEGANode]) -> MEGAShareType {
        var currentNodeShareType: MEGAShareType = .accessUnknown
    
        nodes.forEach { node in
            currentNodeShareType = MEGASdk.shared.accessLevel(for: node)
            
            if currentNodeShareType == .accessRead && currentNodeShareType.rawValue < shareType.rawValue {
                return
            }
            
            if (currentNodeShareType == .accessReadWrite && currentNodeShareType.rawValue < shareType.rawValue) ||
                (currentNodeShareType == .accessFull && currentNodeShareType.rawValue < shareType.rawValue) {
                shareType = currentNodeShareType
            }
        }
        
        return shareType
    }
    
    @objc func toolbarActions(nodeArray: [MEGANode]?) {
        guard let nodeArray = nodeArray, !nodeArray.isEmpty else {
            return
        }
        let isBackupNode = displayMode == .backup
        shareType = isBackupNode ? .accessRead : shareType(for: nodeArray)
        
        toolbarActions(for: shareType, isBackupNode: isBackupNode)
    }

    @objc func updateParentNodeIfNeeded(_ updatedNodeList: MEGANodeList) {
        guard let updatedParentNode = updatedParentNodeIfBelongs(updatedNodeList) else { return }
        
        self.parentNode = updatedParentNode
        setNavigationBarButtons()
    }
    
    @objc func sortNodes(_ nodes: [MEGANode], sortBy order: MEGASortOrderType) -> [MEGANode] {
        let sortOrder = SortOrderType(megaSortOrderType: order)
        let folderNodes = nodes.filter { $0.isFolder() }.sort(by: sortOrder)
        let fileNodes = nodes.filter { $0.isFile() }.sort(by: sortOrder)
        return folderNodes + fileNodes
    }
    
    @objc func newFolderNameAlertTitle(invalidChars containsInvalidChars: Bool) -> String {
        guard containsInvalidChars else {
            return Strings.Localizable.newFolder
        }
        return Strings.Localizable.General.Error.charactersNotAllowed(String.Constants.invalidFileFolderNameCharacters)
    }
    
    @objc func showNodeActionsForNode(_ node: MEGANode, isIncoming: Bool, isBackupNode: Bool, sender: Any) {
        let nodeActions = NodeActionViewController(node: node, delegate: self, displayMode: displayMode, isIncoming: isIncoming, isBackupNode: isBackupNode, sender: sender)
        present(nodeActions, animated: true)
    }
    
    @objc func showCustomActionsForNode(_ node: MEGANode, sender: Any) {
        switch displayMode {
        case .backup:
            showCustomActionsForBackupNode(node, sender: sender)
        case .rubbishBin:
            let isSyncDebrisNode = RubbishBinUseCase(rubbishBinRepository: RubbishBinRepository.newRepo).isSyncDebrisNode(node.toNodeEntity())
            showNodeActionsForNode(node, isIncoming: isIncomingShareChildView, isBackupNode: isSyncDebrisNode, sender: sender)
        default:
            showNodeActionsForNode(node, isIncoming: isIncomingShareChildView, isBackupNode: false, sender: sender)
        }
    }
    
    @objc func updateNavigationBarTitle() {
        var selectedNodesArrayCount = 0
        var navigationTitle = ""
        
        if let selectedNodesArray { selectedNodesArrayCount = selectedNodesArray.count }
        
        if viewModel.editModeActive {
            navigationTitle = selectedNodesArrayCount == 0 ? Strings.Localizable.selectTitle : Strings.Localizable.General.Format.itemsSelected(selectedNodesArrayCount)
        } else {
            switch displayMode {
            case .cloudDrive:
                navigationTitle = parentNode == nil || parentNode?.type == .root ? Strings.Localizable.cloudDrive : parentNode?.name ?? ""
                
            case .rubbishBin:
                navigationTitle = parentNode?.type == .rubbish ? Strings.Localizable.rubbishBinLabel : parentNode?.name ?? ""
                
            case .backup:
                var isBackupsRootNode = false
                if let parentNode {
                    isBackupsRootNode = BackupsUseCase(backupsRepository: BackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo).isBackupsRootNode(parentNode.toNodeEntity())
                }
                
                navigationTitle = isBackupsRootNode ? Strings.Localizable.Backups.title : parentNode?.name ?? ""
                
            case .recents:
                if let nodes {
                    navigationTitle = Strings.Localizable.Recents.Section.Title.items(nodes.size.intValue)
                }
                
            default: break
            }
        }
        
        navigationItem.title = navigationTitle
        setMenuCapableBackButtonWith(menuTitle: navigationTitle)
    }

    @objc func updateToolbarButtonsEnabled(_ enabled: Bool, selectedNodesArray: [MEGANode]) {
        let enableIfNotDisputed = !selectedNodesArray.contains(where: { $0.isTakenDown() }) && enabled
        
        downloadBarButtonItem?.isEnabled = enableIfNotDisputed
        shareLinkBarButtonItem?.isEnabled = enableIfNotDisputed
        moveBarButtonItem?.isEnabled = enableIfNotDisputed
        carbonCopyBarButtonItem?.isEnabled = enableIfNotDisputed
        deleteBarButtonItem?.isEnabled = enabled
        restoreBarButtonItem?.isEnabled = enableIfNotDisputed
        actionsBarButtonItem?.isEnabled = enabled

        if self.displayMode == DisplayMode.rubbishBin && enabled {
            for node in selectedNodesArray where !node.mnz_isRestorable() {
                restoreBarButtonItem?.isEnabled = false
                break
            }
        }
    }
    
    func showImagePickerFor(sourceType: UIImagePickerController.SourceType) {
        if sourceType == .camera {
            guard let imagePickerController = MEGAImagePickerController(
                toUploadWithParentNode: parentNode,
                sourceType: sourceType
            ) else { return }
            present(imagePickerController, animated: true)
        } else {
            permissionHandler.photosPermissionWithCompletionHandler {[weak self] granted in
                guard let self else { return }
                if granted {
                    self.loadPhotoAlbumBrowser()
                } else {
                    self.permissionRouter.alertPhotosPermission()
                }
            }
        }
    }
    
    func showMediaCapture() {
        permissionHandler.requestVideoPermission { [weak self] videoPermissionGranted in
            guard let self else { return }
            if videoPermissionGranted {
                permissionHandler.photosPermissionWithCompletionHandler {[weak self] photosPermissionGranted in
                    guard let self else { return }
                    if !photosPermissionGranted {
                        UserDefaults.standard.set(false, forKey: "isSaveMediaCapturedToGalleryEnabled")
                    }
                    showImagePickerFor(sourceType: .camera)
                }
            } else {
                permissionRouter.alertVideoPermission()
            }
        }
    }
    
    func showDocumentImporter() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.data, UTType.package], asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        documentPicker.popoverPresentationController?.barButtonItem = contextBarButtonItem
        present(documentPicker, animated: true)
    }
    
    @objc func findIndexPath(for node: MEGANode, source: [MEGANode]) -> IndexPath {
        let section = sectionIndex(for: node, source: source)
        let item = itemIndex(for: node, source: source)
        return IndexPath(item: item, section: section)
    }
    
    private func sectionIndex(for node: MEGANode, source: [MEGANode]) -> Int {
        return node.isFolder() ? 0 : 1
    }
    
    private func itemIndex(for node: MEGANode, source: [MEGANode]) -> Int {
        guard source.isNotEmpty else {
            return 0
        }
        
        let isOnlyFiles = isAllNodeIsFileType(in: source)
        let isOnlyFolders = isAllNodeIsFolderType(in: source)
        let hasFilesAndFolders = !isOnlyFiles && !isOnlyFolders
        
        if isOnlyFiles || isOnlyFolders {
            return source.firstIndex { $0.handle == node.handle } ?? 0
        }
        
        if hasFilesAndFolders {
            if node.isFolder() {
                return source.firstIndex { $0.handle == node.handle } ?? 0
            } else {
                return findItemIndexForFileNode(for: node, source: source)
            }
        }
            
        return 0
    }
    
    private func findItemIndexForFileNode(for node: MEGANode, source: [MEGANode]) -> Int {
        let potentialIndex = source.firstIndex { $0.handle == node.handle } ?? 0
        let folderNodeCount = source.filter { $0.isFolder() }.count
        let normalizedFileNodeIndex = potentialIndex - folderNodeCount
        return normalizedFileNodeIndex
    }
    
    private func isAllNodeIsFileType(in source: [MEGANode]) -> Bool {
        source.allSatisfy { $0.isFile() }
    }
    
    private func isAllNodeIsFolderType(in source: [MEGANode]) -> Bool {
        source.allSatisfy { $0.isFolder() }
    }
    
    @objc func mapNodeListToArray(_ nodeList: MEGANodeList) -> NSArray {
        guard let size = nodeList.size, size.intValue > 0 else {
            return []
        }
        
        let tempNodes = NSMutableArray(capacity: nodeList.size.intValue)
        for i in 0..<nodeList.size.intValue {
            if let node = nodeList.node(at: i) {
                tempNodes.add(node)
            }
        }
        
        guard let immutableNodes = tempNodes.copy() as? NSArray else {
            return []
        }
        return immutableNodes
    }
    
    @objc func presentGetLink(for nodes: [MEGANode]) {
        guard MEGAReachabilityManager.isReachableHUDIfNot() else { return }
        GetLinkRouter(presenter: self,
                      nodes: nodes).start()
    }

    @objc func setupContactNotVerifiedBanner() {
        let hostingView = UIHostingController(
            rootView: WarningView(
                viewModel: .init(warningType: .contactNotVerifiedSharedFolder(parentNode?.name ?? ""))
            )
        )
        
        guard let hostingViewUIView = hostingView.view else { return }
        
        contactNotVerifiedBannerView.isHidden = !isFromUnverifiedContactSharedFolder
        contactNotVerifiedBannerView.addSubview(hostingViewUIView)
        hostingViewUIView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            hostingViewUIView.topAnchor.constraint(equalTo: contactNotVerifiedBannerView.topAnchor),
            hostingViewUIView.leadingAnchor.constraint(equalTo: contactNotVerifiedBannerView.leadingAnchor),
            hostingViewUIView.trailingAnchor.constraint(equalTo: contactNotVerifiedBannerView.trailingAnchor),
            hostingViewUIView.bottomAnchor.constraint(equalTo: contactNotVerifiedBannerView.bottomAnchor)
        ])
    }

    @objc func showUpgradePlanView() {
        UpgradeAccountRouter().presentUpgradeTVC()
    }
        
    @objc func setUpInvokeCommands() {
        viewModel.invokeCommand = { [weak self] command in
            
            guard let self else { return }
            
            switch command {
            case .enterSelectionMode:
                setEditMode(true)
            case .exitSelectionMode:
                setEditMode(false)
            case .reloadNavigationBarItems:
                setNavigationBarButtons()
            }
        }
    }
}
