//
//  SharedFactories.swift
//  EssentialFeedTests
//
//  Created by Anh Nguyen on 17/12/2024.
//

import Foundation

internal func makeUrl() -> URL { URL(string: "https://a-url.com")! }

internal func makeNsError() -> NSError { NSError(domain: "any error", code: 1) }
