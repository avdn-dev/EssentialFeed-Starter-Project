//
//  FeedViewControllerTests.swift
//  EssentialFeedIOSTests
//
//  Created by Anh Nguyen on 26/12/2024.
//

import EssentialFeed
import Testing
import UIKit

final class FeedViewController: UIViewController {
    private var loader: FeedLoader!
    
    convenience init(loader: FeedLoader) {
        self.init()
        self.loader = loader
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loader.load { _ in }
    }
}

@MainActor
final class FeedViewControllerTests {
    private var sutTracker: MemoryLeakTracker<FeedViewController>?
    private var loaderTracker: MemoryLeakTracker<LoaderSpy>?
    
    deinit {
        sutTracker?.verifyDeallocation()
        loaderTracker?.verifyDeallocation()
    }
    
    @Test("Initialiser does not load feed")
    func initialiserDoesNotLoadFeed() {
        let (_, loader) = makeSut()
        
        #expect(loader.loadCallCount == 0)
    }
    
    @Test("viewDidLoad call loads feed")
    func viewDidLoadLoadsFeed() {
        let (sut, loader) = makeSut()
        
        sut.loadViewIfNeeded()
        
        #expect(loader.loadCallCount == 1)
    }
    
    // MARK: Helpers
    func makeSut(sourceLocation: SourceLocation = #_sourceLocation) -> (sut: FeedViewController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        sutTracker = MemoryLeakTracker(instance: sut, sourceLocation: sourceLocation)
        loaderTracker = MemoryLeakTracker(instance: loader, sourceLocation: sourceLocation)
        return (sut, loader)
    }
    
    class LoaderSpy: FeedLoader {
        private(set) var loadCallCount = 0
        
        func load(completion: @escaping (FeedLoader.Result) -> Void) {
            loadCallCount += 1
        }
    }
}
