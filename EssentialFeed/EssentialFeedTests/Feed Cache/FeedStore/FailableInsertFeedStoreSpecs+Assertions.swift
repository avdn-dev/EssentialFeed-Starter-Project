//
//  FailableInsertFeedStoreSpecs+Assertions.swift
//  EssentialFeedTests
//
//  Created by Anh Nguyen on 18/12/2024.
//

import EssentialFeed
import Foundation
import Testing

extension FailableInsertFeedStoreSpecs {
    func assertThatInsertDeliversErrorOnInsertionError(on sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async {
        let insertionError = await insert((makeUniqueImageFeed().local  , Date()), to: sut)
        
        #expect(insertionError != nil, sourceLocation: sourceLocation)
    }
    
    func assertThatInsertDeliversErrorOnInsertionErrorWithNoSideEffect(on sut: FeedStore, sourceLocation: SourceLocation = #_sourceLocation) async {
        await insert((makeUniqueImageFeed().local  , Date()), to: sut)
        
        await expect(sut, toRetrieve: .success(.empty), sourceLocation: sourceLocation)
    }
}

