use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug, PartialEq)]
pub struct IntentPayload {
    pub message: String,
    pub public_key_hex: String,
    pub signature_hex: String,
}
