//
//  FeedViewControllerTests.swift
//  EssentialFeedIOSTests
//
//  Created by Anh Nguyen on 26/12/2024.
//

import Testing

final class FeedViewController {
    init(loader: FeedViewControllerTests.LoaderSpy) {
        
    }
}

struct FeedViewControllerTests {
    @Test("Initialiser does not load feed")
    func initialiserDoesNotLoadFeed() {
        let loader = LoaderSpy()
        _ = FeedViewController(loader: loader)
        
        #expect(loader.loadCallCount == 0)
    }
    
    class LoaderSpy {
        private(set) var loadCallCount = 0
    }
}
