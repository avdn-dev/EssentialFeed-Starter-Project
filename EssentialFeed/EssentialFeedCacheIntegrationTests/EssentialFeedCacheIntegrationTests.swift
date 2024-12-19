//
//  EssentialFeedCacheIntegrationTests.swift
//  EssentialFeedCacheIntegrationTests
//
//  Created by Anh Nguyen on 19/12/2024.
//

import EssentialFeed
import Testing
import Foundation

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
        
        await confirmation("Load completion") { complete in
            await withCheckedContinuation { continuation in
                sut.load { result in
                    switch result {
                    case let .success(imageFeed):
                        #expect(imageFeed.isEmpty)
                    case let .failure(error):
                        Issue.record("Expected successful feed result, got \(error) instead")
                    }
                    
                    continuation.resume()
                    complete()
                }
            }
        }
    }
    
    @Test("Load delivers items saved on a separate instance")
    func loadDeliversItemsSavedOnASeparateInstance() async {
        let sutToPerformSave = makeSut()
        let sutToPerformLoad = makeSut()
        let feed = makeUniqueImageFeed().models
        
        await confirmation("Save completion") { complete in
            await withCheckedContinuation { continuation in
                sutToPerformSave.save(feed) { saveError in
                    #expect(saveError == nil)
                    
                    continuation.resume()
                    complete()
                }
            }
        }
        
        await confirmation("Save completion") { complete in
            await withCheckedContinuation { continuation in
                sutToPerformLoad.load { loadResult in
                    switch loadResult {
                    case let .success(imageFeed):
                        #expect(imageFeed == feed)
                    case let .failure(error):
                        Issue.record("Expected successful feed result, got \(error) instead")
                    }
                    
                    continuation.resume()
                    complete()
                }
            }
        }
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
}
