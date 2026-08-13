# IPWho ([ipwho.org](https://www.ipwho.org)) Swift SDK

[![Swift](https://img.shields.io/badge/swift-5.9+-F05138.svg)](https://swift.org/) [![license](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/lavrox/SDK-IPWho-Swift/blob/main/LICENSE)

Official Swift client for the [IPWho](https://www.ipwho.org) IP Intelligence API. One call returns the **full** payload: geolocation, timezone, flag, currency, connection (ASN/ISP), security, and user-agent when present.

SPM uses the GitHub repo URL (no extra registry).

- Website: [https://www.ipwho.org](https://www.ipwho.org)
- API docs: [https://www.ipwho.org/docs](https://www.ipwho.org/docs)
- Get an API key: [https://www.ipwho.org](https://www.ipwho.org)
- Live API: [https://api.ipwho.org](https://api.ipwho.org)
- Source: [https://github.com/lavrox/SDK-IPWho-Swift](https://github.com/lavrox/SDK-IPWho-Swift)

## Installation

Xcode: **File → Add Package Dependencies…**

```
https://github.com/lavrox/SDK-IPWho-Swift
```

```swift
.package(url: "https://github.com/lavrox/SDK-IPWho-Swift.git", from: "1.0.0")
```

Swift 5.9+. Client: `IPWhoisClient`. Product: `IPWhois`.

## Quick Start

```swift
import IPWhois

let client = IPWhoisClient(apiKey: ProcessInfo.processInfo.environment["IPWHO_API_KEY"] ?? "")

let resp = try await client.lookup(ip: "8.8.8.8")           // GET /ip/{ip}
let me = try await client.me()                              // GET /me
let bulk = try await client.bulk(ips: ["8.8.8.8", "1.1.1.1"])
```

```
IpGeoResponse
├── success
├── message
└── data: GeoData?
    ├── ip
    ├── geoLocation
    ├── timezone
    ├── flag
    ├── currency
    ├── connection
    ├── security
    └── userAgent
```

Bulk: `BulkResponse.data.responseArray: [IpGeoResponse]?`.

## Reading the full response (8.8.8.8)

Live [IPWho](https://www.ipwho.org) values: United States, ASN 15169, America/Chicago, dial code +1.

```swift
let data = try await client.lookup(ip: "8.8.8.8").data
print(data?.ip ?? "") // 8.8.8.8

let geo = data?.geoLocation
print(geo?.country ?? "")       // United States
print(geo?.countryCode ?? "")   // US
print(geo?.continent ?? "")
print(geo?.continentCode ?? "")
print(geo?.capital ?? "")
print(geo?.region ?? "")
print(geo?.regionCode ?? "")
print(geo?.city ?? "")
print(geo?.postalCode ?? "")
print(geo?.dialCode ?? "")      // +1
print(geo?.isInEu as Any)
print(geo?.latitude as Any)
print(geo?.longitude as Any)
print(geo?.accuracyRadius as Any)

let tz = data?.timezone
print(tz?.timeZone ?? "") // America/Chicago
print(tz?.abbr ?? "")
print(tz?.offset as Any)
print(tz?.isDst as Any)
print(tz?.utc ?? "")
print(tz?.currentTime ?? "")

print(data?.flag?.flagIcon ?? "")    // 🇺🇸
print(data?.flag?.flagUnicode ?? "")

print(data?.currency?.code ?? "")
print(data?.currency?.namePlural ?? "") // US dollars

let conn = data?.connection
print(conn?.asnNumber as Any)      // 15169
print(conn?.asnOrg ?? "")          // Google LLC
print(conn?.isp ?? "")
print(conn?.org ?? "")
print(conn?.domain ?? "")
print(conn?.connectionType ?? "")  // Corporate

print(data?.security?.isVpn as Any)
print(data?.security?.isTor as Any)
print(data?.security?.isThreat ?? "")

print(data?.userAgent?.browser.name ?? "")

let me = try await client.me()
print(me.data?.ip ?? "")

let bulk = try await client.bulk(ips: ["8.8.8.8", "1.1.1.1"])
print(bulk.data?.responseArray?.count ?? 0)
```

`lookup` / `me` take `format: ResponseFormat = .json` and optional `fields`.

## API Reference

### `IPWhoisClient(apiKey:baseURL:session:)`

Default base `https://api.ipwho.org`. Query `apiKey`.

### Errors

`IPWhoisError`: `networkError`, `httpError`, `apiError`, `rateLimitExceeded`, `notFound`, `decodingError`, `invalidResponse`.

## Type Definitions

```swift
public struct GeoLocation {
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
}
```

Also `Timezone`, `Flag`, `Currency`, `Connection`, `Security`, `UserAgent` (browser/engine/os/device/cpu). Codable keys follow the live wire.

## Troubleshooting

- Key: [https://www.ipwho.org](https://www.ipwho.org).
- HTTP 403: do not strip the SDK User-Agent.
- Optionals: city and user-agent are often nil on anycast IPs.

## Testing

```bash
IPWHO_API_KEY=your_key swift run Check
```

The live check is `Examples/Check/test_main.swift`.

## Changelog

### v1.0.0

- `lookup`, `me`, `bulk` matching [https://api.ipwho.org](https://api.ipwho.org)

## License

MIT License — see [LICENSE](LICENSE).

## Support

- Documentation: [https://www.ipwho.org/docs](https://www.ipwho.org/docs)
- Contact: [https://www.ipwho.org/contact](https://www.ipwho.org/contact)
- GitHub Issues: [https://github.com/lavrox/SDK-IPWho-Swift/issues](https://github.com/lavrox/SDK-IPWho-Swift/issues)
- Website: [https://www.ipwho.org](https://www.ipwho.org)

---

Product by [https://lavrox.com](https://lavrox.com)
