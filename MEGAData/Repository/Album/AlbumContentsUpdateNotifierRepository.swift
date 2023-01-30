import MEGADomain

final class AlbumContentsUpdateNotifierRepository: AlbumContentsUpdateNotifierRepositoryProtocol {
    var onAlbumReload: (() -> Void)?
    
    private let sdk: MEGASdk
    private var nodesUpdateListenerRepo: NodesUpdateListenerProtocol
    
    init(
        sdk: MEGASdk,
        nodesUpdateListenerRepo: NodesUpdateListenerProtocol
    ) {
        self.sdk = sdk
        self.nodesUpdateListenerRepo = nodesUpdateListenerRepo
        
        self.nodesUpdateListenerRepo.onNodesUpdateHandler = { [weak self] nodes in
            self?.checkAlbumForReload(nodes.toMEGANodes(in: sdk))
        }
    }
    
    private func isAnyNodeMovedIntoTrash(_ nodes: [MEGANode]) -> Bool {
        let trashedNodes = nodes.lazy.filter {
            self.sdk.rubbishNode == $0
        }
        return trashedNodes.isNotEmpty
    }
    
    private func checkAlbumForReload(_ nodes: [MEGANode]) {
        let isAnyNodesTrashed = isAnyNodeMovedIntoTrash(nodes)
        let hasNewNodes = nodes.containsNewNode()
        let hasModifiedNodes = nodes.hasModifiedAttributes()
        let hasModifiedParent = nodes.hasModifiedParent()
        let hasPublicLink = nodes.hasPublicLink()
        let isPublicLinkRemoved = nodes.isPublicLinkRemoved()
        
        if isAnyNodesTrashed || hasNewNodes ||
            hasModifiedNodes || hasModifiedParent ||
            hasPublicLink || isPublicLinkRemoved {
            onAlbumReload?()
        }
    }
}
