import Foundation
import IPWhois
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

var pass = 0
var fail = 0
func ok(_ c: Bool, _ m: String) {
    if c { pass += 1; print("  PASS \(m)") } else { fail += 1; print("  FAIL \(m)") }
}

func run() async {
    guard let key = ProcessInfo.processInfo.environment["IPWHO_API_KEY"] else {
        print("no key"); exit(2)
    }
    let c = IPWhoisClient(apiKey: key)

    do {
        // 1. lookup
        let r = try await c.lookup(ip: "8.8.8.8")
        let d = r.data!
        let gl = d.geoLocation!
        let tz = d.timezone!
        let fl = d.flag!
        let cu = d.currency!
        let cn = d.connection!
        ok(d.ip == "8.8.8.8", "lookup ip == 8.8.8.8")
        ok(gl.country == "United States", "country == United States (got \(gl.country ?? "nil"))")
        ok(cn.asnNumber == 15169, "asn_number == 15169 (got \(String(describing: cn.asnNumber)))")
        ok(gl.dialCode != nil, "dial_code captured (\(gl.dialCode ?? "nil"))")
        ok(gl.isInEu != nil, "is_in_eu captured")
        ok(tz.timeZone != nil, "time_zone captured (\(tz.timeZone ?? "nil"))")
        ok(fl.flagIcon != nil, "flag_Icon captured (\(fl.flagIcon ?? "nil"))")
        ok(fl.flagUnicode != nil, "flag_unicode captured (\(fl.flagUnicode ?? "nil"))")
        ok(cu.namePlural != nil, "name_plural captured (\(cu.namePlural ?? "nil"))")
        ok(cn.asnOrg != nil, "asn_org captured (\(cn.asnOrg ?? "nil"))")
        ok(cn.connectionType != nil, "connection_type captured (\(cn.connectionType ?? "nil"))")

        // 2. me
        let me = try await c.me()
        ok(me.data?.ip.isEmpty == false, "me ip captured (\(me.data?.ip ?? "nil"))")

        // 3. bulk
        let b = try await c.bulk(ips: ["8.8.8.8", "1.1.1.1"])
        let n = b.data?.responseArray?.count ?? 0
        ok(n == 2, "bulk returns 2 (got \(n))")
    } catch {
        ok(false, "primary tests threw: \(error)")
    }

    // 4. bad key
    do {
        _ = try await IPWhoisClient(apiKey: "sk.invalid_test_key").lookup(ip: "8.8.8.8")
        ok(false, "bad key should raise")
    } catch {
        ok(true, "bad key raised \(error)")
    }

    print("\nSWIFT RESULT: \(pass) passed, \(fail) failed")
    exit(fail > 0 ? 1 : 0)
}

let sem = DispatchSemaphore(value: 0)
Task { await run(); sem.signal() }
sem.wait()
