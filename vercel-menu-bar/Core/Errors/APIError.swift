//
//  APIError.swift
//  Vercel Menu Bar
//
//  Copyright (c) 2026 Ryan Marcus
//  Licensed under the MIT License
//
import Foundation

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidResponse
    case invalidToken
    case missingToken
    case forbidden(message: String?)
    case httpError(Int, message: String = "")
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidToken:
            return "Invalid API token"
        case .missingToken:
            return "API token is missing"
        case .forbidden(let message):
            return message ?? "Access forbidden"
        case .httpError(let code, let message):
            return "HTTP error: \(code)\(message)"
        }
    }
}

// MARK: - Vercel Error Response

struct VercelErrorResponse: Decodable {
    let error: VercelErrorDetail?
}

struct VercelErrorDetail: Decodable {
    let code: String?
    let message: String?
    let invalidToken: Bool?
    let missingToken: Bool?
}
