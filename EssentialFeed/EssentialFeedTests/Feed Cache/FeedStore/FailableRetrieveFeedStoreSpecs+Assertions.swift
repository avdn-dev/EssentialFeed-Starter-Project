//
//  FailableRetrieveFeedStoreSpecs+Assertions.swift
//  EssentialFeedTests
//
//  Created by Anh Nguyen on 18/12/2024.
//

import EssentialFeed
import Foundation
import Testing

extension FailableRetrieveFeedStoreSpecs {
    func assertThatRetrieveDeliversFailureOnRetrievalError(on sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async {
        await expect(sut, toRetrieve: .failure(makeNsError()), sourceLocation: sourceLocation)
    }
    
    func assertThatRetrieveDeliversFailureOnRetrievalErrorTwice(on sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async {
        await expect(sut, toRetrieveTwice: .failure(makeNsError()), sourceLocation: sourceLocation)
    }
}
