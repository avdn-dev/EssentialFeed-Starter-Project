//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Anh Nguyen on 12/12/2024.
//

import Foundation

public protocol HTTPClient {
    typealias Result = Swift.Result<(Data, HTTPURLResponse), Error>
    
    /// The completion hanler can be invoked in any thread.
    /// Clients are responssible for dispatching to appropriate threads, if needed.
    func get(from url: URL, completion: @escaping (Result) -> Void)
}
