//
//  URLSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by Joffrey Mann on 2/14/24.
//

import Foundation

public class URLSessionHTTPClient: HTTPClient {
    private var session: URLSession
    
    private struct UnexpectedValuesRepresentation: Error {}
    
    public init(session: URLSession = .shared, onResume: @escaping (Int) -> Void = { _ in }) {
        self.session = session
    }
    
    public func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let data = data, let response = response as? HTTPURLResponse {
                completion(.success(data, response))
            } else if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }.resume()
    }
}
