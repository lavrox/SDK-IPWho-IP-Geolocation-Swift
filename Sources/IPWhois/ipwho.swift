// ---------------------------------------------------------------------------
// Package.swift  (Copy this to a proper Package.swift for SPM integration)
// ---------------------------------------------------------------------------
// // swift-tools-version: 5.9
// import PackageDescription
//
// let package = Package(
//     name: "IPWhois",
//     platforms: [.iOS(.v15), .macOS(.v12), .tvOS(.v15), .watchOS(.v8)],
//     products: [.library(name: "IPWhois", targets: ["IPWhois"])],
//     dependencies: [],
//     targets: [.target(name: "IPWhois", dependencies: [])]
// )
// ---------------------------------------------------------------------------

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Error Type

/// Errors that can occur when using the IPWhois API.
public enum IPWhoisError: Error, LocalizedError, Sendable {
    /// Network / transport-level failure.
    case networkError(Error)
    /// The server returned an unsuccessful HTTP status code.
    case httpError(statusCode: Int, message: String)
    /// The API responded with `success: false` and a message.
    case apiError(message: String)
    /// Rate limit exceeded (HTTP 429).
    case rateLimitExceeded(message: String)
    /// The IP was not found (HTTP 404).
    case notFound(message: String)
    /// Failed to decode the JSON response.
    case decodingError(Error)
    /// Unexpected or malformed response.
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case .networkError(let err):
            return "Network error: \(err.localizedDescription)"
        case .httpError(let code, let msg):
            return "HTTP \(code): \(msg)"
        case .apiError(let msg):
            return "API error: \(msg)"
        case .rateLimitExceeded(let msg):
            return "Rate limit exceeded: \(msg)"
        case .notFound(let msg):
            return "Not found: \(msg)"
        case .decodingError(let err):
            return "Decoding error: \(err.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}

// MARK: - Response Format

/// Supported API response formats.
public enum ResponseFormat: String, Sendable {
    case json = "json"
    case xml  = "xml"
    case csv  = "csv"
}

// MARK: - GeoLocation

/// Geographic location data for the queried IP.
public struct GeoLocation: Codable, Sendable {
    public let continent: String?
    public let continentCode: String?
    public let country: String?
    public let countryCode: String?
    public let capital: String?
    public let region: String?
    public let regionCode: String?
    public let city: String?
    public let postalCode: String?
    public let dialCode: String?
    public let isInEu: Bool?
    public let latitude: Double?
    public let longitude: Double?
    public let accuracyRadius: Double?

    public init(
        continent: String? = nil,
        continentCode: String? = nil,
        country: String? = nil,
        countryCode: String? = nil,
        capital: String? = nil,
        region: String? = nil,
        regionCode: String? = nil,
        city: String? = nil,
        postalCode: String? = nil,
        dialCode: String? = nil,
        isInEu: Bool? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        accuracyRadius: Double? = nil
    ) {
        self.continent = continent
        self.continentCode = continentCode
        self.country = country
        self.countryCode = countryCode
        self.capital = capital
        self.region = region
        self.regionCode = regionCode
        self.city = city
        self.postalCode = postalCode
        self.dialCode = dialCode
        self.isInEu = isInEu
        self.latitude = latitude
        self.longitude = longitude
        self.accuracyRadius = accuracyRadius
    }

    enum CodingKeys: String, CodingKey {
        case continent
        case continentCode = "continent_code"
        case country
        case countryCode = "country_code"
        case capital
        case region
        case regionCode = "region_code"
        case city
        case postalCode = "postal_Code"
        case dialCode = "dial_code"
        case isInEu = "is_in_eu"
        case latitude
        case longitude
        case accuracyRadius = "accuracy_radius"
    }
}

// MARK: - Timezone

/// Timezone information for the queried IP.
public struct Timezone: Codable, Sendable {
    public let timeZone: String?
    public let abbr: String?
    public let offset: Int?
    public let isDst: Bool?
    public let utc: String?
    public let currentTime: String?

    public init(
        timeZone: String? = nil,
        abbr: String? = nil,
        offset: Int? = nil,
        isDst: Bool? = nil,
        utc: String? = nil,
        currentTime: String? = nil
    ) {
        self.timeZone = timeZone
        self.abbr = abbr
        self.offset = offset
        self.isDst = isDst
        self.utc = utc
        self.currentTime = currentTime
    }

