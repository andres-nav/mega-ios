import XCTest
@testable import MEGA
import MEGADomain
import MEGADomainMock
import Combine

final class PhotoLibraryYearViewModelTests: XCTestCase {
    private var sut: PhotoLibraryYearViewModel!
    private var subscriptions = Set<AnyCancellable>()
    
    override func setUpWithError() throws {
        let nodes =  [
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, modificationTime: try "2021-07-18T22:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 3, modificationTime: try "2020-04-18T22:01:04Z".date),
        ]
        let library = nodes.toPhotoLibrary(withSortType: .newest, in: TimeZone(secondsFromGMT: 0))
        let libraryViewModel = PhotoLibraryContentViewModel(library: library)
        libraryViewModel.selectedMode = .year
        sut = PhotoLibraryYearViewModel(libraryViewModel: libraryViewModel)
        XCTAssertEqual(sut.photoCategoryList, library.photoByYearList)
        XCTAssertEqual(sut.photoCategoryList[0].categoryDate, try "2022-08-18T22:01:04Z".date.removeMonth(timeZone: TimeZone(secondsFromGMT: 0)))
        XCTAssertNil(libraryViewModel.cardScrollPosition)
        XCTAssertNil(libraryViewModel.photoScrollPosition)
        XCTAssertEqual(libraryViewModel.selectedMode, .year)
    }
    
    func testDidTapCategory_tappingYearCard_goToMonthMode() throws {
        let category = sut.photoCategoryList[2]
        XCTAssertEqual(category.categoryDate, try "2020-04-18T22:01:04Z".date.removeMonth(timeZone: TimeZone(secondsFromGMT: 0)))
        sut.didTapCategory(category)
        XCTAssertEqual(sut.libraryViewModel.cardScrollPosition, category.position)
        XCTAssertNil(sut.libraryViewModel.photoScrollPosition)
        XCTAssertEqual(sut.libraryViewModel.selectedMode, .month)
    }
    
    func testChangingSelectedMode_switchingFromYearToMonthMode_goToMonthMode() throws {
        sut.libraryViewModel.selectedMode = .month
        XCTAssertNil(sut.libraryViewModel.cardScrollPosition)
        XCTAssertNil(sut.libraryViewModel.photoScrollPosition)
    }
    
    func testChangingSelectedMode_switchingFromYearToDayMode_goToDayMode() throws {
        sut.libraryViewModel.selectedMode = .day
        XCTAssertNil(sut.libraryViewModel.cardScrollPosition)
        XCTAssertNil(sut.libraryViewModel.photoScrollPosition)
    }
    
    func testChangingSelectedMode_switchingFromYearToAllMode_goToAllMode() throws {
        var didFinishPhotoCardScrollPositionCalculationNotificationCount = 0
        
        NotificationCenter
            .default
            .publisher(for: .didFinishPhotoCardScrollPositionCalculation)
            .sink { _ in
                didFinishPhotoCardScrollPositionCalculationNotificationCount += 1
            }
            .store(in: &subscriptions)
        
        
        sut.libraryViewModel.selectedMode = .all
        XCTAssertNil(sut.libraryViewModel.cardScrollPosition)
        XCTAssertNil(sut.libraryViewModel.photoScrollPosition)
        XCTAssertEqual(didFinishPhotoCardScrollPositionCalculationNotificationCount, 1)
    }
}
