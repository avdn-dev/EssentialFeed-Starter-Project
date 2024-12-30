//
//  FeedViewControllerTests.swift
//  EssentialFeedIOSTests
//
//  Created by Anh Nguyen on 26/12/2024.
//

import EssentialFeed
import EssentialFeedIOS
import Testing
import UIKit

@MainActor
final class FeedViewControllerTests {
    private var sutTracker: MemoryLeakTracker<FeedViewController>?
    private var loaderTracker: MemoryLeakTracker<LoaderSpy>?
    
    deinit {
        sutTracker?.verifyDeallocation()
        loaderTracker?.verifyDeallocation()
    }
    
    @Test("Load feed actions request feed from loader")
    func loadFeedActionsRequestFeedFromLoader() {
        let (sut, loader) = makeSut()
        #expect(loader.loadCallCount == 0, "Expected no loading requests before view is loaded")
        
        sut.loadViewIfNeeded()
        #expect(loader.loadCallCount == 1, "Expected a loading request once view is loaded")
        
        sut.simulateUserInitiatedFeedReload()
        #expect(loader.loadCallCount == 2, "Expected another loading request once user initiates a reload")
        
        sut.simulateUserInitiatedFeedReload()
        #expect(loader.loadCallCount == 3, "Expected a third loading request once a user initiates another reload")
    }
    
    @Test("Loading indicator is visible while loading feed")
    func loadingIndicatorIsVisibleWhileLoadingFeed() {
        let (sut, loader) = makeSut()
        
        sut.loadViewIfNeeded()
        #expect(sut.isShowingLoadIndicator, "Expected loading indicator once view is loaded")
        
        loader.completeFeedLoading(at: 0)
        #expect(!sut.isShowingLoadIndicator, "Expected no loading indicator once loading is completed")
        
        sut.simulateUserInitiatedFeedReload()
        #expect(sut.isShowingLoadIndicator, "Expected loading indicator once user initiates a reload")
        
        loader.completeFeedLoading(at: 1)
        #expect(!sut.isShowingLoadIndicator, "Expected no loading indicator once user initiated reload is completed")
    }
    
    // MARK: Helpers
    func makeSut(sourceLocation: SourceLocation = #_sourceLocation) -> (sut: FeedViewController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader, makeRefreshControl: MockUIRefreshControl.init)
        sutTracker = MemoryLeakTracker(instance: sut, sourceLocation: sourceLocation)
        loaderTracker = MemoryLeakTracker(instance: loader, sourceLocation: sourceLocation)
        return (sut, loader)
    }
    
    class LoaderSpy: FeedLoader {
        private var completions = [(FeedLoader.Result) -> Void]()
        
        var loadCallCount: Int { completions.count }
        
        func load(completion: @escaping (FeedLoader.Result) -> Void) {
            completions.append(completion)
        }
        
        func completeFeedLoading(at index: Int) {
            completions[index](.success([]))
        }
    }
}

private class MockUIRefreshControl: UIRefreshControl {
    private var _isRefreshing = false
    
    override var isRefreshing: Bool { _isRefreshing }
    
    override func beginRefreshing() {
        _isRefreshing = true
    }
    
    override func endRefreshing() {
        _isRefreshing = false
    }
}

private extension UIRefreshControl {
    func simulatePullToRefresh() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .valueChanged)?.forEach { action in
                (target as NSObject).perform(Selector(action))
            }
        }
    }
}

extension FeedViewController {
    func simulateUserInitiatedFeedReload() {
        refreshControl?.simulatePullToRefresh()
    }
    
    var isShowingLoadIndicator: Bool { refreshControl?.isRefreshing == true }
}
