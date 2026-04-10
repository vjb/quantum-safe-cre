#![no_main]
sp1_zkvm::entrypoint!(main);

pub mod models;
use models::IntentPayload;

pub fn main() {
    let payload = sp1_zkvm::io::read::<IntentPayload>();

    let public_key_bytes = hex::decode(&payload.public_key_hex).expect("Failed to decode public key hex");
    let signature_bytes = hex::decode(&payload.signature_hex).expect("Failed to decode signature hex");

    let verify_result = pqc_dilithium::verify(
        &signature_bytes,
        payload.message.as_bytes(),
        &public_key_bytes
    );

    if verify_result.is_err() {
        panic!("Dilithium signature verification failed!");
    }

    sp1_zkvm::io::commit(&payload.message);
}
