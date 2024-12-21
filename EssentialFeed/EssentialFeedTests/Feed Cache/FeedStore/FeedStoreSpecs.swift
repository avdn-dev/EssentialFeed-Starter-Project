//
//  FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Anh Nguyen on 18/12/2024.
//

protocol FeedStoreSpecs {
    func retrieveDeliversNothingOnEmptyCache() async
    func retrieveDeliversNothingOnEmptyCacheTwice() async
    func retrieveAfterInsertDeliversInsertedValues() async
    func retrieveAfterInsertDeliversInsertedValuesWithNoSideEffect() async
    
    func insertDeliversSuccessOnEmptyCache() async
    func insertDeliversSuccessOnNonemptyCache() async
    func insertOverwritesPreviousCacheValues() async
    
    func deleteDeliversSuccessOnEmptyCache() async
    func deleteHasNoSideEffectsOnEmptyCache() async
    func deleteDeliversSuccessOnNonemptyCache() async
    func deleteEmptiesPreviouslyInsertedCache() async
    
    func storeSideEffectsRunSerially() async
}

protocol FailableRetrieveFeedStoreSpecs: FeedStoreSpecs {
    func retrieveDeliversFailureOnRetrievalError() async
    func retrieveDeliversFailureOnRetrievalErrorWithNoSideEffect() async
}

protocol FailableInsertFeedStoreSpecs: FeedStoreSpecs {
    func insertDeliversErrorOnInsertionError() async
    func insertDeliversErrorOnInsertionErrorWithNoSideEffect() async
}

protocol FailableDeleteFeedStoreSpecs: FeedStoreSpecs {
    func deleteDeliversErrorOnDeletionError() async
    func deleteDeliversErrorOnDeletionErrorWithNoSideEffect() async
}

protocol FailableFeedStore: FailableRetrieveFeedStoreSpecs,  FailableInsertFeedStoreSpecs, FailableDeleteFeedStoreSpecs { }