    enum CodingKeys: String, CodingKey {
        case timeZone = "time_zone"
        case abbr
        case offset
        case isDst = "is_dst"
        case utc
        case currentTime = "current_time"
    }
}

// MARK: - Flag

/// Flag information for the IP's country.
public struct Flag: Codable, Sendable {
    public let flagIcon: String?
    public let flagUnicode: String?

    public init(flagIcon: String? = nil, flagUnicode: String? = nil) {
        self.flagIcon = flagIcon
        self.flagUnicode = flagUnicode
    }

    enum CodingKeys: String, CodingKey {
        case flagIcon = "flag_Icon"
        case flagUnicode = "flag_unicode"
    }
}

// MARK: - Currency

/// Currency information for the IP's country.
public struct Currency: Codable, Sendable {
    public let code: String?
    public let symbol: String?
    public let name: String?
    public let namePlural: String?
    public let hexUnicode: String?

    public init(
        code: String? = nil,
        symbol: String? = nil,
        name: String? = nil,
        namePlural: String? = nil,
        hexUnicode: String? = nil
    ) {
        self.code = code
        self.symbol = symbol
        self.name = name
        self.namePlural = namePlural
        self.hexUnicode = hexUnicode
    }

    enum CodingKeys: String, CodingKey {
        case code
        case symbol
        case name
        case namePlural = "name_plural"
        case hexUnicode = "hex_unicode"
    }
}

// MARK: - Connection

/// Network connection details for the queried IP.
public struct Connection: Codable, Sendable {
    public let asnNumber: Int?
    public let asnOrg: String?
    public let isp: String?
    public let org: String?
    public let domain: String?
    public let connectionType: String?

    public init(
        asnNumber: Int? = nil,
        asnOrg: String? = nil,
        isp: String? = nil,
        org: String? = nil,
        domain: String? = nil,
        connectionType: String? = nil
    ) {
        self.asnNumber = asnNumber
        self.asnOrg = asnOrg
        self.isp = isp
        self.org = org
        self.domain = domain
        self.connectionType = connectionType
    }

    enum CodingKeys: String, CodingKey {
        case asnNumber = "asn_number"
        case asnOrg = "asn_org"
        case isp
        case org
        case domain
        case connectionType = "connection_type"
    }
}

// MARK: - Security

/// Security / threat intelligence for the queried IP.
public struct Security: Codable, Sendable {
    public let isVpn: Bool?
    public let isTor: Bool?
    /// One of: "low", "medium", "high"
    public let isThreat: String?

    public init(isVpn: Bool? = nil, isTor: Bool? = nil, isThreat: String? = nil) {
        self.isVpn = isVpn
        self.isTor = isTor
        self.isThreat = isThreat
    }

    enum CodingKeys: String, CodingKey {
        case isVpn
        case isTor
        case isThreat
    }
}

// MARK: - User Agent Sub-types

public struct Browser: Codable, Sendable {
    public let name: String?
    public let version: String?

    public init(name: String? = nil, version: String? = nil) {
        self.name = name
        self.version = version
    }
}

public struct Engine: Codable, Sendable {
    public let name: String?
    public let version: String?

    public init(name: String? = nil, version: String? = nil) {
        self.name = name
        self.version = version
    }
}

public struct OS: Codable, Sendable {
    public let name: String?
    public let version: String?

    public init(name: String? = nil, version: String? = nil) {
        self.name = name
        self.version = version
    }
}

public struct Device: Codable, Sendable {
    public let type: String?
    public let vendor: String?
    public let model: String?

    public init(type: String? = nil, vendor: String? = nil, model: String? = nil) {
        self.type = type
        self.vendor = vendor
        self.model = model
    }
}

public struct CPU: Codable, Sendable {
    public let architecture: String?

    public init(architecture: String? = nil) {
        self.architecture = architecture
    }
}

// MARK: - UserAgent

/// User-agent details parsed from the IP's traffic.
public struct UserAgent: Codable, Sendable {
    public let browser: Browser?
    public let engine: Engine?
    public let os: OS?
    public let device: Device?
    public let cpu: CPU?

