//
//  TaskTests.swift
//  DeferredTests
//
//  Created by John Gallagher on 7/1/15.
//  Copyright © 2014-2015 Big Nerd Ranch. Licensed under MIT.
//

import XCTest
#if SWIFT_PACKAGE
import Result
import Deferred
@testable import Task
#else
@testable import Deferred
#endif

func mockCancellation(expectation: XCTestExpectation?)() -> Void {
    expectation?.fulfill()
}

class CancellableTaskTests: XCTestCase {

    func testThatFlatMapForwardsCancellationToSubsequentTask() {
        let firstTask = Task<Int, NoError>(value: .Success(1))
        let expectation = expectationWithDescription("flatMapped task is cancelled")
        let mappedTask = firstTask.flatMap { _ -> Task<Int, NoError> in
            let d = Deferred<Result<Int, NoError>>()
            return Task(d, cancellation: mockCancellation(expectation))
        }
        mappedTask.cancel()
        waitForExpectationsWithTimeout(TestTimeout, handler: nil)
    }

    func testThatFlatMapSuccessForwardsCancellationToSubsequentTask() {
        let firstTask = Task<Int, NoError>(value: .Success(1))
        let expectation = expectationWithDescription("flatMapped task is cancelled")
        let mappedTask = firstTask.flatMapSuccess { _ -> Task<Int, NoError> in
            let d = Deferred<Result<Int, NoError>>()
            return Task<Int, NoError>(d, cancellation: mockCancellation(expectation))
        }
        mappedTask.cancel()
        waitForExpectationsWithTimeout(TestTimeout, handler: nil)
    }

}
