import Combine
import Foundation
import MEGADomain
import MEGAL10n
import Search

class NodeBrowserViewModel: ObservableObject {

    // Here, we retain for example context menu delegate handlers, that need to leave as long as this view model.
    // See ContextMenuManager usage inside CloudDriveViewController that uses weakly linked delegates, those objects
    // are retained in the array below to guarantee correct time of life of those objects.
    // Ideally this should not be needed and ContextMenuManager should create menus and retain handlers in there
    // but we are reusing very complex ContextMenuManager that cannot be used in such a way currently.
    var actionHandlers: [Any] = []

    // View is in edit mode once user starts selecting nodes
    // Otherwise, view will be in regular mode, with Bool value indicating whether the back button
    // should be displayed or not
    enum ViewState {
        case editing
        case regular(showBackButton: Bool)
    }

    let searchResultsViewModel: SearchResultsViewModel
    // this is private as view should access only the view when needed, and this depends
    // on the view mode state and the injected instance.
    // Making actual property private removes logic of checking this from the view, allows to cover this by tests with high confidence
    private let mediaDiscoveryViewModel: MediaDiscoveryContentViewModel? // not available for recent buckets yet
    let warningViewModel: WarningViewModel?
    var mediaContentDelegate: MediaContentDelegateHandler?
    private let upgradeEncouragementViewModel: UpgradeEncouragementViewModel?
    let config: NodeBrowserConfig
    @Published var contextMenuViewFactory: NodeBrowserContextMenuViewFactory?

    @Published var shouldShowMediaDiscoveryAutomatically: Bool?
    @Published var viewMode: ViewModePreferenceEntity
    @Published var editing = false
    @Published var title = ""
    @Published var viewState: ViewState = .regular(showBackButton: false)
    var isSelectionHidden = false
    private var subscriptions = Set<AnyCancellable>()
    let avatarViewModel: MyAvatarViewModel
    private let storageFullAlertViewModel: StorageFullAlertViewModel

    private let nodeSource: NodeSource
    private let titleBuilder: (_ isEditing: Bool, _ selectedNodeCount: Int) -> String
    private let onOpenUserProfile: () -> Void
    private let onUpdateSearchBarVisibility: (Bool) -> Void
    private let onBack: () -> Void
    private let onEditingChanged: (Bool) -> Void

    init(
        viewMode: ViewModePreferenceEntity,
        searchResultsViewModel: SearchResultsViewModel,
        mediaDiscoveryViewModel: MediaDiscoveryContentViewModel?,
        warningViewModel: WarningViewModel?,
        upgradeEncouragementViewModel: UpgradeEncouragementViewModel?,
        config: NodeBrowserConfig,
        nodeSource: NodeSource,
        avatarViewModel: MyAvatarViewModel,
        // we call this whenever view sate is changed so that:
        // - preference is saved if it's required
        // - context menu can be reconstructed
        viewModeSaver: @escaping (ViewModePreferenceEntity) -> Void,
        storageFullAlertViewModel: StorageFullAlertViewModel,
        titleBuilder: @escaping (Bool, Int) -> String,
        onOpenUserProfile: @escaping () -> Void,
        onUpdateSearchBarVisibility: @escaping (Bool) -> Void,
        onBack: @escaping () -> Void,
        onEditingChanged: @escaping (Bool) -> Void
    ) {
        self.viewMode = viewMode
        self.searchResultsViewModel = searchResultsViewModel
        self.mediaDiscoveryViewModel = mediaDiscoveryViewModel
        self.warningViewModel = warningViewModel
        self.upgradeEncouragementViewModel = upgradeEncouragementViewModel
        self.config = config
        self.nodeSource = nodeSource
        self.avatarViewModel = avatarViewModel
        self.storageFullAlertViewModel = storageFullAlertViewModel
        self.titleBuilder = titleBuilder
        self.onOpenUserProfile = onOpenUserProfile
        self.onUpdateSearchBarVisibility = onUpdateSearchBarVisibility
        self.onEditingChanged = onEditingChanged
        self.onBack = onBack
        
        $viewMode
            .removeDuplicates()
            .sink { viewMode in
                if viewMode == .list {
                    searchResultsViewModel.layout = .list
                }
                if viewMode == .thumbnail {
                    searchResultsViewModel.layout = .thumbnail
                }
                
                // save to preferences/reconstruct context menu
                viewModeSaver(viewMode)
                // hide search bar if we are showing media disovery
                onUpdateSearchBarVisibility(viewMode != .mediaDiscovery)
            }
            .store(in: &subscriptions)
        
        // Some observations regarding editing (selection) state
        // in the legacy CD, so default we should implement it the same way.
        // When editing mode is enabled, there's no way of leaving the screen until edit mode is disabled
        // * user cannot navigate back (there's a select all button where normally back button is)
        // * user cannot navigate forward as selecting cell does mark is as select and does not push/present any new screen
        // * Tab bar is replaced by contextual Toolbar items
        // * More button (···) is replaced by "Cancel" button to exit edit mode
        // * Since user cannot access context More menu, view mode cannot be switched from List/Thumbnail to MediaDiscovery and vice versa.
        // * So those two pieces of state do not have to (and probably shouldn't )be kept sync
        $editing
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] editing in
                guard let self else { return }
                searchResultsViewModel.editing = editing
                mediaDiscoveryViewModel?.editMode = editing ? .active : .inactive
                if !editing {
                    searchResultsViewModel.selectedResultIds.removeAll()
                    // need to deselect all here to reset selected items
                    // ticket for this is [FM-1464]
                }

