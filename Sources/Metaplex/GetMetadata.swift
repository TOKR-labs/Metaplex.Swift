// NL 2021

import Foundation
import Solana

extension MetaplexActions {
    
    public struct GetMetadata: ActionTemplate {
    
        public typealias Success = PublicKey
        public let tokenMint: PublicKey

        public init(tokenMint: PublicKey) {
            self.tokenMint = tokenMint
        }
        
        public func perform(withConfigurationFrom actionClass: Action, completion: @escaping (Result<Success, Error>) -> Void) {

            let seed = [
                String.metadataPrefix.bytes +
                PublicKey.metadataProgramId.bytes +
                tokenMint.bytes
            ].map {
                Data($0)
            }
            
            _ = PublicKey._findProgramAddress(seeds: seed, programId: .metadataProgramId)
                .onSuccess { key in
                    completion(.success(key.0))
                }
                .onFailure { error in
                    completion(.failure(error))
                }
            
        }
    }
    
}
