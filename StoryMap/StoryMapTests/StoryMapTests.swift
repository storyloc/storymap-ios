//
//  StoryMapTests.swift
//  StoryMapTests
//
//  Created by Dory on 10/11/2021.
//

import XCTest
@testable import StoryMap
import AVFAudio

class AddStoryViewModelTests: XCTestCase {
    let testLocation = Location(latitude: 0, longitude: 0)

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    
    }

    func testConfirmButtonEnabledWhenImageIsNil() {
        // Given
        let viewModel = AddStoryViewModel(location: testLocation)
        
        // When
        viewModel.title = "Title"
        viewModel.image = nil
        
        // Then
        XCTAssertFalse(viewModel.confirmButtonEnabled)
    }
    
    func testConfirmButtonEnabledWhenTitleAndImageIsNil() {
        // Given
        let viewModel = AddStoryViewModel(location: testLocation)
        
        // When
        viewModel.title = nil
        viewModel.image = nil
        
        // Then
        XCTAssertFalse(viewModel.confirmButtonEnabled)
    }
}
