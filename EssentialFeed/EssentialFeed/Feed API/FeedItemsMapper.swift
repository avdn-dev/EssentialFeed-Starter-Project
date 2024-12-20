//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Anh Nguyen on 12/12/2024.
//

import Foundation

final class FeedItemsMapper {
    private struct Root: Decodable {
        let items:  [RemoteFeedItem]
    }
    
    private static var OK_STATUS_CODE: Int {
        return 200
    }
    
    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [RemoteFeedItem]  {
        guard response.statusCode == OK_STATUS_CODE, let root = try? JSONDecoder().decode(Root.self, from: data) else {
           throw RemoteFeedLoader.Error.invalidData
        }
        
        return root.items
    }
}
