//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Anh Nguyen on 17/12/2024.
//

import EssentialFeed
import Foundation
import Testing

@Suite(.serialized)
final class CodableFeedStoreTests {
    private var sutTracker: MemoryLeakTracker<CodableFeedStore>?
    
    init() {
        setupEmptyStoreState()
    }
    
    deinit {
        undoStoreSideEffects()
        sutTracker?.verifyDeallocation()
    }
    
    @Test("Retrieve delivers nothing on empty cache")
    func retrieveDeliversNothingOnEmptyCache() async {
        let sut = makeSut()
        
        await expect(sut, toRetrieve: .empty)
    }
    
    @Test("Retrieve delivers nothing on empty cache twice with no side effect")
    func retrieveDeliversNothingOnEmptyCacheTwice() async {
        let sut = makeSut()
        
        await expect(sut, toRetrieveTwice: .empty)
    }
    
    @Test("Retrieve after insert into empty cache returns initially inserted values")
    func retrieveAfterInsertDeliversInsertedValues() async {
        let feed = makeUniqueImageFeed().local
        let timestamp = Date()
        let sut = makeSut()
        
        await insert((feed, timestamp), to: sut)
        
        await expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp))
    }
    
    @Test("Retrieve after insert into empty cache returns initially inserted values with no side effect")
    func retrieveAfterInsertDeliversInsertedValuesTwice() async {
        let feed = makeUniqueImageFeed().local
        let timestamp = Date()
        let sut = makeSut()
        
        await insert((feed, timestamp), to: sut)
        
        await expect(sut, toRetrieveTwice: .found(feed: feed, timestamp: timestamp))
    }
    
    @Test("Retrieve delivers failure on retrieval error")
    func retrieveDeliversFailureOnRetrievalError() async {
        let storeUrl = makeTestStoreUrl()
        let sut = makeSut(storeUrl: storeUrl)
        
        try! "invalid data".write(to: storeUrl, atomically: false, encoding: .utf8)
        
        await expect(sut, toRetrieve: .failure(makeNsError()))
    }
    
    @Test("Retrieve delivers failure on retrieval error with no side effect")
    func retrieveDeliversFailureOnRetrievalErrorTwice() async {
        let storeUrl = makeTestStoreUrl()
        let sut = makeSut(storeUrl: storeUrl)
        
        try! "invalid data".write(to: storeUrl, atomically: false, encoding: .utf8)
        
        await expect(sut, toRetrieveTwice: .failure(makeNsError()))
    }
    
    @Test("Insert overwrites previously inserted cache values")
    func insertOverwritesPreviousCacheValues() async {
        let sut = makeSut()
        
        let firstInsertionError = await insert((makeUniqueImageFeed().local, Date()), to: sut)
        #expect(firstInsertionError == nil)
        
        let latestFeed = makeUniqueImageFeed().local
        let latestTimestamp = Date()
        let latestInsertionError = await insert((latestFeed, latestTimestamp), to: sut)
        
        #expect(latestInsertionError == nil)
        await expect(sut, toRetrieve: .found(feed: latestFeed, timestamp: latestTimestamp))
    }
    
    @Test("Insert delivers error on insertion error")
    func insertDeliversErrorOnInsertionError() async {
        let invalidStoreUrl = URL(string: "invalid://store-url")
        let sut = makeSut(storeUrl: invalidStoreUrl)
        
        let insertionError = await insert((makeUniqueImageFeed().local  , Date()), to: sut)
        
        #expect(insertionError != nil)
    }
    
    @Test("Insert delivers error on insertion error with no side effect")
    func insertDeliversErrorOnInsertionErrorTwice() async {
        let invalidStoreUrl = URL(string: "invalid://store-url")
        let sut = makeSut(storeUrl: invalidStoreUrl)
        
        await insert((makeUniqueImageFeed().local  , Date()), to: sut)
        
        await expect(sut, toRetrieve: .empty)
    }
    
    @Test("Delete has no side effects on empty cache")
    func deleteHasNoSideEffectsOnEmptyCache() async {
        let sut = makeSut()
        
        let deletionError = await deleteCache(from: sut)
        
        #expect(deletionError == nil)
        await expect(sut, toRetrieve: .empty)
    }
    
    @Test("Delete empties previously inserted cache")
    func deleteEmptiesPreviouslyInsertedCache() async {
        let sut = makeSut()
        
        await insert((makeUniqueImageFeed().local, Date()), to: sut)
        let deletionError = await deleteCache(from: sut)
        
        #expect(deletionError == nil)
        await expect(sut, toRetrieve: .empty)
    }
    
    @Test("Delete delivers error on deletion error")
    func deleteDeliversErrorOnDeletionError() async {
        let noDeletePermissionsUrl = makeCachesDirectoryUrl()
        let sut = makeSut(storeUrl: noDeletePermissionsUrl)
        
        let deletionError = await deleteCache(from: sut)
        
        #expect(deletionError != nil)
        await expect(sut, toRetrieve: .empty)
    }
    
    @Test("Store side effects run serially")
    func storeSideEffectsRunSerially() async {
        let sut = makeSut()
        var completedOperationsInOrder = [Int]()
        
        await confirmation("Operations complete", expectedCount: 3) {
            completed in
            sut.insert(makeUniqueImageFeed().local, at: Date()) { _ in
                completedOperationsInOrder.append(1)
                completed()
            }
            
            sut.deleteCachedFeed { _ in
                completedOperationsInOrder.append(2)
                completed()
            }
            
            sut.insert(makeUniqueImageFeed().local, at: Date()) { _ in
                completedOperationsInOrder.append(3)
                completed()
            }
            
            try? await Task.sleep(for: .milliseconds(500))
        }
        
        #expect(completedOperationsInOrder == [1, 2, 3])
    }
    
    // MARK: Helpers
    private func makeSut(storeUrl: URL? = nil, sourceLocation: SourceLocation = #_sourceLocation) -> FeedStore {
        let sut = CodableFeedStore(storeUrl: storeUrl ?? makeTestStoreUrl())
        sutTracker = MemoryLeakTracker(instance: sut, sourceLocation: sourceLocation)
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
    
    private func expect(_ sut: FeedStore, toRetrieve expectedResult: RetrieveCachedFeedResult, sourceLocation: SourceLocation = #_sourceLocation) async {
        await confirmation("Retrieve completion") { completed in
            await withCheckedContinuation { continuation in
                sut.retrieve { retrievedResult in
                    switch (expectedResult, retrievedResult) {
                    case (.empty, .empty), (.failure, .failure):
                        break
                    case let (.found(expectedFeed, expectedTimestamp), .found(retrievedFeed, retrievedTimestamp)):
                        #expect(retrievedFeed == expectedFeed, sourceLocation: sourceLocation)
                        #expect(retrievedTimestamp == expectedTimestamp, sourceLocation: sourceLocation)
                    default:
                        Issue.record("Expected to retrieve \(expectedResult), got \(retrievedResult) instead", sourceLocation: sourceLocation)
                    }
                    
                    continuation.resume()
                    completed()
                }
            }
        }
    }
    
    private func expect(_ sut: FeedStore, toRetrieveTwice expectedResult: RetrieveCachedFeedResult, sourceLocation: SourceLocation = #_sourceLocation) async {
        await expect(sut, toRetrieve: expectedResult)
        await expect(sut, toRetrieve: expectedResult)
    }
    
    @discardableResult
    private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: FeedStore) async -> Error? {
        var insertionError: Error?
        
        await confirmation("Insert completion") { completed in
            await withCheckedContinuation { continuation in
                sut.insert(cache.feed, at: cache.timestamp) { receivedInsertionError in
                    insertionError = receivedInsertionError
                    continuation.resume()
                    completed()
                }
            }
        }
        
        return insertionError
    }
    
    private func deleteCache(from sut: FeedStore) async -> Error? {
        var deletionError: Error?
        
        await confirmation("Delete completion") { completed in
            await withCheckedContinuation { continuation in
                sut.deleteCachedFeed { receivedDeletionError in
                    deletionError = receivedDeletionError
                    continuation.resume()
                    completed()
                }
            }
        }
        
        return deletionError
    }
}
