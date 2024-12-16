//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Anh Nguyen on 16/12/2024.
//

import Foundation

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    func insert(_ items: [LocalFeedItem], at timestamp: Date, completion: @escaping InsertionCompletion)
}
