import MEGADomain

public final class MockNodeDataUseCase: NodeUseCaseProtocol {
    private let nodeAccessLevelVariable: NodeAccessTypeEntity
    public var labelStringToReturn: String
    private let filesAndFolders: (Int, Int)
    public var versions: Bool
    public var downloadedToReturn: Bool
    public var inRubbishBinToReturn: Bool
    private var multimediaNodes: [NodeEntity]
    
    public var isMultimediaFileNode_CalledTimes = 0
    
    public init(nodeAccessLevelVariable: NodeAccessTypeEntity = .unknown,
                labelString: String = "",
                filesAndFolders: (Int, Int) = (0, 0),
                versions: Bool = false,
                downloaded: Bool = false,
                inRubbishBin: Bool = false,
                multimediaNodes: [NodeEntity] = []) {
        self.nodeAccessLevelVariable = nodeAccessLevelVariable
        self.labelStringToReturn = labelString
        self.filesAndFolders = filesAndFolders
        self.versions = versions
        self.downloadedToReturn = downloaded
        self.inRubbishBinToReturn = inRubbishBin
        self.multimediaNodes = multimediaNodes
    }
    
    public func nodeAccessLevel(nodeHandle: HandleEntity) -> NodeAccessTypeEntity {
        return nodeAccessLevelVariable
    }
    
    public func nodeAccessLevelAsync(nodeHandle: HandleEntity) async -> NodeAccessTypeEntity {
        nodeAccessLevelVariable
    }
    
    public func downloadToOffline(nodeHandle: HandleEntity) { }
    
    public func labelString(label: NodeLabelTypeEntity) -> String {
        labelStringToReturn
    }
    
    public func getFilesAndFolders(nodeHandle: HandleEntity) -> (childFileCount: Int, childFolderCount: Int) {
        filesAndFolders
    }
    
    public func hasVersions(nodeHandle: HandleEntity) -> Bool {
        versions
    }
    
    public func isDownloaded(nodeHandle: HandleEntity) -> Bool {
        downloadedToReturn
    }
    
    public func isInRubbishBin(nodeHandle: HandleEntity) -> Bool {
        inRubbishBinToReturn
    }
    
    public func nodeForHandle(_ handle: MEGADomain.HandleEntity) -> NodeEntity? {
        nil
    }
    
    public func parentForHandle(_ handle: MEGADomain.HandleEntity) -> NodeEntity? {
        nil
    }
    
    public func parentsForHandle(_ handle: MEGADomain.HandleEntity) async -> [NodeEntity]? {
        nil
    }
}
