import Foundation
import Solana

extension Metaplex {

    public struct Metadata: BufferLayout {
        
        public static let BUFFER_LENGTH: UInt64 = 0
        
        public let key: UInt8
        public let updateAuthority: PublicKey
        public let mint: PublicKey
        public let data: PlexData
        public let primarySaleHappened: Bool
        public let isMutable: Bool
        public let editionNonce: UInt64?
        
    }

}

extension Metaplex.Metadata: BorshCodable {

    public init(from reader: inout BinaryReader) throws {
        self.key = try .init(from: &reader)
        self.updateAuthority = try .init(from: &reader)
        self.mint = try .init(from: &reader)
        self.data = try .init(from: &reader)
        self.primarySaleHappened = try .init(from: &reader)
        self.isMutable = try .init(from: &reader)
        self.editionNonce = try? .init(from: &reader)
    }

    public func serialize(to writer: inout Data) throws {
        try key.serialize(to: &writer)
        try updateAuthority.serialize(to: &writer)
        try mint.serialize(to: &writer)
        try data.serialize(to: &writer)
        try primarySaleHappened.serialize(to: &writer)
        try isMutable.serialize(to: &writer)
        try editionNonce?.serialize(to: &writer)
    }
    
}
