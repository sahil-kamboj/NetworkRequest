//
//  RequestProtocol.swift
//  NetworkRequest
//
//  Created by Sahil Kamboj on 11/12/24.
//

import Foundation

//MARK: - API Request with Data
enum RequestMethod: String {
	case get = "GET"
	case post = "POST"
	case put = "PUT"
	case patch = "PATCH"
	case delete = "DELETE"
}

protocol APIRequest {
	associatedtype Response: Decodable
	
	var endpoint: String { get }
	var method: RequestMethod { get }
	var body: Data? { get }
	var headers: [String: String] { get }
}

//MARK: - API Request with File Uploading
protocol MediaUploadRequest {
	associatedtype Response: Decodable
	
	var endpoint: String { get }
	var fileData: Data { get }
	var fileName: String { get }
	var mimeType: String { get }
}
