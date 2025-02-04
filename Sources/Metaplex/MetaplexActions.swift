// NL 2021

import Foundation
import Solana

public enum MetaplexActions {}

// MARK: - Constants
private var maxSeedLength = 32
private let gf1 = NaclLowLevel.gf([1])

private extension Int {
    func toBool() -> Bool {
        self != 0
    }
}

// TODO: Remove compat


extension PublicKey {
    
    static func _findProgramAddress(
        seeds: [Data],
        programId: Self
    ) -> Result<(Self, UInt8), Error> {
        for nonce in stride(from: UInt8(255), to: 0, by: -1) {
            let seedsWithNonce = seeds + [Data([nonce])]
            if case .success(let publicKey) = _createProgramAddress(seeds: seedsWithNonce, programId: programId) {
                return .success((publicKey, nonce))
            }
        }
        return .failure(SolanaError.notFoundProgramAddress)
    }
    
    
    private static func _createProgramAddress(
        seeds: [Data],
        programId: PublicKey
    ) ->  Result<PublicKey, Error> {
        // construct data
        var data = Data()
        for seed in seeds {
            data.append(seed)
        }
        data.append(programId.data)
        data.append("ProgramDerivedAddress".data(using: .utf8)!)

        // hash it
        let hash = sha256(data: data)
        let publicKeyBytes = Bignum(number: hash.hexString, withBase: 16).data
        
        // check it
        if _isOnCurve(publicKeyBytes: publicKeyBytes).toBool() {
            return .failure(SolanaError.other("Invalid seeds, address must fall off the curve"))
        }
        guard let newKey = PublicKey(data: publicKeyBytes) else {
            return .failure(SolanaError.invalidPublicKey)
        }
        return .success(newKey)
    }

    static var programIds: [PublicKey] {
        [
            .tokenProgramId,
            .splAssociatedTokenAccountProgramId,
            .vaultProgramId,
            .systemProgramID,
            .auctionProgramId,
            .metaplexProgramId,
            .metadataProgramId
        ]
    }

    static let metadataProgramId =
    PublicKey(string: "metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s")!

    static let vaultProgramId = PublicKey(string:                                          "vau1zxA2LbssAUEF7Gpw91zMM1LvXrvpzJtmZ58rPsn")!

    static let auctionProgramId = PublicKey(string:                                             "auctxRXPeJoc4817jDhf4HbjnhEcr1cCXenosMhK5R8")!

    static let metaplexProgramId = PublicKey(string:                                                 "p1exdMJcjVao65QdewkaZRUnU6VPSXhus9n2GzWfh98")!

    static let systemProgramID =  PublicKey(string: "11111111111111111111111111111111")!
}

extension String {
    static let metadataPrefix = "metadata"
    static let editionKeyword = "edition"
}

/// Extension for Data to interoperate with Bignum
extension Data {

    /// Hexadecimal string representation of the underlying data
    var hexString: String {
        return withUnsafeBytes { (buf: UnsafePointer<UInt8>) -> String in
            let charA = UInt8(UnicodeScalar("a").value)
            let char0 = UInt8(UnicodeScalar("0").value)

            func itoh(_ value: UInt8) -> UInt8 {
                return (value > 9) ? (charA + value - 10) : (char0 + value)
            }

            let ptr = UnsafeMutablePointer<UInt8>.allocate(capacity: count * 2)

            for i in 0 ..< count {
                ptr[i*2] = itoh((buf[i] >> 4) & 0xF)
                ptr[i*2+1] = itoh(buf[i] & 0xF)
            }

            return String(bytesNoCopy: ptr, length: count*2, encoding: .utf8, freeWhenDone: true)!
        }
    }
}


extension PublicKey {
    

