pub mod models;

use models::IntentPayload;
use sp1_sdk::{ProverClient, SP1Stdin};
use std::fs;
use std::path::Path;
use std::time::Instant;
use tracing::info;

pub const ELF: &[u8] = include_bytes!(env!("SP1_PROGRAM_ELF"));

fn main() {
    tracing_subscriber::fmt::init();
    info!("Starting SP1 Host Orchestrator...");

    let intent_path = Path::new("../../1-client/intent.json");
    let intent_file = if intent_path.exists() {
        intent_path
    } else {
        Path::new("../1-client/intent.json")
    };

    let file_content = fs::read_to_string(intent_file).expect("Failed to read intent.json");
    let payload: IntentPayload = serde_json::from_str(&file_content).expect("Failed to parse intent.json");

    info!("Preparing SP1 Prover Client...");
    let client = ProverClient::new();
    let mut stdin = SP1Stdin::new();
    stdin.write(&payload);

    info!("Generating STARK proof...");
    let start_time = Instant::now();
    
    // In SDK versions >= 2.0, execute() requires ELF directly.
    let (mut public_values, _report) = client.execute(ELF, stdin).run().unwrap();
    
    let commited_message = public_values.read::<String>();
    let duration = start_time.elapsed();
    info!("Execution completed in {:?}", duration);
    
    assert_eq!(commited_message, payload.message);
    info!("Successfully verified and committed message: {}", commited_message);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_zkvm_rejects_invalid_intent() {
        let client = ProverClient::new();
        let mut stdin = SP1Stdin::new();
        
        let payload = IntentPayload {
            message: "Transfer 1000 USDC".to_string(),
            public_key_hex: "00".to_string(),
            signature_hex: "00".to_string(),
        };
        stdin.write(&payload);
        
        let execution = client.execute(ELF, stdin).run();
        assert!(execution.is_err(), "SP1 Validation should panic on invalid sig");
    }
}
