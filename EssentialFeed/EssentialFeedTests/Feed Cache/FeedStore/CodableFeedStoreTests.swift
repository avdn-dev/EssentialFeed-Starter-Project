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
final class CodableFeedStoreTests: FailableFeedStore {
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
        
        await assertThatRetrieveDeliversNothingOnEmptyCache(on: sut)
    }
    
    @Test("Retrieve delivers nothing on empty cache twice with no side effect")
    func retrieveDeliversNothingOnEmptyCacheTwice() async {
        let sut = makeSut()
        
        await assertThatRetrieveDeliversNothingOnEmptyCacheTwice(on: sut)
    }
    
    @Test("Retrieve after insert into empty cache returns initially inserted values")
    func retrieveAfterInsertDeliversInsertedValues() async {
        let sut = makeSut()
        
        await assertThatRetrieveDeliversInitiallyInsertedValues(on: sut)
    }
    
    @Test("Retrieve after insert into empty cache returns initially inserted values with no side effect")
    func retrieveAfterInsertDeliversInsertedValuesWithNoSideEffect() async {
        let sut = makeSut()
        
        await assertThatRetrieveDeliversInitiallyInsertedValuesWithNoSideEffect(on: sut)
    }
    
    @Test("Retrieve delivers failure on retrieval error")
    func retrieveDeliversFailureOnRetrievalError() async {
        let storeUrl = makeTestStoreUrl()
        let sut = makeSut(storeUrl: storeUrl)
        
        try! "invalid data".write(to: storeUrl, atomically: false, encoding: .utf8)
        
        await assertThatRetrieveDeliversFailureOnRetrievalError(on: sut)
    }
    
    @Test("Retrieve delivers failure on retrieval error with no side effect")
    func retrieveDeliversFailureOnRetrievalErrorWithNoSideEffect() async {
        let storeUrl = makeTestStoreUrl()
        let sut = makeSut(storeUrl: storeUrl)
        
        try! "invalid data".write(to: storeUrl, atomically: false, encoding: .utf8)
        
        await assertThatRetrieveDeliversFailureOnRetrievalErrorWithNoSideEffect(on: sut)
    }
    
    @Test("Insert delivers no error on empty cache")
    func insertDeliversNoErrorOnEmptyCache() async {
        let sut = makeSut()
        
        await assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
    }
    
    @Test("Insert delivers no error on nonempty cache")
    func insertDeliversNoErrorOnNonemptyCache() async {
        let sut = makeSut()
        
        await assertThatInsertDeliversNoErrorOnNonemptyCache(on: sut)
    }
    
    @Test("Insert overwrites previously inserted cache values")
    func insertOverwritesPreviousCacheValues() async {
        let sut = makeSut()
        
        await assertThatInsertOverwritesPreviousCacheValue(on: sut)
    }
    
    @Test("Insert delivers error on insertion error")
    func insertDeliversErrorOnInsertionError() async {
        let invalidStoreUrl = URL(string: "invalid://store-url")
        let sut = makeSut(storeUrl: invalidStoreUrl)
        
        await assertThatInsertDeliversErrorOnInsertionError(on: sut)
    }
    
    @Test("Insert delivers error on insertion error with no side effect")
    func insertDeliversErrorOnInsertionErrorWithNoSideEffect() async {
        let invalidStoreUrl = URL(string: "invalid://store-url")
        let sut = makeSut(storeUrl: invalidStoreUrl)
        
        await assertThatInsertDeliversErrorOnInsertionErrorWithNoSideEffect(on: sut)
    }
    
    @Test("Delete delivers no error on empty cache")
    func deleteDeliversNoErrorOnEmptyCache() async {
        let sut = makeSut()
        
        await assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
    }
    
    @Test("Delete has no side effects on empty cache")
    func deleteHasNoSideEffectsOnEmptyCache() async {
        let sut = makeSut()
        
        await assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
    }
    
    @Test("Delete delivers no error on nonempty cache")
    func deleteDeliversNoErrorOnNonemptyCache() async {
        let sut = makeSut()
        
        await assertThatDeleteDeliversNoErrorOnNonemptyCache(on: sut)
    }
    
    @Test("Delete empties previously inserted cache")
    func deleteEmptiesPreviouslyInsertedCache() async {
        let sut = makeSut()
        
        await assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
    }
    
    @Test("Delete delivers error on deletion error")
    func deleteDeliversErrorOnDeletionError() async {
        let noDeletePermissionsUrl = makeCachesDirectoryUrl()
        let sut = makeSut(storeUrl: noDeletePermissionsUrl)
        
        await assertThatDeleteDeliversErrorOnDeletionError(on: sut)
    }
    
    @Test("Delete delivers error on deletion error with no side effect")
    func deleteDeliversErrorOnDeletionErrorWithNoSideEffect() async {
        let noDeletePermissionsUrl = makeCachesDirectoryUrl()
        let sut = makeSut(storeUrl: noDeletePermissionsUrl)
        
        await assertThatDeleteDeliversErrorOnDeletionErrorWithNoSideEffect(on: sut)
    }
    
    @Test("Store side effects run serially")
    func storeSideEffectsRunSerially() async {
        let sut = makeSut()
        
        await assertThatStoreSideEffectsRunSerially(on: sut)
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
}