    private static func _isOnCurve(publicKeyBytes: Data) -> Int {
        var r = [[Int64]](repeating: NaclLowLevel.gf(), count: 4)

        var t = NaclLowLevel.gf(),
            chk = NaclLowLevel.gf(),
            num = NaclLowLevel.gf(),
            den = NaclLowLevel.gf(),
            den2 = NaclLowLevel.gf(),
            den4 = NaclLowLevel.gf(),
            den6 = NaclLowLevel.gf()

        NaclLowLevel.set25519(&r[2], gf1)
        NaclLowLevel.unpack25519(&r[1], publicKeyBytes.bytes)
        NaclLowLevel.S(&num, r[1])
        NaclLowLevel.M(&den, num, NaclLowLevel.D)
        NaclLowLevel.Z(&num, num, r[2])
        NaclLowLevel.A(&den, r[2], den)

        NaclLowLevel.S(&den2, den)
        NaclLowLevel.S(&den4, den2)
        NaclLowLevel.M(&den6, den4, den2)
        NaclLowLevel.M(&t, den6, num)
        NaclLowLevel.M(&t, t, den)

        NaclLowLevel.pow2523(&t, t)
        NaclLowLevel.M(&t, t, num)
        NaclLowLevel.M(&t, t, den)
        NaclLowLevel.M(&t, t, den)
        NaclLowLevel.M(&r[0], t, den)

        NaclLowLevel.S(&chk, r[0])
        NaclLowLevel.M(&chk, chk, den)
        if NaclLowLevel.neq25519(chk, num).toBool() {
            NaclLowLevel.M(&r[0], r[0], NaclLowLevel.I)
        }

        NaclLowLevel.S(&chk, r[0])
        NaclLowLevel.M(&chk, chk, den)

        if NaclLowLevel.neq25519(chk, num).toBool() {
            return 0
        }
        return 1
    }
 
}

struct NaclLowLevel {

    // MARK: - Constants
    static var D = gf( [0x78a3, 0x1359, 0x4dca, 0x75eb,
                        0xd8ab, 0x4141, 0x0a4d, 0x0070,
                        0xe898, 0x7779, 0x4079, 0x8cc7,
                        0xfe73, 0x2b6f, 0x6cee, 0x5203] )
    static let I = gf([ 0xa0b0, 0x4a0e, 0x1b27, 0xc4ee,
                        0xe478, 0xad2f, 0x1806, 0x2f43,
                        0xd7a7, 0x3dfb, 0x0099, 0x2b4d,
                        0xdf0b, 0x4fc1, 0x2480, 0x2b83] )

    // MARK: - Methods
    static func gf() -> [Int64] {
        return gf([0])
    }

    static func gf(_ ai: [Int64]) -> [Int64] {
        var r = [Int64](repeating: 0, count: 16)
        for i in 0..<ai.count {
            r[i] = ai[i]
        }
        return r
    }

    static func unpack25519(_ o:inout [Int64], _ n: [UInt8]) {
        for i in 0..<16 {
            o[i] = Int64(n[2*i]) + ( Int64(n[2*i+1]) << 8) // *** R
        }
        o[15] = o[15] & 0x7fff
    }

    static func A(_ o:inout [Int64], _ a: [Int64], _ b: [Int64]) {
        for i in 0..<16 {
            o[i] = a[i] + b[i]
        }
    }

    static func Z(_ o:inout [Int64], _ a: [Int64], _ b: [Int64]) {
        for i in 0..<16 {
            o[i] = a[i] - b[i]
        }
    }

    static func M(_ o:inout [Int64], _ a: [Int64], _ b: [Int64]) {
        var at = [Int64](repeating: 0, count: 32)
        var ab = [Int64](repeating: 0, count: 16)

        for i in 0..<16 {
            ab[i] = b[i]
        }

        var v: Int64
        for i in 0..<16 {
            v = a[i]
            for j in 0..<16 {
                at[j+i] += v * ab[j]
            }
        }

        for i in 0..<15 {
            at[i] += 38 * at[i+16]
        }
        // t15 left as is
        // first car
        var c: Int64 = 1
        for i in 0..<16 {
            v = at[i] + c + 65535
            c = Int64( floor(Double(v) / 65536.0) )
            at[i] = v - c * 65536
        }
        at[0] += c-1 + 37 * (c-1)

        // second car
        c = 1
        for i in 0..<16 {
            v = at[i] + c + 65535
            c = Int64( floor(Double(v) / 65536.0) )
            at[i] = v - c * 65536
        }
        at[0] += c-1 + 37 * (c-1)

        for i in 0..<16 {
            o[i] = at[i]
        }

    }

