import re

with open("flagship_demo.ps1", "r", encoding="utf-8") as f:
    content = f.read()

# Replace Emojis
content = content.replace("🚀 ", "[INFO] ")
content = content.replace("❌ [FATAL ERROR]", "[ERROR]")
content = content.replace("❌ [WARNING]", "[WARNING]")
content = content.replace("❌ ", "[ERROR] ")
content = content.replace("✅ ", "[SUCCESS] ")
content = content.replace("📡 ", "[INFO] ")
content = content.replace("⚡ ", "[INFO] ")
content = content.replace("📥 ", "[INFO] ")
content = content.replace("🔗 ", "[INFO] ")

# Specific word replaces to conform to institutional standard
replacements = {
    "Matrix Payload natively": "Payload",
    "Matrix payload physically": "Payload",
    "Payload natively": "Payload",
    "natively": "",
    "structurally ": "",
    "dynamically ": "",
    "Orchestration Bounding": "Orchestration",
    "Flagship Pipeline (DEBUG MODE)...": "Execution Pipeline...",
    "live-flagship-demo": "execution-pipeline",
    "Tailing Execution Log Live!": "Monitoring execution logs.",
    "Bucket DataLayer": "GCS Bucket",
    "GCS DataLayer": "GCS Bucket",
    "Secure Enclave Invocation": "Cloud Function execution",
    "Telemetry": "Logs",
    "Flagship validation": "Pipeline execution",
    "hardware sequence": "Execution",
    "Hardware sequence": "Execution",
    "via self-destruct": "by orchestration service",
    "Linux Sandbox": "Docker container",
    "chaotic swarm": "system"
}

for k, v in replacements.items():
    content = content.replace(k, v)

# Fix up double spaces
content = content.replace("  ", " ")

with open("flagship_demo.ps1", "w", encoding="utf-8") as f:
    f.write(content)
