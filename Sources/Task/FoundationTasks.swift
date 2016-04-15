//
//  FoundationTasks.swift
//  Deferred
//
//  Created by Zachary Waldowski on 1/10/16.
//  Copyright © 2016 Big Nerd Ranch. Licensed under MIT.
//

#if SWIFT_PACKAGE
import Deferred
import Result
#endif
import Foundation

private func needsNoDataFallback(for request: NSURLRequest) -> Bool {
    switch request.HTTPMethod {
    case "GET"?, "POST"?, "PATCH"?:
        return false
    default:
        return true
    }
}

extension NSURLSession {

    private func beginTask<URLTask: NSURLSessionTask>(@noescape configurator configure: URLTask throws -> Void, @noescape makeTask: (completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> URLTask, @autoclosure(escaping) needsDefaultData: () -> Bool) rethrows -> Task<(NSData, NSURLResponse)> {
        let deferred = Deferred<Task<(NSData, NSURLResponse)>.Result>()
        func handleCompletion(data: NSData?, response: NSURLResponse?, error: NSError?) {
            if let error = error {
                deferred.fail(error)
            } else if let response = response {
                deferred.succeed((data ?? NSData(), response))
            } else {
                deferred.fail(NSURLError.BadServerResponse)
            }
        }

        let task = makeTask(completionHandler: handleCompletion)
        try configure(task)
        defer { task.resume() }
        return Task(deferred, cancellation: task.cancel)
    }

    // MARK: - Sending and Recieving Small Data

    /// Returns the data from the contents of a URL, based on `request`, as a
    /// future.
    ///
    /// The session bypasses delegate methods for result delivery. Delegate
    /// methods for handling authentication challenges are still called.
    ///
    /// - parameter request: Object that provides the URL, body data, and so on.
    /// - parameter configure: An optional callback for setting properties on
    ///   the URL task.
    public func beginDataTask(request request: NSURLRequest, @noescape configure: NSURLSessionDataTask throws -> Void) rethrows -> Task<(NSData, NSURLResponse)> {
        return try beginTask(configurator: configure, makeTask: { completionHandler in
            dataTaskWithRequest(request, completionHandler: completionHandler)
        }, needsDefaultData: needsNoDataFallback(for: request))
    }

    /// Returns the data from the contents of a URL, based on `request`, as a
    /// future.
    public func beginDataTask(request request: NSURLRequest) -> Task<(NSData, NSURLResponse)> {
        return beginDataTask(request: request) { _ in }
    }

    // MARK: - Uploading Data

    /// Returns the data from uploading the optional `bodyData` as a future.
    ///
    /// The session bypasses delegate methods for result delivery. Delegate
    /// methods for handling authentication challenges are still called.
    ///
    /// - parameter request: Object that provides the URL, body data, and so on.
    ///   The body stream and body data are ignored.
    /// - parameter configure: An optional callback for setting properties on
    ///   the URL task.
    public func beginUploadTask(request request: NSURLRequest, fromData bodyData: NSData? = nil, @noescape configure: NSURLSessionUploadTask throws -> Void) rethrows -> Task<(NSData, NSURLResponse)> {
        return try beginTask(configurator: configure, makeTask: { completionHandler in
            uploadTaskWithRequest(request, fromData: bodyData, completionHandler: completionHandler)
        }, needsDefaultData: true)
    }

    /// Returns the data from uploading the optional `bodyData` as a future.
    public func beginUploadTask(request request: NSURLRequest, fromData bodyData: NSData? = nil) -> Task<(NSData, NSURLResponse)> {
        return beginUploadTask(request: request, fromData: bodyData) { _ in }
    }

    /// Returns the data from uploading the file at `fileURL` as a future.
    ///
    /// The session bypasses delegate methods for result delivery. Delegate
    /// methods for handling authentication challenges are still called.
    ///
    /// - parameter request: Object that provides the URL, body data, and so on.
    ///   The body stream and body data are ignored.
    /// - parameter configure: An optional callback for setting properties on
    ///   the URL task.
    public func beginUploadTask(request request: NSURLRequest, fromFile fileURL: NSURL, @noescape configure: NSURLSessionUploadTask throws -> Void) rethrows -> Task<(NSData, NSURLResponse)> {
        return try beginTask(configurator: configure, makeTask: { completionHandler in
            uploadTaskWithRequest(request, fromFile: fileURL, completionHandler: completionHandler)
        }, needsDefaultData: true)
    }

    /// Returns the data from uploading the file at `fileURL` as a future.
    public func beginUploadTask(request request: NSURLRequest, fromFile fileURL: NSURL) -> Task<(NSData, NSURLResponse)> {
        return beginUploadTask(request: request, fromFile: fileURL) { _ in }
    }

}
