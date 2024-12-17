//
//  LocalFeedItem.swift
//  EssentialFeed
//
//  Created by Anh Nguyen on 16/12/2024.
//

import Foundation

public struct LocalFeedImage: Equatable, Codable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let url: URL
    
    // Memberwise initialiser is not public, so it is not visible to e.g. testing target
    public init(id: UUID, description: String?, location: String?, url: URL) {
        self.id = id
        self.description = description
        self.location = location
        self.url = url
    }
}
