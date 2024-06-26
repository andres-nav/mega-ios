import MEGADomain
import MEGASdk

public struct PhotoLibraryRepository: PhotoLibraryRepositoryProtocol, Sendable {    
    private let sdk: MEGASdk
    private let cameraUploadNodeAccess: CameraUploadNodeAccess
    
    public init(sdk: MEGASdk, cameraUploadNodeAccess: CameraUploadNodeAccess) {
        self.sdk = sdk
        self.cameraUploadNodeAccess = cameraUploadNodeAccess
    }
    
    public func visualMediaNodes(inParent parentNode: NodeEntity?) -> [NodeEntity] {
        guard let parentNode = parentNode?.toMEGANode(in: sdk) else {
            return []
        }
        
        let nodeList = sdk.children(
            forParent: parentNode,
            order: MEGASortOrderType.modificationDesc.rawValue
        )
        
        return nodeList.toNodeArray().filter {
            $0.name?.fileExtensionGroup.isVisualMedia ?? false
        }.toNodeEntities()
    }
    
    public func videoNodes(inParent parentNode: NodeEntity?) -> [NodeEntity] {
        guard let parentNode = parentNode?.toMEGANode(in: sdk) else {
            return []
        }
        
        let nodeList = sdk.children(
            forParent: parentNode,
            order: MEGASortOrderType.modificationDesc.rawValue
        )
        
        return nodeList.toNodeArray().filter {
            $0.name?.fileExtensionGroup.isVideo ?? false
        }.toNodeEntities()
    }
    
    public func photoSourceNode(for source: PhotoSourceEntity) async throws -> NodeEntity? {
        switch source {
        case .camera:
            return try await cameraUploadNode()
        case .media:
            return try await mediaUploadNode()
        }
    }

    private func cameraUploadNode() async throws -> NodeEntity? {
        try await withCheckedThrowingContinuation { continuation in
            cameraUploadNodeAccess.loadNode { node, error in
                guard Task.isCancelled == false
                else {
                    continuation.resume(throwing: CancellationError())
                    return
                }

                if let node {
                    continuation.resume(returning: node.toNodeEntity())
                } else if let error = error {
                    let message = "Couldn't load CU: \(error)"
                    MEGASdk.log(with: .warning, message: "[iOS] \(message)", filename: #file, line: #line)
                    continuation.resume(throwing: PhotoLibraryErrorEntity.cameraUploadNodeDoesNotExist)
                } else {
                    continuation.resume(throwing: PhotoLibraryErrorEntity.cameraUploadNodeDoesNotExist)
                }
            }
        }
    }
    
    private func mediaUploadNode() async throws -> NodeEntity? {
        try await withCheckedThrowingContinuation { continuation in
            MediaUploadNodeAccess.shared.loadNode { node, error in
                guard Task.isCancelled == false
                else {
                    continuation.resume(throwing: CancellationError())
                    return
                }

                if let node {
                    continuation.resume(returning: node.toNodeEntity())
                } else if let error {
                    let message = "Couldn't load MU: \(error)"
                    MEGASdk.log(with: .warning, message: "[iOS] \(message)", filename: #file, line: #line)
                    continuation.resume(throwing: PhotoLibraryErrorEntity.mediaUploadNodeDoesNotExist)
                } else {
                    continuation.resume(throwing: PhotoLibraryErrorEntity.mediaUploadNodeDoesNotExist)
                }
            }
        }
    }
}
