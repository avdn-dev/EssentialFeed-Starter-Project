//
//  Date+CreationHelpers.swift
//  EssentialFeedTests
//
//  Created by Anh Nguyen on 17/12/2024.
//

import Foundation

extension Date {
    private var feedCacheMaxAgeInDays: Int { 7 }
    
    func minusCacheFeedMaxAge() -> Date { self.adding(days: -feedCacheMaxAgeInDays) }
    
    private func adding(days: Int) -> Date { Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)! }
}

extension Date {
    func adding(seconds: TimeInterval) -> Date { self.addingTimeInterval(seconds) }
}
