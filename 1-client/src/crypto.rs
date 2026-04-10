use pqc_dilithium::*;
use tracing::info;

pub struct IntentSigner {
    keypair: Keypair,
}

impl IntentSigner {
    pub fn new() -> Self {
        info!("Generating Dilithium keypair...");
        let keys = Keypair::generate();
        Self { keypair: keys }
    }

    pub fn sign_intent(&self, message: &[u8]) -> Vec<u8> {
        info!("Signing intent payload...");
        self.keypair.sign(message).to_vec()
    }

    pub fn public_key_hex(&self) -> String {
        hex::encode(self.keypair.public)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_dilithium_sign_and_verify() {
        let signer = IntentSigner::new();
        let message = b"Transfer 10 USDC";
        let signature = signer.sign_intent(message);
        
        
        let verify_result = pqc_dilithium::verify(
            &signature,
            message,
            &signer.keypair.public
        );
        assert!(verify_result.is_ok());
    }

    #[test]
    fn test_signature_tamper_rejection() {
        let signer = IntentSigner::new();
        let message = b"Transfer 10 USDC";
        let signature = signer.sign_intent(message);
        
        let malicious_message = b"Transfer 1000 USDC";
        let verify_result = pqc_dilithium::verify(
            &signature,
            malicious_message,
            &signer.keypair.public
        );
        assert!(verify_result.is_err(), "Signature verification should fail on tampered message");
    }
}
