//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Joffrey Mann on 2/5/24.
//

import Foundation

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(RemoteFeedLoader.Error)
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}
