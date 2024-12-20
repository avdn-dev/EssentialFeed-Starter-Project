//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Anh Nguyen on 12/12/2024.
//

import Foundation

public typealias HTTPClientResult = Result<(Data, HTTPURLResponse), Error>

public protocol HTTPClient {
    /// The completion hanler can be invoked in any thread.
    /// Clients are responssible for dispatching to appropriate threads, if needed.
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}
