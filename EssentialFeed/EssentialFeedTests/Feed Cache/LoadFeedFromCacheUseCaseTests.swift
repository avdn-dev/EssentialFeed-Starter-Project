//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Anh Nguyen on 16/12/2024.
//

import EssentialFeed
import Foundation
import Testing

final class LoadFeedFromCacheUseCaseTests {
    private var sutTracker: MemoryLeakTracker<LocalFeedLoader>?
    private var storeTracker: MemoryLeakTracker<FeedStoreSpy>?
    
    deinit {
        sutTracker?.verifyDeallocation()
        storeTracker?.verifyDeallocation()
    }
    
    @Test("LocalFeedLoader does not message store upon initialisation")
    func initialiserDoesNotMessageStore() {
        let (_, store) = makeSut()
        
        #expect(store.receivedMessages == [])
    }
    
    @Test("Load requests cache retrieval")
    func loadRequestsCacheRetrieval() {
        let (sut, store) = makeSut()
        
        sut.load { _ in }
        
        #expect(store.receivedMessages == [.retrieve])
    }
    
    @Test("Load fails on retrieval error")
    func loadFailsOnRetrievalError() async {
        let (sut, store) = makeSut()
        let retrievalError = makeNsError()
        
        await expect(sut, toCompleteWith: .failure(retrievalError)) {
            store.completeRetrieval(with: retrievalError)
        }
    }
    
    @Test("Load delivers no images when cache is empty")
    func loadDeliversNoImagesOnEmptyCache() async throws {
        let (sut, store) = makeSut()
        
        await expect(sut, toCompleteWith: .success([])) {
            store.completeRetrievalWithEmptyCache()
        }
    }
    
    // MARK: Helpers
    private func makeSut(currentDate: @escaping () -> Date = Date.init, sourceLocation: SourceLocation = #_sourceLocation) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        sutTracker = MemoryLeakTracker(instance: sut, sourceLocation: sourceLocation)
        storeTracker = MemoryLeakTracker(instance: store, sourceLocation: sourceLocation)
        return (sut, store)
    }
    
    private func makeNsError() -> NSError { NSError(domain: "any error", code: 1) }
    
    private func expect(_ sut: LocalFeedLoader, toCompleteWith expectedResult: LocalFeedLoader.LoadResult, when action: () -> Void, sourceLocation: SourceLocation = #_sourceLocation) async {
        await confirmation("Load completion") { loaded in
            sut.load { receivedResult in
                switch (receivedResult, expectedResult ) {
                case let (.success(receivedImages), .success(expectedImages)):
                    #expect(receivedImages == expectedImages, sourceLocation: sourceLocation)
                case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                    #expect(receivedError == expectedError, sourceLocation: sourceLocation)
                default:
                    Issue.record("Expected result \(expectedResult), got \(receivedResult) instead", sourceLocation: sourceLocation)
                }
                
                loaded()
            }
             
            action()
        }
    }
}

