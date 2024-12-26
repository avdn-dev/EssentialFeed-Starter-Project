//
//  FeedViewControllerTests.swift
//  EssentialFeedIOSTests
//
//  Created by Anh Nguyen on 26/12/2024.
//

import EssentialFeed
import Testing
import UIKit

final class FeedViewController: UITableViewController {
    private var loader: FeedLoader?
    
    convenience init(loader: FeedLoader) {
        self.init()
        self.loader = loader
    }
    
    deinit {
        loader = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = MockUIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
        refreshControl?.beginRefreshing()
        load()
    }
    
    @objc private func load() {
        loader?.load { [weak self] _ in
            self?.refreshControl?.endRefreshing()
        }
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
    
    @Test("Pull to refresh loads feed")
    func pullToRefreshLoadsFeed() {
        let (sut, loader) = makeSut()
        sut.loadViewIfNeeded()
        
        sut.refreshControl?.simulatePullToRefresh()
        #expect(loader.loadCallCount == 2)
        
        sut.refreshControl?.simulatePullToRefresh()
        #expect(loader.loadCallCount == 3)
    }
    
    @Test("viewDidLoad shows loading indicator")
    func viewDidLoadShowsLoadingIndicator() {
        let (sut, _) = makeSut()
        
        sut.loadViewIfNeeded()
        
        #expect(sut.refreshControl?.isRefreshing == true)
    }
    
    @Test("viewDidLoad hides loading indicator on loader completion")
    func viewDidLoadHidesLoadingIndicatorOnLoaderCompletion() {
        let (sut, loader) = makeSut()
        
        sut.loadViewIfNeeded()
        loader.completeFeedLoading()
        
        #expect(sut.refreshControl?.isRefreshing == false)
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
        private var completions = [(FeedLoader.Result) -> Void]()
        
        var loadCallCount: Int { completions.count }
        
        func load(completion: @escaping (FeedLoader.Result) -> Void) {
            completions.append(completion)
        }
        
        func completeFeedLoading() {
            completions[0](.success([]))
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