    static func S(_ o:inout [Int64], _ a: [Int64]) {
        M(&o, a, a)
    }

    static func pow2523(_ o:inout [Int64], _ i: [Int64]) {
        var c = gf()
        for a in 0..<16 {
            c[a] = i[a]
        }
        for a in (0...250).reversed() {
            S(&c, c)
            if a != 1 {
                M(&c, c, i)
            }
        }
        for a in 0..<16 {
            o[a] = c[a]
        }
    }

    static func vn(_ x: [UInt8], _ xi: Int, _ y: [UInt8], _ yi: Int, _ n: Int) -> Int {
        var d: UInt8 = 0
        for i in 0..<n {
            d = d | ( x[xi+i] ^ y[yi+i] )
        }
        return (1 & ( ( Int(d) - 1 ) >>> 8 ) ) - 1
    }

    static func crypto_verify_32(_ x: [UInt8], _ xi: Int, _ y: [UInt8], _ yi: Int) -> Int {
        return vn(x, xi, y, yi, 32)
    }

    static func set25519(_ r:inout [Int64], _ a: [Int64]) {
        for i in 0..<16 {
            r[i] = a[i] | 0
        }
    }

    static func car25519(_ o:inout [Int64]) {
        var v: Int64
        var c = 1
        for i in 0..<16 {
            v = o[i] + Int64(c + 65535)
            c = Int(floor(Double(v) / 65536.0))
            o[i] = v - Int64(c * 65536)
        }
        o[0] += Int64( c-1 + 37 * (c-1) )
    }

    static func sel25519(_ p:inout [Int64], _ q:inout [Int64], _ b: Int) {
        var t: Int64
        let c = Int64( ~(b-1) )
        for i in 0..<16 {
            t = c & ( p[i] ^ q[i] )
            p[i] = p[i] ^ t
            q[i] = q[i] ^ t
        }
    }

    static func pack25519(_ o:inout [UInt8], _ n: [Int64]) {
        var b: Int64
        var m = gf()
        var t = gf()

        for i in 0..<16 {
            t[i] = n[i]
        }
        car25519(&t)
        car25519(&t)
        car25519(&t)

        for _ in 0...1 {
            m[0] = t[0] - 0xffed
            for i in 1...14 {
                m[i] = t[i] - 0xffff - ((m[i-1] >> 16) & 1)
                m[i-1] = m[i-1] & 0xffff
            }
            m[15] = t[15] - 0x7fff - ((m[14] >> 16) & 1)
            b = (m[15] >> 16) & 1
            m[14] = m[14] & 0xffff
            sel25519(&t, &m, Int(1-b) )
        }
        for i in 0..<16 {
            o[2*i] = UInt8(t[i] & 0xff ) // *** R
            o[2*i+1] = UInt8(t[i] >> 8 ) // *** R
        }
    }

    static func neq25519(_ a: [Int64], _ b: [Int64]) -> Int {
        var c = [UInt8](repeating: 0, count: 32)
        var d = [UInt8](repeating: 0, count: 32)
        pack25519(&c, a)
        pack25519(&d, b)
        return crypto_verify_32(c, 0, d, 0)
    }
}

private extension Int {
//    func toBool() -> Bool {
//        self != 0
//    }
}

infix operator >>> : BitwiseShiftPrecedence
func >>> (lhs: Int, rhs: Int) -> Int {
    let l = getInt32(Int64(lhs))
    let r = getInt32(Int64(rhs))
    return Int( Int32(bitPattern: UInt32(bitPattern: l) >> UInt32(r)) )
}
func getInt32(_ value: Int64) -> Int32 {
    return Int32(truncatingIfNeeded: value)
}

