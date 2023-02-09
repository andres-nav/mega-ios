import Foundation
import MEGADomain
import Combine

final class AlbumContentPickerViewModel: ObservableObject {
   
    private let album: AlbumEntity
    private let photoLibraryUseCase: PhotoLibraryUseCaseProtocol
    private let mediaUseCase: MediaUseCaseProtocol
    private let albumContentModificationUseCase: AlbumContentModificationUseCaseProtocol
    private let completion: (String, AlbumEntity) -> Void
    private var subscriptions = Set<AnyCancellable>()
    var photosLoadingTask: Task<Void, Never>?
    
    @Published private(set) var photoSourceLocation: PhotosFilterLocation = .allLocations
    @Published var navigationTitle: String = ""
    @Published var isDismiss = false
    @Published var photoLibraryContentViewModel: PhotoLibraryContentViewModel
    @Published var shouldRemoveFilter = true
    
    private var normalNavigationTitle: String {
        Strings.Localizable.CameraUploads.Albums.Create.addItemsTo(album.name)
    }
    
    @MainActor
    init(album: AlbumEntity,
         photoLibraryUseCase: PhotoLibraryUseCaseProtocol,
         mediaUseCase: MediaUseCaseProtocol,
         albumContentModificationUseCase: AlbumContentModificationUseCaseProtocol,
         completion: @escaping (String, AlbumEntity) -> Void) {
        self.album = album
        self.photoLibraryUseCase = photoLibraryUseCase
        self.mediaUseCase = mediaUseCase
        self.albumContentModificationUseCase = albumContentModificationUseCase
        self.completion = completion
        photoLibraryContentViewModel = PhotoLibraryContentViewModel(library: PhotoLibrary(),
                                                                    contentMode: .album)
        navigationTitle = normalNavigationTitle
        setupSubscriptions()
    }
    
    deinit {
        photosLoadingTask?.cancel()
    }
    
    @MainActor
    public func onDone() {
        let nodes: [NodeEntity] = photoLibraryContentViewModel.selection.photos.values.map { $0 }
        guard nodes.isNotEmpty else {
            isDismiss.toggle()
            return
        }
        
        photosLoadingTask = Task(priority: .userInitiated) {
            do {
                let result = try await albumContentModificationUseCase.addPhotosToAlbum(by: album.id, nodes: nodes)
                if result.success > 0 {
                    let successMsg = self.successMessage(forAlbumName: album.name, withNumberOfItmes: result.success)
                    completion(successMsg, album)
                }
            } catch {
                MEGALogError("Error occurred when adding photos to an album. \(error.localizedDescription)")
            }
        }
        
        isDismiss.toggle()
    }
    
    func onFilter() {
        photoLibraryContentViewModel.showFilter.toggle()
    }
    
    func onCancel() {
        isDismiss.toggle()
    }
    
    // MARK: - Private
    private func setupSubscriptions() {
        photoLibraryContentViewModel.selection.$photos
            .compactMap { [weak self] photos in
                guard let self = self else { return nil }
                return photos.isEmpty ? self.normalNavigationTitle : self.navigationTitle(forNumberOfItems: photos.count)
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$navigationTitle)
        
        photoLibraryContentViewModel.filterViewModel.$appliedFilterLocation
            .removeDuplicates()
            .sink { [weak self] appliedPhotoFilterLocation in
                self?.loadPhotos(forPhotoLocation: appliedPhotoFilterLocation)
            }
            .store(in: &subscriptions)
    }
    
    private func loadPhotos(forPhotoLocation filterLocation: PhotosFilterLocation) {
        photosLoadingTask = Task(priority: .userInitiated) { [photoLibraryUseCase] in
            do {
                async let cloudDrive = await photoLibraryUseCase.allPhotosFromCloudDriveOnly()
                async let cameraUpload = await photoLibraryUseCase.allPhotosFromCameraUpload()
                let (cloudDrivePhotos, cameraUploadPhotos) = try await (cloudDrive, cameraUpload)
                await hideFilter(cloudDrivePhotos.isEmpty || cameraUploadPhotos.isEmpty)
                await updatePhotoSourceLocationIfRequired(filterLocation: filterLocation,
                                                          isCloudDriveEmpty: cloudDrivePhotos.isEmpty,
                                                          isCameraUploadsEmpty: cameraUploadPhotos.isEmpty)
                await updatePhotoLibraryContent(cloudDrivePhotos: cloudDrivePhotos, cameraUploadPhotos: cameraUploadPhotos)
            } catch {
                MEGALogError("Error occurred when loading photos. \(error.localizedDescription)")
            }
        }
    }
    
    @MainActor
    private func updatePhotoLibraryContent(cloudDrivePhotos: [NodeEntity], cameraUploadPhotos: [NodeEntity]) {
        let filteredPhotos = photoNodes(for: photoSourceLocation, from: cloudDrivePhotos, and: cameraUploadPhotos)
            .filter { $0.hasThumbnail }
        photoLibraryContentViewModel.library = filteredPhotos.toPhotoLibrary(withSortType: .newest)
        photoLibraryContentViewModel.selection.editMode = .active
    }
    
    @MainActor
    private func hideFilter(_ shouldHideFilter: Bool) {
        guard self.shouldRemoveFilter != shouldHideFilter else {
            return
        }
        self.shouldRemoveFilter = shouldHideFilter
    }
    
    @MainActor
    private func updatePhotoSourceLocationIfRequired(filterLocation: PhotosFilterLocation, isCloudDriveEmpty: Bool,
                                                     isCameraUploadsEmpty: Bool) {
        var selectedFilterLocation = filterLocation
        if isCloudDriveEmpty {
            selectedFilterLocation = .cameraUploads
        } else if isCameraUploadsEmpty {
            selectedFilterLocation = .cloudDrive
        }
        guard self.photoSourceLocation != selectedFilterLocation else {
            return
        }
        self.photoSourceLocation = selectedFilterLocation
    }
    
    private func photoNodes(for location: PhotosFilterLocation, from cloudDrivePhotos: [NodeEntity],
                       and cameraUploadPhotos: [NodeEntity]) -> [NodeEntity] {
        switch location {
        case .allLocations:
            return cloudDrivePhotos + cameraUploadPhotos
        case .cloudDrive:
            return cloudDrivePhotos
        case .cameraUploads:
            return cameraUploadPhotos
        }
    }
    
    private func navigationTitle(forNumberOfItems num: Int) -> String {
        num == 1 ? Strings.Localizable.oneItemSelected(1): Strings.Localizable.itemsSelected(num)
    }
    
    private func successMessage(forAlbumName name: String, withNumberOfItmes num: UInt) -> String {
        Strings.Localizable.CameraUploads.Albums.addedItemTo(Int(num)).replacingOccurrences(of: "[A]", with: "\(name)")
    }
}
