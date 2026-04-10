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

    #[test]
    fn test_payload_serialization() {
        let payload = IntentPayload {
            message: "Transfer 10 USDC".to_string(),
            public_key_hex: "0xabc123".to_string(),
            signature_hex: "0xdef456".to_string(),
        };

        let serialized = serde_json::to_string(&payload).unwrap();
        assert!(serialized.contains("Transfer 10 USDC"));
        assert!(serialized.contains("0xabc123"));
        
        let deserialized: IntentPayload = serde_json::from_str(&serialized).unwrap();
        assert_eq!(payload, deserialized);
    }
}
