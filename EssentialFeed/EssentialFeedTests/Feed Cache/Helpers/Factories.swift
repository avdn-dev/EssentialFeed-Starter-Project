//
//  Factories.swift
//  EssentialFeedTests
//
//  Created by Anh Nguyen on 17/12/2024.
//

import EssentialFeed
import Foundation

func makeUniqueImage() -> FeedImage { FeedImage(id: UUID(), description: nil, location: nil, url: makeUrl()) }

func makeUniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
    let models = [makeUniqueImage(), makeUniqueImage()]
    let local = models.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
    return (models, local)
}
