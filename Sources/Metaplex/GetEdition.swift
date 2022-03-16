// NL 2021

import Foundation
import Solana
import CryptoKit

extension MetaplexActions {
   
    public struct GetEdition: ActionTemplate {
        
        public typealias Success = PublicKey
        
        public let tokenMint: PublicKey

        public func perform(withConfigurationFrom actionClass: Action, completion: @escaping (Result<Success, Error>) -> Void) {
            
            let seed = [
                String.metadataPrefix.bytes +
                        PublicKey.metadataProgramId.bytes +
                        tokenMint.bytes +
                        String.editionKeyword.bytes
            ].map { Data($0) }
            
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
