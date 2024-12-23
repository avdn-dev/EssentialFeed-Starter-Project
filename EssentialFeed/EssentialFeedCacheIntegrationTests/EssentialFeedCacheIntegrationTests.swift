//
//  EssentialFeedCacheIntegrationTests.swift
//  EssentialFeedCacheIntegrationTests
//
//  Created by Anh Nguyen on 19/12/2024.
//

import EssentialFeed
import Testing
import Foundation

@Suite(.serialized)
final class EssentialFeedCacheIntegrationTests {
    private var sutTracker: MemoryLeakTracker<LocalFeedLoader>?
    private var storeTracker: MemoryLeakTracker<CodableFeedStore>?
    
    init() {
        setupEmptyStoreState()
    }
    
    deinit {
        undoStoreSideEffects()
        sutTracker?.verifyDeallocation()
        storeTracker?.verifyDeallocation()
    }
    
    @Test("Load delivers no items from empty cache")
    func loadDeliversNoItemsFromEmptyCache() async {
        let sut = makeSut()
        
        await expect(sut, toLoad: [])
    }
    
    @Test("Load delivers items saved on a separate instance")
    func loadDeliversItemsSavedOnASeparateInstance() async {
        let sutToPerformSave = makeSut()
        let sutToPerformLoad = makeSut()
        let feed = makeUniqueImageFeed().models
        
        await save(feed, with: sutToPerformSave)
        
        await expect(sutToPerformLoad, toLoad: feed)
    }
    
    @Test("Save overrides items saved on a separate instance")
    func saveOverridesItemsSavedOnASeparateInstance() async {
        let sutToPerformFirstSave = makeSut()
        let sutToPerformSecondSave = makeSut()
        let sutToPerformLoad = makeSut()
        let firstFeed = makeUniqueImageFeed().models
        let secondFeed = makeUniqueImageFeed().models
        
        await save(firstFeed, with: sutToPerformFirstSave)
        await save(secondFeed, with: sutToPerformSecondSave)
        
        await expect(sutToPerformLoad, toLoad: secondFeed)
    }
    
    // MARK: Helpers
    private func makeSut(sourceLocation: SourceLocation = #_sourceLocation) -> LocalFeedLoader {
        let store = CodableFeedStore(storeUrl: makeTestStoreUrl())
        let sut = LocalFeedLoader(store: store, currentDate: Date.init)
        sutTracker = MemoryLeakTracker(instance: sut, sourceLocation: sourceLocation)
        storeTracker = MemoryLeakTracker(instance: store, sourceLocation: sourceLocation)
        return sut
    }
    
    private func makeTestStoreUrl() -> URL { makeCachesDirectoryUrl().appending(path: "\(type(of: self)).store") }
    
    private func makeCachesDirectoryUrl() -> URL { FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first! }
    
    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }
    
    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: makeTestStoreUrl())
    }
    
    private func expect(_ sut: LocalFeedLoader, toLoad expectedFeed: [FeedImage], sourceLocation: SourceLocation = #_sourceLocation) async {
        await withCheckedContinuation { continuation in
            sut.load { result in
                switch result {
                case let .success(loadedFeed):
                    #expect(loadedFeed == expectedFeed, sourceLocation: sourceLocation)
                case let .failure(error):
                    Issue.record("Expected successful feed result, got \(error) instead", sourceLocation: sourceLocation)
                }
                
                continuation.resume()
            }
        }
    }
    
    private func save(_ feed: [FeedImage], with loader: LocalFeedLoader, sourceLocation: SourceLocation = #_sourceLocation) async {
        await withCheckedContinuation { continuation in
            loader.save(feed) { saveResult in
                switch saveResult {
                case .success:
                    break
                case let .failure(error):
                    Issue.record("Expected success, got \(error) instead", sourceLocation: sourceLocation)
                }
                
                continuation.resume()
            }
        }
    }
}
