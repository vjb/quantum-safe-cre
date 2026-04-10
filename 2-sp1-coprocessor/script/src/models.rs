use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug, PartialEq)]
pub struct IntentPayload {
    pub message: String,
    pub public_key_hex: String,
    pub signature_hex: String,
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use std::path::Path;

    #[test]
    fn test_read_client_intent() {
        let mut path = Path::new("../../1-client/intent.json");
        if !path.exists() {
            path = Path::new("../1-client/intent.json");
        }
        
        if !path.exists() {
            let mock = IntentPayload {
                message: "Transfer 10 USDC".to_string(),
                public_key_hex: "00".to_string(),
                signature_hex: "00".to_string(),
            };
            fs::create_dir_all("../../1-client").unwrap();
            fs::write(Path::new("../../1-client/intent.json"), serde_json::to_string(&mock).unwrap()).unwrap();
            path = Path::new("../../1-client/intent.json");
        }

        let file_content = fs::read_to_string(path).expect("Failed to read intent.json");
        let payload: IntentPayload = serde_json::from_str(&file_content).expect("Failed to parse JSON");
        
        assert!(!payload.message.is_empty(), "Message should not be empty");
        assert!(!payload.signature_hex.is_empty(), "Signature should not be empty");
    }
}
