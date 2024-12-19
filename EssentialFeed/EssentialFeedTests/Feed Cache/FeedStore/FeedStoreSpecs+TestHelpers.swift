//
//  FeedStoreSpecs+TestHelpers.swift
//  EssentialFeedTests
//
//  Created by Anh Nguyen on 18/12/2024.
//

import EssentialFeed
import Foundation
import Testing

extension FeedStoreSpecs {
    func expect(_ sut: FeedStore, toRetrieve expectedResult: RetrieveCachedFeedResult, sourceLocation: SourceLocation = #_sourceLocation) async {
        await confirmation("Retrieve completion", sourceLocation: sourceLocation) { completed in
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
    
    func expect(_ sut: FeedStore, toRetrieveTwice expectedResult: RetrieveCachedFeedResult, sourceLocation: SourceLocation = #_sourceLocation) async {
        await expect(sut, toRetrieve: expectedResult)
        await expect(sut, toRetrieve: expectedResult)
    }
    
    @discardableResult
    func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async -> Error? {
        var insertionError: Error?
        
        await confirmation("Insert completion", sourceLocation: sourceLocation) { completed in
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
    
    func deleteCache(from sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async -> Error? {
        var deletionError: Error?
        
        await confirmation("Delete completion", sourceLocation: sourceLocation) { completed in
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
    
    func assertThatRetrieveDeliversNothingOnEmptyCache(on sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async {
        await expect(sut, toRetrieve: .empty, sourceLocation: sourceLocation)
    }
    
    func assertThatRetrieveDeliversNothingOnEmptyCacheTwice(on sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async {
        await expect(sut, toRetrieveTwice: .empty, sourceLocation: sourceLocation)
    }
    
    func assertThatRetrieveDeliversInitiallyInsertedValues(on sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async {
        let feed = makeUniqueImageFeed().local
        let timestamp = Date()
        
        await insert((feed, timestamp), to: sut)
        
        await expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp))
    }
    
    func assertThatRetrieveDeliversInitiallyInsertedValuesWithNoSideEffect(on sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async {
        let feed = makeUniqueImageFeed().local
        let timestamp = Date()
        
        await insert((feed, timestamp), to: sut)
        
        await expect(sut, toRetrieveTwice: .found(feed: feed, timestamp: timestamp))
    }
    
    func assertThatInsertDeliversNoErrorOnEmptyCache(on sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async {
        let insertionError = await insert((makeUniqueImageFeed().local, Date()), to: sut)
        
        #expect(insertionError == nil, sourceLocation: sourceLocation)
    }
    
    func assertThatInsertDeliversNoErrorOnNonemptyCache(on sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async {
        await insert((makeUniqueImageFeed().local, Date()), to: sut)
        
        let insertionError = await insert((makeUniqueImageFeed().local, Date()), to: sut)
        
        #expect(insertionError == nil, sourceLocation: sourceLocation)
    }
    
    func assertThatInsertOverwritesPreviousCacheValue(on sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async {
        await insert((makeUniqueImageFeed().local, Date()), to: sut)
        
        let latestFeed = makeUniqueImageFeed().local
        let latestTimestamp = Date()
        await insert((latestFeed, latestTimestamp), to: sut)
        
        await expect(sut, toRetrieve: .found(feed: latestFeed, timestamp: latestTimestamp), sourceLocation: sourceLocation)
    }
    
    func assertThatDeleteDeliversNoErrorOnEmptyCache(on sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async {
        let deletionError = await deleteCache(from: sut)
        
        #expect(deletionError == nil, sourceLocation: sourceLocation)
    }
    
    func assertThatDeleteHasNoSideEffectsOnEmptyCache(on sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async {
        _ = await deleteCache(from: sut)

        await expect(sut, toRetrieve: .empty, sourceLocation: sourceLocation)
    }
    
    func assertThatDeleteDeliversNoErrorOnNonemptyCache(on sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async {
        await insert((makeUniqueImageFeed().local, Date()), to: sut)
        
        let deletionError = await deleteCache(from: sut)
        
        #expect(deletionError == nil, sourceLocation: sourceLocation)
    }
    
    func assertThatDeleteEmptiesPreviouslyInsertedCache(on sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async {
        await insert((makeUniqueImageFeed().local, Date()), to: sut)
        
        _ = await deleteCache(from: sut)
        
        await expect(sut, toRetrieve: .empty, sourceLocation: sourceLocation)
    }
    
    func assertThatStoreSideEffectsRunSerially(on sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async {
        var completedOperationsInOrder = [Int]()
        
        await confirmation("Operations complete", expectedCount: 3, sourceLocation: sourceLocation) {
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
        
        #expect(completedOperationsInOrder == [1, 2, 3], sourceLocation: sourceLocation)
    }
}
