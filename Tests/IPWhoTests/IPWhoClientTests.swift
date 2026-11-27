// A URLProtocol stub answers every request with a recorded API response,
// so these tests need no API key and no network access.

import XCTest
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import IPWho

private let testKey = "sk.test_secret_value"

private final class StubProtocol: URLProtocol {
    // Tests run one at a time, so plain shared state is enough.
    static var status = 200
    static var body = Data()
    static var requests: [URLRequest] = []

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        StubProtocol.requests.append(request)
        let response = HTTPURLResponse(
            url: request.url!, statusCode: StubProtocol.status, httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: StubProtocol.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

final class IPWhoClientTests: XCTestCase {
    private var client: IPWhoClient!

    override func setUpWithError() throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubProtocol.self]
        client = IPWhoClient(apiKey: testKey, session: URLSession(configuration: configuration))
        StubProtocol.requests = []
        try reply(200, fixture: "lookup")
    }

    private func reply(_ status: Int, _ body: String) {
        StubProtocol.status = status
        StubProtocol.body = Data(body.utf8)
    }

    private func reply(_ status: Int, fixture name: String) throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/\(name).json")
        StubProtocol.status = status
        StubProtocol.body = try Data(contentsOf: url)
    }

    func testKeyIsInTheHeaderAndNeverInTheURL() async throws {
        _ = try await client.lookup(ip: "8.8.8.8")
        _ = try await client.me()
        try reply(200, fixture: "bulk")
        _ = try await client.bulk(ips: ["8.8.8.8", "1.1.1.1"])

        XCTAssertEqual(StubProtocol.requests.count, 3)
        for request in StubProtocol.requests {
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(testKey)")
            XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), "ipwho-swift-sdk/1.0.0")
            let url = request.url!.absoluteString
            XCTAssertFalse(url.contains(testKey), url)
            XCTAssertFalse(url.lowercased().contains("apikey"), url)
            XCTAssertNil(request.url!.query)
        }
    }

    func testKeyWithSurroundingWhitespaceIsTrimmed() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubProtocol.self]
        let padded = IPWhoClient(apiKey: "  \(testKey)\n", session: URLSession(configuration: configuration))
        _ = try await padded.lookup(ip: "8.8.8.8")
        XCTAssertEqual(StubProtocol.requests[0].value(forHTTPHeaderField: "Authorization"), "Bearer \(testKey)")
    }

    func testLookupMapsEveryGeoLocationCode() async throws {
        let data = try await client.lookup(ip: "8.8.8.8").data
        XCTAssertEqual(data?.ip, "8.8.8.8")
        XCTAssertEqual(data?.geoLocation?.country, "United States")
        XCTAssertEqual(data?.geoLocation?.countryCode, "US")
        XCTAssertEqual(data?.geoLocation?.continentCode, "NA")
        XCTAssertEqual(data?.geoLocation?.dialCode, "+1")
        XCTAssertEqual(data?.connection?.asnNumber, 15169)
        XCTAssertEqual(data?.timezone?.timeZone, "America/Chicago")
        XCTAssertEqual(data?.currency?.code, "USD")
    }

    func testRegionCodeIsDecoded() async throws {
        reply(200, #"{"success":true,"data":{"ip":"203.0.113.1","geoLocation":{"region":"Victoria","regionCode":"VIC"}}}"#)
        let data = try await client.lookup(ip: "203.0.113.1").data
        XCTAssertEqual(data?.geoLocation?.regionCode, "VIC")
    }

    func testLookupAcceptsANullCurrency() async throws {
        try reply(200, fixture: "lookup-null-currency")
        let data = try await client.lookup(ip: "1.1.1.1").data
        XCTAssertEqual(data?.ip, "1.1.1.1")
        XCTAssertNil(data?.currency)
    }

    func testBulkReturnsTheDataForEveryAddress() async throws {
        try reply(200, fixture: "bulk")
        let response = try await client.bulk(ips: ["8.8.8.8", "1.1.1.1", "192.168.0.1", "9.9.9.9"])
        let rows = try XCTUnwrap(response.data?.responseArray)
        XCTAssertEqual(rows.map { $0.data?.ip ?? "" }, ["8.8.8.8", "1.1.1.1", "192.168.0.1", "9.9.9.9"])

        XCTAssertTrue(rows[0].success)
        XCTAssertEqual(rows[0].data?.geoLocation?.country, "United States")
        XCTAssertEqual(rows[0].data?.geoLocation?.countryCode, "US")
        XCTAssertEqual(rows[0].data?.connection?.asnNumber, 15169)

        XCTAssertTrue(rows[1].success)
        XCTAssertNil(rows[1].data?.currency)

        XCTAssertFalse(rows[2].success)
        XCTAssertNil(rows[2].data?.geoLocation)
        XCTAssertEqual(rows[2].message, "Reserved range/Invalid IP address")

        XCTAssertFalse(rows[3].success)
        XCTAssertEqual(rows[3].message?.contains("quota"), true)
    }

    func testBulkResponseSurvivesEncodingAndDecoding() async throws {
        try reply(200, fixture: "bulk")
        let response = try await client.bulk(ips: ["8.8.8.8"])
        let copy = try JSONDecoder().decode(BulkResponse.self, from: JSONEncoder().encode(response))
        XCTAssertEqual(copy.data?.responseArray?.first?.data?.geoLocation?.countryCode, "US")
    }

    func testAFieldsFilterWithoutIPStillDecodes() async throws {
        reply(200, #"{"success":true,"data":{"geoLocation":{"country":"United States"}}}"#)
        let data = try await client.lookup(ip: "8.8.8.8", fields: "geoLocation").data
        XCTAssertEqual(data?.geoLocation?.country, "United States")
        XCTAssertEqual(data?.ip, "")
        XCTAssertEqual(StubProtocol.requests[0].url?.query, "get=geoLocation")
    }

    func testHTTPErrors() async throws {
        reply(404, #"{"success":false,"message":"Reserved range/Invalid IP address"}"#)
        await assertThrows { error in
            if case .notFound = error { return true }
            return false
        }
        reply(429, #"{"error":"rate_limit_exceeded"}"#)
        await assertThrows { error in
            if case .rateLimitExceeded = error { return true }
            return false
        }
        reply(401, #"{"error":"invalid_api_key"}"#)
        await assertThrows { error in
            if case .httpError(let status, let message) = error { return status == 401 && message == "invalid_api_key" }
            return false
        }
    }

    private func assertThrows(
        _ matches: (IPWhoError) -> Bool, file: StaticString = #filePath, line: UInt = #line
    ) async {
        do {
            _ = try await client.lookup(ip: "8.8.8.8")
            XCTFail("Expected an error", file: file, line: line)
        } catch let error as IPWhoError {
            XCTAssertTrue(matches(error), "\(error)", file: file, line: line)
            XCTAssertFalse("\(error)".contains(testKey), file: file, line: line)
        } catch {
            XCTFail("Unexpected error: \(error)", file: file, line: line)
        }
    }
}
