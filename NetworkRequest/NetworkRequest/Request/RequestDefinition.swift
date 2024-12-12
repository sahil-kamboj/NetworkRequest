//
//  RequestDefinition.swift
//  NetworkRequest
//
//  Created by Sahil Kamboj on 13/05/24.
//

import Foundation

// Define a struct representing a POST request
struct PostRequest<T: Codable>: APIRequest {
	typealias Response = T
	
	let endpoint: String
	let method: RequestMethod = .post
	let body: Data?
	let headers: [String: String]
}

// Define a struct representing a GET request
struct GetRequest<T: Codable>: APIRequest {
	typealias Response = T
	
	var endpoint: String
	let method: RequestMethod = .get
	let body: Data? = nil
	var headers: [String: String] = [:]
}

// Define a struct representing a File Upload Request
struct UploadFileRequest<T: Codable>: MediaUploadRequest {
	typealias Response = T
	
	let endpoint: String
	let fileData: Data
	let fileName: String
	let mimeType: String
}
