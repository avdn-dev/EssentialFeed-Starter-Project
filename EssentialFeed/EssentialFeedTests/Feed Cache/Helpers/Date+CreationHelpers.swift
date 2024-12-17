//
//  Date+CreationHelpers.swift
//  EssentialFeedTests
//
//  Created by Anh Nguyen on 17/12/2024.
//

import Foundation

internal extension Date {
    func adding(days: Int) -> Date { Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)! }
    
    func adding(seconds: TimeInterval) -> Date { self.addingTimeInterval(seconds) }
}