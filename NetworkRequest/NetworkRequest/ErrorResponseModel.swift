//
//  ErrorResponseModel.swift
//  NetworkRequest
//
//  Created by Sahil Kamboj on 13/05/24.
//

import Foundation

// MARK: - ErrorType
struct ErrorResponse: Codable {
	let errors: [ErrorType]?
}

// MARK: - Error
struct ErrorType: Codable {
	let message, type: String?
}
