//
//  FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Anh Nguyen on 18/12/2024.
//

import Foundation

protocol FeedStoreSpecs {
    func retrieveDeliversNothingOnEmptyCache() async
    func retrieveDeliversNothingOnEmptyCacheTwice() async
    func retrieveAfterInsertDeliversInsertedValues() async
    func retrieveAfterInsertDeliversInsertedValuesTwice() async
    
    func insertDeliversNoErrorOnEmptyCache() async
    func insertDeliversNoErrorOnNonemptyCache() async
    func insertOverwritesPreviousCacheValues() async
    
    func deleteDeliversNoErrorOnEmptyCache() async
    func deleteHasNoSideEffectsOnEmptyCache() async
    func deleteDeliversNoErrorOnNonemptyCache() async
    func deleteEmptiesPreviouslyInsertedCache() async
    
    func storeSideEffectsRunSerially() async
}

protocol FailableRetrieveFeedStoreSpecs: FeedStoreSpecs {
    func retrieveDeliversFailureOnRetrievalError() async
    func retrieveDeliversFailureOnRetrievalErrorTwice() async
}

protocol FailableInsertFeedStoreSpecs: FeedStoreSpecs {
    func insertDeliversErrorOnInsertionError() async
    func insertDeliversErrorOnInsertionErrorTwice() async
}

protocol FailableDeleteFeedStoreSpecs: FeedStoreSpecs {
    func deleteDeliversErrorOnDeletionError() async
    func deleteDeliversErrorOnDeletionErrorTwice() async
}

typealias FailableFeedStore = FailableRetrieveFeedStoreSpecs & FailableInsertFeedStoreSpecs & FailableDeleteFeedStoreSpecs
