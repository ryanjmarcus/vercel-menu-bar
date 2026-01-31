//
//  APIError.swift
//  vercel-menu
//
//  Created by Ryan Marcus on 1/28/26.
//

import Foundation

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidResponse
    case unauthorized
    case forbidden
    case httpError(Int, message: String = "")
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Invalid API key"
        case .forbidden:
            return "Access forbidden - check API key permissions"
        case .httpError(let code, let message):
            return "HTTP error: \(code)\(message)"
        }
    }
}
