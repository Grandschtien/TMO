//
//  NetworkManager.swift
//  NIR
//
//  Created by Егор Шкарин on 04.04.2022.
//

import Foundation

enum NetworkErrors: Error {
    case badUrl
    case noInternetConnection
    case internalError
}

final class NetworkManager {
    static let shared = NetworkManager()
    private init() {}
    
    func downloadImage(urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw NetworkErrors.badUrl
        }
        guard let (data, response) = try? await URLSession.shared.data(from: url) else {
            throw NetworkErrors.noInternetConnection
        }
        guard let response = response as? HTTPURLResponse else {
            throw NetworkErrors.noInternetConnection
        }
        if response.statusCode >= 200 && response.statusCode < 300 {
            return data
        } else {
            throw NetworkErrors.internalError
        }
        
    }
}
