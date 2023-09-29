import Foundation
public protocol NetworkServicerPotocol {
	func request<T>(_ request: Urlable, complition: @escaping (Result<T, Error>) -> Void) where T: Decodable
	
}

public final class NetworkServiceByURLSession {
	private let decoderService: DecoderServicable
	public init(decoderService: DecoderServicable) {
		self.decoderService = decoderService
	}
}

extension NetworkServiceByURLSession: NetworkServicerPotocol {
	public func request<T>(_ request: Urlable, complition: @escaping (Result<T, Error>) -> Void) where T: Decodable {
		func complitionHandler(_ result: Result<T, Error>) {
			DispatchQueue.main.async {
				complition(result)
			}
		}
		DispatchQueue.global(qos: .userInitiated).async {  [weak self] in
			guard let self = self else {
				return
			}
			guard let url = URL(string: request.urlString) else { return }
			let urlRequest = URLRequest(url: url)
			URLSession.shared.dataTask(with: urlRequest, completionHandler: { data, response, error in
				if let error = error {
					complition(.failure(error))
				}
				if let data = data {
					self.decoderService.decode(data, complition: complition)
				}
			}).resume()
		}
	}
}
public protocol DecoderServicable{
	func decode<T: Decodable>(_ data: Data, complition: @escaping (Result<T, Error>) -> Void)
	func encode<T: Encodable>(_ data: T, complition: @escaping (Result<Data, Error>) -> Void)
}

public final class DecoderService{
	public init() {}
	private let jsonDecoder = JSONDecoder()
	private let jsonEncoder = JSONEncoder()
}

extension DecoderService: DecoderServicable {
	public func decode<T: Decodable>(_ data: Data, complition: @escaping (Result<T, Error>) -> Void) {
		do {
			let result = try self.jsonDecoder.decode(T.self, from: data)
			complition(.success(result))
		} catch  {
			complition(.failure(error))
		}
	}
	
	public func encode<T: Encodable>(_ data: T, complition: @escaping (Result<Data, Error>) -> Void) {
		do {
			let result = try self.jsonEncoder.encode(data)
			complition(.success(result))
		} catch  {
			complition(.failure(error))
		}
	}
}


public protocol Urlable {
	var urlString: String { get }
}
