//
//  FeedCachePolicy.swift
//  EssentialFeed
//
//  Created by Anh Nguyen on 17/12/2024.
//

import Foundation

internal enum FeedCachePolicy {
    private static let calendar = Calendar(identifier: .gregorian)
    private static let maxCacheAgeInDays = 7
    
    static func validate(_ timestamp: Date, against date: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
            return false
        }
        
        return date < maxCacheAge
    }
}
