//
//  Copyright © Essential Developer. All rights reserved.
//

import Foundation

public struct FeedItem: Equatable {
	public let id: UUID
	public let description: String?
	public let location: String?
	public let imageUrl: URL
    
    // Memberwise initialiser is not public, so it is not visible to e.g. testing target
    public init(id: UUID, description: String?, location: String?, imageUrl: URL) {
        self.id = id
        self.description = description
        self.location = location
        self.imageUrl = imageUrl
    }
}
