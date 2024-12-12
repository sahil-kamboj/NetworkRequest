//
//  ErrorResponse.swift
//  NetworkRequest
//
//  Created by Sahil Kamboj on 13/05/24.
//

import Foundation

// MARK: - ErrorResponse
struct ErrorResponse: Codable {
	let status, message: String
	let code: Int
}
