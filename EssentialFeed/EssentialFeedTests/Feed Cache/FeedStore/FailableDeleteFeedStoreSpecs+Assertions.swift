//
//  FailableDeleteFeedStoreSpecs+Assertions.swift
//  EssentialFeedTests
//
//  Created by Anh Nguyen on 18/12/2024.
//

import EssentialFeed
import Foundation
import Testing

extension FailableDeleteFeedStoreSpecs {
    func assertThatDeleteDeliversErrorOnDeletionError(on sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async {
        let deletionError = await deleteCache(from: sut)
        
        #expect(deletionError != nil, sourceLocation: sourceLocation)
    }
    
    func assertThatDeleteDeliversErrorOnDeletionErrorWithNoSideEffect(on sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async {
        _ = await deleteCache(from: sut)
        
        await expect(sut, toRetrieve: .success(.empty), sourceLocation: sourceLocation)
    }
}
