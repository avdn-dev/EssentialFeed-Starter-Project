//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Anh Nguyen on 12/12/2024.
//

import Foundation

internal struct RemoteFeedItem: Decodable {
    internal let id: UUID
    internal let description: String?
    internal let location: String?
    internal let image: URL
}

internal final class FeedItemsMapper {
    private struct Root: Decodable {
        let items:  [RemoteFeedItem]
    }
    
    private static var OK_STATUS_CODE: Int {
        return 200
    }
    
    internal static func map(_ data: Data, from response: HTTPURLResponse) throws -> [RemoteFeedItem]  {
        guard response.statusCode == OK_STATUS_CODE, let root = try? JSONDecoder().decode(Root.self, from: data) else {
           throw RemoteFeedLoader.Error.invalidData
        }
        
        return root.items
    }
}
