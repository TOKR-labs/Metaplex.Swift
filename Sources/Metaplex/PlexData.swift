import Foundation
import Solana

extension Metaplex {

    public struct PlexData: BufferLayout {
        
        public static let BUFFER_LENGTH: UInt64 = 0

        public let name: String
        public let symbol: String
        public let uri: String
        public let sellerFeeBasisPoints: UInt16
        
        // @FIXME: deserialization fails when creators are empty
        // public let creators: [Creator]?
        
    }
}

extension Metaplex.PlexData: BorshCodable {

    public init(from reader: inout BinaryReader) throws {
        
        let tempName = try String.init(from: &reader)
        let tempSymbol = try String.init(from: &reader)
        let tempUri = try String.init(from: &reader)
        self.sellerFeeBasisPoints = try .init(from: &reader)
        
        // @FIXME: deserialization fails when creators are empty
        // self.creators = try? .init(from: &reader)

        self.name = tempName.replacingOccurrences(of: "\0", with: "")
        self.symbol = tempSymbol.replacingOccurrences(of: "\0", with: "")
        self.uri = tempUri.replacingOccurrences(of: "\0", with: "")

    }

    public func serialize(to writer: inout Data) throws {
        try name.serialize(to: &writer)
        try symbol.serialize(to: &writer)
        try uri.serialize(to: &writer)
        try sellerFeeBasisPoints.serialize(to: &writer)
        
        // @FIXME: deserialization fails when creators are empty
        // try? creators?.serialize(to: &writer)
    }

}
