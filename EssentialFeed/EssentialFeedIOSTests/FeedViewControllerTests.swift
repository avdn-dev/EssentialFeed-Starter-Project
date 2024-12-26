//
//  FeedViewControllerTests.swift
//  EssentialFeedIOSTests
//
//  Created by Anh Nguyen on 26/12/2024.
//

import Testing
import UIKit

final class FeedViewController: UIViewController {
    private var loader: FeedViewControllerTests.LoaderSpy!
    
    convenience init(loader: FeedViewControllerTests.LoaderSpy) {
        self.init()
        self.loader = loader
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loader.load()
    }
}

@MainActor
struct FeedViewControllerTests {
    @Test("Initialiser does not load feed")
    func initialiserDoesNotLoadFeed() {
        let loader = LoaderSpy()
        _ = FeedViewController(loader: loader)
        
        #expect(loader.loadCallCount == 0)
    }
    
    @Test("viewDidLoad call loads feed")
    func viewDidLoadLoadsFeed() {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        
        sut.loadViewIfNeeded()
        
        #expect(loader.loadCallCount == 1)
    }
    
    class LoaderSpy {
        private(set) var loadCallCount = 0
        
        func load() {
            loadCallCount += 1
        }
    }
}