    public init(
        browser: Browser? = nil,
        engine: Engine? = nil,
        os: OS? = nil,
        device: Device? = nil,
        cpu: CPU? = nil
    ) {
        self.browser = browser
        self.engine = engine
        self.os = os
        self.device = device
        self.cpu = cpu
    }
}

// MARK: - GeoData (the `data` payload)

/// The `data` object inside a successful `IpGeoResponse`.
public struct GeoData: Codable, Sendable {
    public let ip: String
    public let geoLocation: GeoLocation?
    public let timezone: Timezone?
    public let flag: Flag?
    public let currency: Currency?
    public let connection: Connection?
    public let security: Security?
    public let userAgent: UserAgent?

    public init(
        ip: String,
        geoLocation: GeoLocation? = nil,
        timezone: Timezone? = nil,
        flag: Flag? = nil,
        currency: Currency? = nil,
        connection: Connection? = nil,
        security: Security? = nil,
        userAgent: UserAgent? = nil
    ) {
        self.ip = ip
        self.geoLocation = geoLocation
        self.timezone = timezone
        self.flag = flag
        self.currency = currency
        self.connection = connection
        self.security = security
        self.userAgent = userAgent
    }

    enum CodingKeys: String, CodingKey {
        case ip
        case geoLocation
        case timezone
        case flag
        case currency
        case connection
        case security
        case userAgent
    }
}

// MARK: - IpGeoResponse (top-level)

/// Top-level response from the IPWho API.
public struct IpGeoResponse: Codable, Sendable {
    public let success: Bool
    public let data: GeoData?
    /// Present only when `success` is `false`.
    public let message: String?

    public init(success: Bool, data: GeoData? = nil, message: String? = nil) {
        self.success = success
        self.data = data
        self.message = message
    }

    enum CodingKeys: String, CodingKey {
        case success
        case data
        case message
    }
}

// MARK: - ErrorResponse

/// Error payload returned on non-200 responses.
public struct ErrorResponse: Codable, Sendable {
    public let success: Bool
    public let message: String?
}

// MARK: - Bulk Response

/// Response from the `/bulk/{bulkIP}` endpoint.
public struct BulkResponse: Codable, Sendable {
    public let success: Bool
    public let data: BulkData?

    public init(success: Bool, data: BulkData? = nil) {
        self.success = success
        self.data = data
    }
}

public struct BulkData: Codable, Sendable {
    public let responseArray: [IpGeoResponse]?

    public init(responseArray: [IpGeoResponse]? = nil) {
        self.responseArray = responseArray
    }
}

// MARK: - IPWhoisClient

/// Swift client for the IPWho IP Intelligence API.
///
/// Usage:
/// ```swift
/// let client = IPWhoisClient(apiKey: "sk.xxxx")
/// let result = try await client.lookup(ip: "8.8.8.8")
/// print(result.data?.geoLocation?.city ?? "unknown")
/// ```
public final class IPWhoisClient: Sendable {
    private let apiKey: String
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(
        apiKey: String,
        baseURL: URL = URL(string: "https://api.ipwho.org")!,
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.session = session
        self.decoder = JSONDecoder()
    }

    // MARK: - Public API

    /// Look up geolocation data for a specific IP address.
    /// - Parameters:
    ///   - ip: IPv4 or IPv6 address.
    ///   - format: Response format (default: `.json`). Non-JSON formats will return raw text.
    ///   - fields: Optional comma-separated field filter (e.g. `"geoLocation,timezone"`).
    /// - Returns: `IpGeoResponse` with nested data.
    public func lookup(
        ip: String,
        format: ResponseFormat = .json,
        fields: String? = nil
    ) async throws -> IpGeoResponse {
        let path = "/ip/\(ip)"
        return try await performRequest(path: path, format: format, fields: fields)
    }

    /// Look up geolocation data for the caller's own IP address.
    /// - Parameters:
    ///   - format: Response format (default: `.json`).
    ///   - fields: Optional comma-separated field filter.
    /// - Returns: `IpGeoResponse` with nested data.
    public func me(
        format: ResponseFormat = .json,
        fields: String? = nil
    ) async throws -> IpGeoResponse {
        return try await performRequest(path: "/me", format: format, fields: fields)
    }

