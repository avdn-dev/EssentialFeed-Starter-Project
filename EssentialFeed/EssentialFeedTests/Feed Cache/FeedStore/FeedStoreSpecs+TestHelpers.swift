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
    func expect(_ sut: FeedStore, toRetrieve expectedResult: FeedStore.RetrievalResult, sourceLocation: SourceLocation = #_sourceLocation) async {
        await withCheckedContinuation { continuation in
            sut.retrieve { retrievedResult in
                switch (expectedResult, retrievedResult) {
                case (.success(.none), .success(.none)), (.failure, .failure):
                    break
                case let (.success(.some(expectedCache)), .success(.some(retrievedCache))):
                    #expect(retrievedCache.feed == expectedCache.feed, sourceLocation: sourceLocation)
                    #expect(retrievedCache.timestamp == expectedCache.timestamp, sourceLocation: sourceLocation)
                default:
                    Issue.record("Expected to retrieve \(expectedResult), got \(retrievedResult) instead", sourceLocation: sourceLocation)
                }
                
                continuation.resume()
            }
        }
    }
    
    func expect(_ sut: FeedStore, toRetrieveTwice expectedResult: FeedStore.RetrievalResult, sourceLocation: SourceLocation = #_sourceLocation) async {
        await expect(sut, toRetrieve: expectedResult)
        await expect(sut, toRetrieve: expectedResult)
    }
    
    @discardableResult
    func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async -> FeedStore.InsertionResult {
        var insertionResult: FeedStore.InsertionResult!
        
        await withCheckedContinuation { continuation in
            sut.insert(cache.feed, at: cache.timestamp) { receivedInsertionResult in
                insertionResult = receivedInsertionResult
                continuation.resume()
            }
        }
        
        return insertionResult
    }
    
    func deleteCache(from sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async -> FeedStore.DeletionResult {
        var deletionResult: FeedStore.DeletionResult!
        
        await withCheckedContinuation { continuation in
            sut.deleteCachedFeed { receivedDeletionResult in
                deletionResult = receivedDeletionResult
                continuation.resume()
            }
        }
        
        return deletionResult
    }
    
    func assertThatRetrieveDeliversNothingOnEmptyCache(on sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async {
        await expect(sut, toRetrieve: .success(.none), sourceLocation: sourceLocation)
    }
    
    func assertThatRetrieveDeliversNothingOnEmptyCacheTwice(on sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async {
        await expect(sut, toRetrieveTwice: .success(.none), sourceLocation: sourceLocation)
    }
    
    func assertThatRetrieveDeliversInitiallyInsertedValues(on sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async {
        let feed = makeUniqueImageFeed().local
        let timestamp = Date()
        
        await insert((feed, timestamp), to: sut)
        
        await expect(sut, toRetrieve: .success(CachedFeed(feed: feed, timestamp: timestamp)))
    }
    
    func assertThatRetrieveDeliversInitiallyInsertedValuesWithNoSideEffect(on sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async {
        let feed = makeUniqueImageFeed().local
        let timestamp = Date()
        
        await insert((feed, timestamp), to: sut)
        
        await expect(sut, toRetrieveTwice: .success(CachedFeed(feed: feed, timestamp: timestamp)))
    }
    
    func assertThatInsertDeliversSuccessOnEmptyCache(on sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async {
        let insertionResult = await insert((makeUniqueImageFeed().local, Date()), to: sut)
        
        switch insertionResult {
        case .success:
            break
        case let .failure(error):
            Issue.record("Expected success, got \(error) instead", sourceLocation: sourceLocation)
        }
    }
    
    func assertThatInsertDeliversSuccessOnNonemptyCache(on sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async {
        await insert((makeUniqueImageFeed().local, Date()), to: sut)
        
        let insertionResult = await insert((makeUniqueImageFeed().local, Date()), to: sut)
        
        switch insertionResult {
        case .success:
            break
        case let .failure(error):
            Issue.record("Expected success, got \(error) instead", sourceLocation: sourceLocation)
        }
    }
    
    func assertThatInsertOverwritesPreviousCacheValue(on sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async {
        await insert((makeUniqueImageFeed().local, Date()), to: sut)
        
        let latestFeed = makeUniqueImageFeed().local
        let latestTimestamp = Date()
        await insert((latestFeed, latestTimestamp), to: sut)
        
        await expect(sut, toRetrieve: .success(CachedFeed(feed: latestFeed, timestamp: latestTimestamp)), sourceLocation: sourceLocation)
    }
    
    func assertThatDeleteDeliversSuccessOnEmptyCache(on sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async {
        let deletionResult = await deleteCache(from: sut)
        
        switch deletionResult {
        case .success:
            break
        case let .failure(error):
            Issue.record("Expected success, got \(error) instead", sourceLocation: sourceLocation)
        }
    }
    
    func assertThatDeleteHasNoSideEffectsOnEmptyCache(on sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async {
        _ = await deleteCache(from: sut)

        await expect(sut, toRetrieve: .success(.none), sourceLocation: sourceLocation)
    }
    
    func assertThatDeleteDeliversSuccessOnNonemptyCache(on sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async {
        await insert((makeUniqueImageFeed().local, Date()), to: sut)
        
        let deletionResult = await deleteCache(from: sut)
        
        switch deletionResult {
        case .success:
            break
        case let .failure(error):
            Issue.record("Expected success, got \(error) instead", sourceLocation: sourceLocation)
        }
    }
    
    func assertThatDeleteEmptiesPreviouslyInsertedCache(on sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async {
        await insert((makeUniqueImageFeed().local, Date()), to: sut)
        
        _ = await deleteCache(from: sut)
        
        await expect(sut, toRetrieve: .success(.none), sourceLocation: sourceLocation)
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
