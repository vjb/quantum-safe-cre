pub mod models;

use models::IntentPayload;
use sp1_sdk::{ProverClient, SP1Stdin, HashableKey, Prover};
use sp1_sdk::prelude::*;
use std::fs;
use std::path::Path;
use std::time::Instant;
use tracing::{info, debug};

pub const ELF: &[u8] = include_bytes!(env!("SP1_PROGRAM_ELF"));

#[tokio::main]
async fn main() {
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
    debug!("Ingested external intent matching exact TDD cryptographic specifications.");

    info!("Preparing SP1 Prover Client...");
    let client = ProverClient::from_env().await;
    let mut stdin = SP1Stdin::new();
    debug!("Mapping SP1Stdin bounds dynamically for guest process...");
    stdin.write(&payload);

    info!("Generating STARK proof (this may take significant RAM/CPU bounds)...");
    let start_time = Instant::now();
    
    // Generate the proving and verifying keys
    let pk = client.setup(sp1_sdk::Elf::Static(ELF)).await.expect("Failed to setup SP1 proving keys.");
    let vk = pk.verifying_key();

    // Attempt to generate a Plonk proof locally. 
    // This is computationally intensive.
    let mut proof: sp1_sdk::SP1ProofWithPublicValues = client.prove(&pk, stdin).plonk().await.expect("Failed to generate STARK Proof. Host machine may have hit OOM limits.");
    
    let commited_message = proof.public_values.read::<String>();
    let duration = start_time.elapsed();
    info!("Execution and STARK proving completed in {:?}", duration);
    
    assert_eq!(commited_message, payload.message);
    info!("Successfully verified and committed message: {}", commited_message);
    
    // Dump actual proof bytes and public values to hex strings for Chainlink Orchestrator
    debug!("Serializing Proof and Public Values to disk...");
    let proof_hex = hex::encode(proof.bytes());
    // SP1 proof.public_values contains ABI encoded bounds. We'll extract raw bytes for Ethers format.
    let pv_hex = hex::encode(proof.public_values.as_slice());
    
    let stark_output = serde_json::json!({
        "proofBytes": format!("0x{}", proof_hex),
        "publicValues": format!("0x{}", pv_hex),
        "vkey": vk.bytes32().to_string()
    });
    
    // Export proof output for Oracle ingestion via Docker mounted volume
    fs::write("/app/output/proof.json", stark_output.to_string()).unwrap_or_else(|_| {
        fs::write("../../proof.json", stark_output.to_string()).expect("Failed to write STARK proof to disk natively");
    });
    info!("STARK cryptographic envelope materialized successfully into proof.json");
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_zkvm_rejects_invalid_intent() {
        let client = ProverClient::from_env().await;
        let mut stdin = SP1Stdin::new();
        
        let payload = IntentPayload {
            message: "Transfer 1000 USDC".to_string(),
            public_key_hex: "00".to_string(),
            signature_hex: "00".to_string(),
        };
        stdin.write(&payload);
        
        let execution = client.execute(sp1_sdk::Elf::Static(ELF), stdin).await;
        assert!(execution.is_err(), "SP1 Validation should panic on invalid sig");
    }
}
