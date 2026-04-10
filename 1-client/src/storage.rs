use std::fs;
use std::path::Path;
use tracing::info;
use crate::models::IntentPayload;

pub fn export_intent_to_file(payload: &IntentPayload, filepath: &Path) {
    let serialized = serde_json::to_string_pretty(payload).expect("Failed to serialize intent payload");
    fs::write(filepath, &serialized).expect("Failed to write intent to file");
    
    let metadata = fs::metadata(filepath).expect("Failed to read file metadata");
    info!("Successfully exported intent to {}. Size: {} bytes", filepath.display(), metadata.len());
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::tempdir;
    use std::fs;

    #[test]
    fn test_intent_export_and_import() {
        let dir = tempdir().unwrap();
        let filepath = dir.path().join("intent.json");
        
        let payload = IntentPayload {
            message: "Transfer 10 USDC".to_string(),
            public_key_hex: "0xabc123".to_string(),
            signature_hex: "0xdef456".to_string(),
        };

        export_intent_to_file(&payload, &filepath);
        
        assert!(filepath.exists());
        let file_content = fs::read_to_string(&filepath).unwrap();
        let deserialized: IntentPayload = serde_json::from_str(&file_content).unwrap();
        
        assert_eq!(payload, deserialized);
    }
}
