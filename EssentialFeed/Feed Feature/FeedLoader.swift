//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Joffrey Mann on 1/29/24.
//

import Foundation

enum LoadFeedResult {
    case success([FeedItem])
    case error(Error)
}

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
