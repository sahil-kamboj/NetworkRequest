//
//  RequestMethods.swift
//  NetworkRequest
//
//  Created by Sahil Kamboj on 11/12/24.
//

import Foundation

// Define a service class responsible for making API requests
class NetworkRequest {
	
	// Request Method with Completion Block implementation
	static func requestWithCompletion<T: APIRequest>(_ request: T, completion: @escaping (Result<T.Response, APIError>) -> Void) {
		guard let url = URL(string: request.endpoint) else {
			completion(.failure(APIError.invalidURL))
			return
		}
		
		var urlRequest = URLRequest(url: url)
		urlRequest.httpMethod = request.method.rawValue
		urlRequest.httpBody = request.body
		request.headers.forEach { key, value in
			urlRequest.setValue(value, forHTTPHeaderField: key)
		}
		
		let taskRequest = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
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
							// let json = try? JSONSerialization.jsonObject(with: data, options: [])
							let decodedResponse = try JSONDecoder().decode(T.Response.self, from: data)
							completion(.success(decodedResponse))
						} catch {
							completion(.failure(.unknown(error)))
						}
					} else {
						completion(.success(true as! T.Response)) // NO Data error
					}
					
					break
					
				case 400...499:
					if let data = data {
						// let json = try? JSONSerialization.jsonObject(with: data, options: [])
						let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
						completion(.failure(.failureResponse(decodedResponse)))
					}
					else {
						completion(.failure(APIError.noData)) // NO Data error
					}
					break
					
				case 500...599:
					completion(.failure(.serverError))
					break
					
				default:
					break
			}
		}
		taskRequest.resume()
	}
	
	// Request Method with async-await implementation
	static func requestWithAsync<T: APIRequest>(_ request: T) async throws -> T.Response {
		guard let url = URL(string: request.endpoint) else {
			throw APIError.invalidURL
		}
		
		var urlRequest = URLRequest(url: url)
		urlRequest.httpMethod = request.method.rawValue
		urlRequest.httpBody = request.body
		request.headers.forEach { key, value in
			urlRequest.setValue(value, forHTTPHeaderField: key)
		}
		
		do {
			let (data, response) = try await URLSession.shared.data(for: urlRequest)
			
			guard let httpResponse = response as? HTTPURLResponse else {
				throw APIError.invalidResponse
			}
			
			self.getMetrics(httpResponse)
			
			switch httpResponse.statusCode {
			case 200...299:
				if data.count > 0 {
					do {
						let decodedResponse = try JSONDecoder().decode(T.Response.self, from: data)
						return decodedResponse
					} catch {
						throw APIError.unknown(error)
					}
				} else {
					guard let response = true as? T.Response else {
						throw APIError.noData
					}
					return response
				}
				
			case 400...499:
				if data.count > 0 {
					let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
					throw APIError.failureResponse(decodedResponse)
				} else {
					throw APIError.noData
				}
				
			case 500...599:
				throw APIError.serverError
				
			default:
				throw APIError.unknown(Error.self as! Error)
			}
		} catch {
			throw APIError.requestFailed(error)
		}
	}
	
	// Upload File Method with Completion Block implementation
	static func uploadFileWithCompletion<T: MediaUploadRequest>(_ request: T, completion: @escaping (Result<T.Response, APIError>) -> Void) {
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
		
		let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
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
				completion(.failure(APIError.noData)) // NO Data error
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
					completion(.failure(.serverError))
					break
					
				default:
					break
			}
		}
		task.resume()
	}
	
	
	// Upload Request Method with async-await implementation
	static func uploadFileWithAsync<T: MediaUploadRequest>(_ request: T) async throws -> T.Response {
		guard let url = URL(string: request.endpoint) else {
			throw APIError.invalidURL
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
		formContent.append("Content-Type: multipart/form-data; boundary=\(boundary)\r\n\r\n")
		formContent.append("\(request.fileData)")
		formContent.append("\r\n")
		formContent.append("--\(boundary)--\r\n")
		
//		print("Upload Request Form Content : \(formContent)")
		
		if let postData = formContent.data(using: .utf8) {
			urlRequest.httpBody = postData
		}
		
		let (data, response) = try await URLSession.shared.data(for: urlRequest)
			
		guard let httpResponse = response as? HTTPURLResponse else {
			throw APIError.invalidResponse
		}
		self.getMetrics(httpResponse)
			
		switch httpResponse.statusCode {
		case 200...299:
			do {
				let decodedResponse = try JSONDecoder().decode(T.Response.self, from: data)
				return decodedResponse
			} catch {
				throw APIError.unknown(error)
			}
			
		case 400...499:
			let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
			throw APIError.failureResponse(decodedResponse)
			
		case 500...599:
			throw APIError.serverError
			
		default:
			throw APIError.invalidResponse
		}
	}
	
	static func getMetrics(_ input: HTTPURLResponse) { // Use for refining the Console output if printing is required
		print("Request URL: ", input.url ?? "")
		print("Request Status: ", input.statusCode)
	}
}
