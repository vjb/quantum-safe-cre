pub mod models;
pub mod crypto;
pub mod storage;

use std::path::Path;
use tracing::{info, debug};
use models::IntentPayload;
use crypto::IntentSigner;

fn main() {
    tracing_subscriber::fmt::init();
    info!("Starting 1-client Intent Generator...");

    let signer = IntentSigner::new();
    let now = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).unwrap().as_secs();
    let message = format!("Transfer 10 USDC - Nonce {}", now);
    let message = message.as_str();
    let signature_bytes = signer.sign_intent(message.as_bytes());
    let signature_hex = hex::encode(signature_bytes);
    
    let payload = IntentPayload {
        message: message.to_string(),
        public_key_hex: signer.public_key_hex(),
        signature_hex,
    };
    debug!("Payload constructed with Message: '{}', Key Length: {}, Sig Length: {}", payload.message, payload.public_key_hex.len(), payload.signature_hex.len());

    let filepath = Path::new("intent.json");
    storage::export_intent_to_file(&payload, filepath);
    
    info!("Success! intent.json has been written to disk.");
}
