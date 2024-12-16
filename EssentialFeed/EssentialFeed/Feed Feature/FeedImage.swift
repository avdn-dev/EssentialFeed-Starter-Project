//
//  Copyright © Essential Developer. All rights reserved.
//

import Foundation

public struct FeedImage: Equatable {
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
