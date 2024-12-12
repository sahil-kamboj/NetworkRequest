//
//  RequestError.swift
//  NetworkRequest
//
//  Created by Sahil Kamboj on 11/12/24.
//

import Foundation

enum APIError: Error {
	case invalidURL
	case requestFailed(Error)
	case decodingError
	case invalidResponse
	case failureResponse(ErrorResponse?)
	case noData
	case unknown(Error)
	case serverError
	
	var title: String {
		return self.errorDescription().title
	}
	
	var message: String {
		return self.errorDescription().message
	}
	
	private func errorDescription() -> (title: String, message: String) {
		switch self {
			case .invalidURL:
				return ("URL Error!", "Invalid URL")
			case .requestFailed(let error):
				return ("Request Failure!", "\(error.localizedDescription)")
			case .decodingError:
				return ("Error!", "Failed to decode response data.")
			case .invalidResponse:
				return ("Error!", "Invalid response received.")
			case .failureResponse(let errorResponse):
				return ("Error!", errorResponse?.message ?? "") // "Failure response: Status not 200"
			case .noData:
				return ("Data Error!", "No Data Found")
			case .unknown(let error):
				return ("Error!", "\(error.localizedDescription)")
			case .serverError:
				return ("Server Error!", "Internal server occurred. Please try again after sometime.")
		}
	}
}
