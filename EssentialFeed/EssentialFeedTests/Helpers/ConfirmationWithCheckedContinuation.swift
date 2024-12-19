//
//  ConfirmationWithCheckedContinuation.swift
//  EssentialFeedTests
//
//  Created by Anh Nguyen on 19/12/2024.
//

import Foundation
import Testing

func confirmationWithCheckedContinuation(
    _ comment: Comment,
    expectedCount: Int = 1,
    sourceLocation: SourceLocation = #_sourceLocation,
    _ body: (ConfirmationWithContinuation) -> Void
) async {
    await confirmation(comment, expectedCount: expectedCount, sourceLocation: sourceLocation) { confirmation in
        await withCheckedContinuation { continuation in
            body(ConfirmationWithContinuation(confirmation: confirmation, continuation: continuation))
        }
    }
}

struct ConfirmationWithContinuation {
    let confirmation: Confirmation
    let continuation: CheckedContinuation<Void, Never>
    
    func callAsFunction() {
        continuation.resume()
        confirmation()
    }
}