                refreshTitle(isEditing: editing)
                onEditingChanged(editing)
            }
            .store(in: &subscriptions)
        
        mediaContentDelegate?.isMediaDiscoverySelectionHandler = {[weak self] isSelectionHidden in
            self?.isSelectionHidden = isSelectionHidden
        }
    
        // we are retaining and then calling the previously assigned closure here
        // as the toolbar handling code need to also be aware of what is selected and need
        // to be called via selectionChanged (See CloudDriveViewControllerFactory)
        let previousClosure = searchResultsViewModel.bridge.selectionChanged
        searchResultsViewModel.bridge.selectionChanged = { [weak self] selected in
            previousClosure(selected)
            guard let self else { return }
            // we not keep the select state in here, keep only one place to store
            // truth state which avoids possibility of incorrect syncing or reading invalid state
            self.refreshTitle()
        }

        searchResultsViewModel.bridge.editingChanged = { [weak self] editing in
            guard let self else { return }
            self.editing = editing
            self.refresh()
        }

        refresh()
    }
    
    var viewModeAwareMediaDiscoveryViewModel: MediaDiscoveryContentViewModel? {
        if viewMode == .mediaDiscovery, let viewModel = mediaDiscoveryViewModel {
            return viewModel
        } 
        return nil
    }
    
    @MainActor
    func onLoadTask() {
        storageFullAlertViewModel.showStorageAlertIfNeeded()
    }
    
    func onViewAppear() {
        encourageUpgradeIfNeeded()
    }
    
    private func encourageUpgradeIfNeeded() {
        upgradeEncouragementViewModel?.encourageUpgradeIfNeeded()
    }

    private func refresh() {
        refreshViewState()
        refreshTitle()
    }

    private func refreshViewState() {
        viewState = editing ? .editing : .regular(showBackButton: isBackButtonShown)
    }

    // this is also triggered from outside when node folder is renamed
    func refreshTitle() {
        refreshTitle(isEditing: editing)
    }
    
    var selectedCount: Int {
        if let mediaDiscoveryViewModel = viewModeAwareMediaDiscoveryViewModel {
            return mediaDiscoveryViewModel.photoLibraryContentViewModel.selection.photos.count
        } else {
            return searchResultsViewModel.selectedResultIds.count
        }
    }
    
    private func refreshTitle(isEditing: Bool) {
        title = titleBuilder(isEditing, selectedCount)
    }
    
    private var isBackButtonShown: Bool {
        guard let parentNode = nodeSource.parentNode else { return false }
        return parentNode.nodeType != .root
    }

    func openUserProfile() {
        onOpenUserProfile()
    }

    func back() {
        onBack()
    }
    
    func toggleSelection() {
        editing.toggle()
        refresh()
    }
    
    func changeViewMode(_ viewMode: ViewModePreferenceEntity) {
        self.viewMode = viewMode
    }
    
    func selectAll() {
        guard case .editing = viewState else { return }
        
        if let mediaDiscoveryViewModel = viewModeAwareMediaDiscoveryViewModel {
            mediaDiscoveryViewModel.toggleAllSelected()
        } else {
            searchResultsViewModel.toggleSelectAll()
        }
        refreshTitle()
    }

    func stopEditing() {
        editing = false
        refresh()
        searchResultsViewModel.bridge.editingCancelled()
    }
}

extension NodeBrowserViewModel {
    /// Decides whether the observing View needs to show its navigation bar back button or not.
    var hidesBackButton: Bool {
        switch viewState {
        case .editing:
            true
        case .regular(let showBackButton):
            !showBackButton
        }
    }
}
