import Foundation

enum SlideShowOptionName {
    case none
    case speed
    case order
    case `repeat`
    
    case speedNormal
    case speedFast
    case speedSlow
    
    case orderShuffle
    case orderNewest
    case orderOldest
}

final class SlideShowOptionViewModel: ObservableObject {
    let navigationTitle = Strings.Localizable.Slideshow.PreferenceSetting.slideshowOptions
    let footerNote = Strings.Localizable.Slideshow.PreferenceSetting.mediaInSubFolders
    let doneButtonTitle = Strings.Localizable.done
    let cellViewModels: [SlideShowOptionCellViewModel]
    let currentConfiguration: SlideShowViewConfiguration
    private(set) var selectedCell: SlideShowOptionCellViewModel!
    
    @Published var shouldShowDetail = false
    
    init(
        cellViewModels: [SlideShowOptionCellViewModel],
        currentConfiguration: SlideShowViewConfiguration
    ) {
        self.cellViewModels = cellViewModels
        self.currentConfiguration = currentConfiguration
    }
    
    func didSelectCell(_ model: SlideShowOptionCellViewModel) {
        if model.type == .detail {
            selectedCell = model
            shouldShowDetail.toggle()
        }
    }
    
    private func selectedSpeed(from cellViewModels: [SlideShowOptionDetailCellViewModel]) -> SlideShowTimeIntervalOption {
        var speed = SlideShowTimeIntervalOption.normal
        
        cellViewModels.forEach { cell in
            if cell.name == .speedFast && cell.isSelcted {
                speed = .fast
            } else if cell.name == .speedSlow && cell.isSelcted {
                speed = .slow
            }
        }
        return speed
    }
    
    private func selectedOrder(from cellViewModels: [SlideShowOptionDetailCellViewModel]) -> SlideShowPlayingOrder {
        var order = SlideShowPlayingOrder.shuffled
        
        cellViewModels.forEach { cell in
            if cell.name == .orderNewest && cell.isSelcted {
                order = .newest
            } else if cell.name == .orderOldest && cell.isSelcted {
                order = .oldest
            }
        }
        return order
    }
    
    func configuration() -> SlideShowViewConfiguration {
        var config = currentConfiguration
       
        cellViewModels.forEach { cellViewModel in
            if cellViewModel.name == .speed {
                config.timeIntervalForSlideInSeconds = selectedSpeed(from: cellViewModel.children)
            } else if cellViewModel.name == .order {
                config.playingOrder = selectedOrder(from: cellViewModel.children)
            } else if cellViewModel.name == .repeat {
                config.isRepeat = cellViewModel.isOn
            }
        }
        
        return config
    }
}

extension SlideShowOptionViewModel {
    convenience init(
        @SlideShowOptionBuilder _ makeCells: () -> [SlideShowOptionCellViewModel],
        currentConfiguration: SlideShowViewConfiguration
    ) {
        self.init(cellViewModels: makeCells(), currentConfiguration: currentConfiguration)
    }
}