    /// Perform a bulk IP lookup.
    /// - Parameter ips: Array of IPv4/IPv6 addresses.
    /// - Returns: `BulkResponse` containing an array of `IpGeoResponse` objects.
    public func bulk(ips: [String]) async throws -> BulkResponse {
        guard !ips.isEmpty else {
            throw IPWhoisError.apiError(message: "IP list must not be empty")
        }
        let bulkParam = ips.joined(separator: ",")
        let path = "/bulk/\(bulkParam)"
        return try await performBulkRequest(path: path)
    }

    // MARK: - Internal

    private func performRequest(
        path: String,
        format: ResponseFormat,
        fields: String?
    ) async throws -> IpGeoResponse {
        let url = try buildURL(path: path, format: format, fields: fields)
        let (data, response) = try await session.data(for: URLRequest(url: url))
        try validateHTTPResponse(response, data: data)

        // Non-JSON formats: unwrap raw text
        if format != .json {
            let text = String(data: data, encoding: .utf8) ?? ""
            return IpGeoResponse(success: true, data: GeoData(ip: text), message: nil)
        }

        do {
            let wrapper = try decoder.decode(IpGeoResponse.self, from: data)
            if !wrapper.success {
                throw IPWhoisError.apiError(message: wrapper.message ?? "API returned success=false")
            }
            return wrapper
        } catch let error as IPWhoisError {
            throw error
        } catch {
            throw IPWhoisError.decodingError(error)
        }
    }

    private func performBulkRequest(path: String) async throws -> BulkResponse {
        let url = try buildURL(path: path, format: .json, fields: nil)
        let (data, response) = try await session.data(for: URLRequest(url: url))
        try validateHTTPResponse(response, data: data)

        do {
            let wrapper = try decoder.decode(BulkResponse.self, from: data)
            if !wrapper.success {
                throw IPWhoisError.apiError(message: "Bulk API returned success=false")
            }
            return wrapper
        } catch let error as IPWhoisError {
            throw error
        } catch {
            throw IPWhoisError.decodingError(error)
        }
    }

    private func buildURL(
        path: String,
        format: ResponseFormat,
        fields: String?
    ) throws -> URL {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path),
                                             resolvingAgainstBaseURL: false) else {
            throw IPWhoisError.invalidResponse
        }
        var queryItems = [URLQueryItem(name: "apiKey", value: apiKey)]
        if format != .json {
            queryItems.append(URLQueryItem(name: "format", value: format.rawValue))
        }
        if let fields = fields, !fields.isEmpty {
            queryItems.append(URLQueryItem(name: "get", value: fields))
        }
        components.queryItems = queryItems
        guard let url = components.url else {
            throw IPWhoisError.invalidResponse
        }
        return url
    }

    private func validateHTTPResponse(_ urlResponse: URLResponse, data: Data) throws {
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw IPWhoisError.invalidResponse
        }
        switch httpResponse.statusCode {
        case 200:
            return
        case 404:
            let msg = (try? decoder.decode(ErrorResponse.self, from: data))?.message ?? "IP not found"
            throw IPWhoisError.notFound(message: msg)
        case 429:
            let msg = (try? decoder.decode(ErrorResponse.self, from: data))?.message ?? "Rate limit exceeded"
            throw IPWhoisError.rateLimitExceeded(message: msg)
        default:
            let msg = (try? decoder.decode(ErrorResponse.self, from: data))?.message ?? "Unknown error"
            throw IPWhoisError.httpError(statusCode: httpResponse.statusCode, message: msg)
        }
    }
}

// MARK: - Example Usage

// import IPWhois
//
// let client = IPWhoisClient(apiKey: ProcessInfo.processInfo.environment["IPWHO_API_KEY"] ?? "sk.xxxx")
//
// Task {
//     do {
//         // Single IP lookup
//         let result = try await client.lookup(ip: "8.8.8.8")
//         if let gl = result.data?.geoLocation {
//             print("\(result.data?.ip ?? "") → \(gl.city ?? ""), \(gl.country ?? "")")
//         }
//
//         // Self lookup
//         let me = try await client.me()
//         print("My IP: \(me.data?.ip ?? "unknown")")
//
//         // Bulk lookup
//         let bulk = try await client.bulk(ips: ["8.8.8.8", "1.1.1.1"])
//         if let items = bulk.data?.responseArray {
//             for item in items {
//                 print("Bulk: \(item.data?.ip ?? "") - \(item.data?.geoLocation?.country ?? "")")
//             }
//         }
//     } catch {
//         print("Error: \(error.localizedDescription)")
//     }
// }
