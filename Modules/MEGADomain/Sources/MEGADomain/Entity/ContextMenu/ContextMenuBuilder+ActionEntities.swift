extension ContextMenuBuilder {
    
    //MARK: - Upload Add Actions
    
    var choosePhotoVideo: CMActionEntity {
        CMActionEntity(type: .uploadAdd(actionType: .chooseFromPhotos))
    }
    
    var capturePhotoVideo: CMActionEntity {
        CMActionEntity(type: .uploadAdd(actionType: .capture))
    }
    
    var importFromFiles: CMActionEntity {
        CMActionEntity(type: .uploadAdd(actionType: .importFrom))
    }
    
    var newTextFile: CMActionEntity {
        CMActionEntity(type: .uploadAdd(actionType: .newTextFile))
    }
    
    var scanDocument: CMActionEntity {
        CMActionEntity(type: .uploadAdd(actionType: .scanDocument))
    }
    
    var newFolder: CMActionEntity {
        CMActionEntity(type: .uploadAdd(actionType: .newFolder))
    }
    
    //MARK: - Display Actions
    
    var select: CMActionEntity {
        CMActionEntity(type: .display(actionType: .select))
    }
    
    var thumbnailView: CMActionEntity {
        CMActionEntity(type: .display(actionType: .thumbnailView),
                       state: currentViewMode() == .thumbnail ? .on : .off)
    }
    
    var listView: CMActionEntity {
            CMActionEntity(type: .display(actionType: .listView),
                       state: currentViewMode() == .list ? .on : .off)
    }
    
    var emptyRubbishBin: CMActionEntity {
        CMActionEntity(type: .display(actionType: .clearRubbishBin))
    }
    
    var mediaDiscovery: CMActionEntity {
        CMActionEntity(type: .display(actionType: .mediaDiscovery))
    }
    
    var filter: CMActionEntity {
        CMActionEntity(type: .display(actionType: .filter))
    }
    
    //MARK: - Sort Actions
    
    var sortNameAscending: CMActionEntity {
        CMActionEntity(type: .sort(actionType: .defaultAsc),
                       state: currentSortType() == .defaultAsc ? .on : .off)
    }
    
    var sortNameDescending: CMActionEntity {
        CMActionEntity(type: .sort(actionType: .defaultDesc),
                       state: currentSortType() == .defaultDesc ? .on : .off)
    }
    
    var sortLargest: CMActionEntity {
        CMActionEntity(type: .sort(actionType: .sizeDesc),
                       state: currentSortType() == .sizeDesc ? .on : .off)
    }
    
    var sortSmallest: CMActionEntity {
        CMActionEntity(type: .sort(actionType: .sizeAsc),
                       state: currentSortType() == .sizeAsc ? .on : .off)
    }
    
    var sortNewest: CMActionEntity {
        CMActionEntity(type: .sort(actionType: .modificationDesc),
                       state: currentSortType() == .modificationDesc ? .on : .off)
    }
    
    var sortOldest: CMActionEntity {
        CMActionEntity(type: .sort(actionType: .modificationAsc),
                       state: currentSortType() == .modificationAsc ? .on : .off)
    }
    
    var sortLabel: CMActionEntity {
        CMActionEntity(type: .sort(actionType: .labelAsc),
                       state: currentSortType() == .labelAsc ? .on : .off)
    }
    
    var sortFavourite: CMActionEntity {
        CMActionEntity(type: .sort(actionType: .favouriteAsc),
                       state: currentSortType() == .favouriteAsc ? .on : .off)
    }
    
    //MARK: - Quick Folder Actions
    
    var info: CMActionEntity {
        CMActionEntity(type: .quickActions(actionType: .info))
    }
    
    var download: CMActionEntity {
        CMActionEntity(type: .quickActions(actionType: .download))
    }
    
    var shareLink: CMActionEntity {
        CMActionEntity(type: .quickActions(actionType: .shareLink))
    }
    
    var manageLink: CMActionEntity {
        CMActionEntity(type: .quickActions(actionType: .manageLink))
    }
    
    var removeLink: CMActionEntity {
        CMActionEntity(type: .quickActions(actionType: .removeLink))
    }
    
    var leaveSharing: CMActionEntity {
        CMActionEntity(type: .quickActions(actionType: .leaveSharing))
    }
    
    var removeSharing: CMActionEntity {
        CMActionEntity(type: .quickActions(actionType: .removeSharing))
    }
    
    var copy: CMActionEntity {
        CMActionEntity(type: .quickActions(actionType: .copy))
    }
    
    var shareFolder: CMActionEntity {
        CMActionEntity(type: .quickActions(actionType: .shareFolder))
    }
    
    var manageFolder: CMActionEntity {
        CMActionEntity(type: .quickActions(actionType: .manageFolder))
    }
    
    var rename: CMActionEntity {
        CMActionEntity(type: .quickActions(actionType: .rename))
    }
    
    //MARK: - Rubbish Bin Actions
    
    var restore: CMActionEntity {
        CMActionEntity(type: .rubbishBin(actionType: .restore))
    }
    
    var infoRubbishBin: CMActionEntity {
        CMActionEntity(type: .rubbishBin(actionType: .info))
    }
    
    var versions: CMActionEntity {
        CMActionEntity(type: .rubbishBin(actionType: .versions))
    }
    
    var remove: CMActionEntity {
        CMActionEntity(type: .rubbishBin(actionType: .remove))
    }
    
    //MARK: - Chat Actions
    
    func chatStatus(_ status: ChatStatusEntity) -> CMActionEntity {
        CMActionEntity(type: .chatStatus(actionType: status),
                       state: currentChatStatus() == status ? .on : .off)
    }
    
    func doNotDisturb(option: DNDTurnOnOptionEntity) -> CMActionEntity {
        CMActionEntity(type: .chatDoNotDisturbEnabled(optionType: option))
    }
    
    //MARK: - My QR Code Actions
    
    var share: CMActionEntity {
        CMActionEntity(type: .qr(actionType: .share))
    }
    
    var settings: CMActionEntity {
        CMActionEntity(type: .qr(actionType: .settings))
    }
    
    var resetQR: CMActionEntity {
        CMActionEntity(type: .qr(actionType: .resetQR))
    }
    
    //MARK: - Meeting
    
    var startMeeting: CMActionEntity {
        CMActionEntity(type: .meeting(actionType: .startMeeting))
    }
    
    var joinMeeting: CMActionEntity {
        CMActionEntity(type: .meeting(actionType: .joinMeeting))
    }
    
    var scheduleMeeting: CMActionEntity {
        CMActionEntity(type: .meeting(actionType: .scheduleMeeting))
    }

}