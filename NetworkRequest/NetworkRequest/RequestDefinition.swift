//
//  RequestDefinition.swift
//  NetworkRequest
//
//  Created by Sahil Kamboj on 13/05/24.
//

import Foundation

import Foundation

enum APIError: Error {
	case invalidURL
	case requestFailed(Error)
	case decodingError
	case invalidResponse
	case failureResponse(ErrorResponse?)
	case noData
	case unknown(Error)
	case serverError(Error)
	
	var localizedDescription: String {
		switch self {
			case .invalidURL:
				return "Invalid URL"
			case .requestFailed(let error):
				return "Network request failed: \(error.localizedDescription)"
			case .decodingError:
				return "Failed to decode response data."
			case .invalidResponse:
				return "Invalid response received."
			case .failureResponse(let errorResponse):
				return errorResponse?.errors?[0].message ?? ""//"Failure response: Status not 200"
			case .noData:
				return "No Data Found"
			case .unknown(let error):
				return "\(error.localizedDescription)"
			case .serverError(let error):
				return "Server Error: \(error.localizedDescription)"
		}
	}
}

//MARK: - API Request with Data
protocol APIRequest {
	associatedtype Response: Decodable
	
	var endpoint: String { get }
	var method: String { get }
	var body: Data? { get }
	var headers: [String: String] { get }
}

// Define a struct representing a POST request
struct PostRequest<T: Codable>: APIRequest {
	typealias Response = T
	
	let endpoint: String
	let method = "POST"
	let body: Data?
	let headers: [String: String]
}

// Define a struct representing a GET request
struct GetRequest<T: Codable>: APIRequest {
	typealias Response = T
	
	var endpoint: String
	let method = "GET"
	let body: Data? = nil
	var headers: [String: String] = [:]
}

//MARK: - API Request with File Uploading
protocol MediaUploadRequest {
	associatedtype Response: Decodable
	
	var endpoint: String { get }
	var fileData: Data { get }
	var fileName: String { get }
	var mimeType: String { get }
//	var headers: [String: String] { get }
}

struct UploadFileRequest<T: Codable>: MediaUploadRequest {
	typealias Response = T
	
	let endpoint: String
	let fileData: Data
	let fileName: String
	let mimeType: String
//	let headers: [String: String]
}

// Define a service class responsible for making API requests
class NetworkRequest {
	static func request<T: APIRequest>(_ request: T, completion: @escaping (Result<T.Response, APIError>) -> Void) {
		// Create the URLRequest
		guard let url = URL(string: request.endpoint) else {
			completion(.failure(APIError.invalidURL))
			return
		}
		
		var urlRequest = URLRequest(url: url)
		urlRequest.httpMethod = request.method
		urlRequest.httpBody = request.body
		request.headers.forEach { key, value in
			urlRequest.setValue(value, forHTTPHeaderField: key)
		}
		
		// Create the URLSession data task
		let taskRequest = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
			// Handle response
			if let error = error {
				completion(.failure(APIError.requestFailed(error)))
				return
			}
			
			guard let httpResponse = response as? HTTPURLResponse else {
				completion(.failure(APIError.invalidResponse))
				return
			}
			self.getMetrics(httpResponse)
			
			switch httpResponse.statusCode {
				case 200...299:
					
					if let data = data, data.count > 0 {
						do {
//							let json = try? JSONSerialization.jsonObject(with: data, options: [])
//							print(json)
							let decodedResponse = try JSONDecoder().decode(T.Response.self, from: data)
							completion(.success(decodedResponse))
						} catch {
							completion(.failure(.unknown(error)))
						}
					} else {
						completion(.success(true as! T.Response))//NO Data error
						
					}
					
					break
					
				case 400...499:
					if let data = data {
//						let json = try? JSONSerialization.jsonObject(with: data, options: [])
//						print(json)
						let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
//						print("Decoded 400 range : ", decodedResponse)
						completion(.failure(.failureResponse(decodedResponse)))
					}
					else {
						completion(.failure(APIError.noData))//NO Data error
					}
					break
					
				case 500...599:
					if let serverError = error {
						completion(.failure(.serverError(serverError)))
					}
					break
					
				default:
					break
			}
		}
		taskRequest.resume()
	}
	
	static func uploadFile<T: MediaUploadRequest>(_ request: T, completion: @escaping (Result<T.Response, APIError>) -> Void) {
		// Create the URLRequest
		guard let url = URL(string: request.endpoint) else {
			completion(.failure(APIError.invalidURL))
			return
		}
		let boundary = "Boundary-\(UUID().uuidString)"
		
		var urlRequest = URLRequest(url: url)
		urlRequest.httpMethod = "POST"
		urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
		urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
		urlRequest.setValue("Bearer token", forHTTPHeaderField: "Authorization")
		
		// Create multipart form data
		var formContent = String()
		
		formContent.append("--\(boundary)\r\n")
		formContent.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(request.fileName)\"\r\n")
//		formContent.append("Content-Type: \(request.mimeType)\r\n\r\n")
		formContent.append("Content-Type: multipart/form-data; boundary=\(boundary)\r\n\r\n")
		formContent.append("\(request.fileData)")
		formContent.append("\r\n")
		formContent.append("--\(boundary)--\r\n")
//		print("Upload Request Form Content : \(formContent)")
		// Set the HTTP body
		var formData = Data()
		if let postData = formContent.data(using: .utf8) {
			urlRequest.httpBody = postData
		}
		
		// Create the URLSession data task
		let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
			// Handle response
			if let error = error {
				completion(.failure(APIError.requestFailed(error)))
				return
			}
			
			guard let httpResponse = response as? HTTPURLResponse else {
				completion(.failure(APIError.invalidResponse))
				return
			}
			self.getMetrics(httpResponse)
			
			guard let data = data else {
				completion(.failure(APIError.noData))//NO Data error
				return
			}
			
			switch httpResponse.statusCode {
				case 200...299:
					do {
						let decodedResponse = try JSONDecoder().decode(T.Response.self, from: data)
						completion(.success(decodedResponse))
					} catch {
						completion(.failure(.unknown(error)))
					}
					break
					
				case 400...499:
					let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
					completion(.failure(.failureResponse(decodedResponse)))
					break
					
				case 500...599:
					if let serverError = error {
						completion(.failure(.serverError(serverError)))
					}
					break
					
				default:
					break
			}
		}
		task.resume()
	}
	
	static func getMetrics(_ input: HTTPURLResponse) { // Use for refining the Console output if printing is required
		print("Request URL: ", input.url ?? "")
		print("Request Status: ", input.statusCode)
	}
}
