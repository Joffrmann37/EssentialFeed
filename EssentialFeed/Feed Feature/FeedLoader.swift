//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Joffrey Mann on 1/29/24.
//

import Foundation

public enum LoadFeedResult<Error: Swift.Error> {
    case success([FeedItem])
    case failure(RemoteFeedLoader.Error)
}

public protocol FeedLoader {
    associatedtype Error: Swift.Error
    func load(completion: @escaping (LoadFeedResult<Error>) -> Void)
}
