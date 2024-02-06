//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Joffrey Mann on 1/29/24.
//

import Foundation

public enum LoadFeedResult {
    case success([FeedItem])
    case failure(RemoteFeedLoader.Error)
}

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
