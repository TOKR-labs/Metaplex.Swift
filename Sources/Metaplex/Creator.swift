// NL 2021

import Foundation
import Solana

extension Metaplex {

    public struct Creator: BufferLayout {
    
    public static let BUFFER_LENGTH: UInt64 = 0
    
    public let address: String
    public let verified: Bool
    public let share: UInt8
    
}

}

extension Metaplex.Creator: BorshCodable {
    
    public init(from reader: inout BinaryReader) throws {
        self.address = try .init(from: &reader)
        self.verified = try .init(from: &reader)
        self.share = try .init(from: &reader)
    }
    
    public func serialize(to writer: inout Data) throws {
        try address.serialize(to: &writer)
        try verified.serialize(to: &writer)
        try share.serialize(to: &writer)
    }
    
}
