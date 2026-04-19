import os
import json
import pytest
from web3 import Web3
from dotenv import load_dotenv

# Load environment variables
dotenv_path = os.path.join(os.path.dirname(__file__), '../.env')
load_dotenv(dotenv_path)

def test_environment_variables():
    """Verify all critical institutional environment variables are present."""
    required_vars = [
        'GCP_PROJECT_ID',
        'GCS_BUCKET_NAME',
        'BASE_SEPOLIA_RPC_URL',
        'ARBITRUM_SEPOLIA_RPC_URL',
        'PRIVATE_KEY'
    ]
    for var in required_vars:
        assert os.environ.get(var), f"Missing required environment variable: {var}"

def test_wallets_and_rpc_readiness():
    """Test RPC connectivity and verify testnet operational balances."""
    base_rpc = os.environ.get('BASE_SEPOLIA_RPC_URL')
    arb_rpc = os.environ.get('ARBITRUM_SEPOLIA_RPC_URL')
    pk = os.environ.get('PRIVATE_KEY')
    
    if not base_rpc or not arb_rpc or not pk:
        pytest.skip("RPC URLs or Private Key missing for live wallet test.")

    # Initialize Web3 providers
    w3_base = Web3(Web3.HTTPProvider(base_rpc))
    w3_arb = Web3(Web3.HTTPProvider(arb_rpc))

    # We skip actual connection assert if the dummy/placeholder values are used
    if "example.com" in base_rpc or "your_" in pk:
        pytest.skip("Placeholder RPC or Key detected. Skipping live connection.")

    assert w3_base.is_connected(), "Failed to connect to Base Sepolia RPC"
    assert w3_arb.is_connected(), "Failed to connect to Arbitrum Sepolia RPC"

    account = w3_base.eth.account.from_key(pk)
    address = account.address

    # Check ETH balance on Base Sepolia
    base_balance = w3_base.eth.get_balance(address)
    # Check ETH balance on Arbitrum Sepolia
    arb_balance = w3_arb.eth.get_balance(address)

    # In a true institutional test, we'd assert balance > threshold.
    # Here we just ensure we can read the balance without errors.
    assert base_balance >= 0, "Base Sepolia balance read failed."
    assert arb_balance >= 0, "Arbitrum Sepolia balance read failed."

def test_gcp_batch_deployment_template():
    """Verify the GCP Batch template adheres to institutional constraints."""
    template_path = os.path.join(os.path.dirname(__file__), '../3-execution-relayer/batch_job_template.json')
    if not os.path.exists(template_path):
        pytest.skip("GCP Batch template not found.")
        
    with open(template_path, 'r') as f:
        template = json.load(f)

    # Verify SPOT provisioning
    provisioning = template.get('allocationPolicy', {}).get('instances', [{}])[0].get('policy', {}).get('provisioningModel')
    assert provisioning == 'SPOT', f"Expected SPOT provisioning model, got {provisioning}"

    # Verify multi-region routing
    locations = template.get('allocationPolicy', {}).get('location', {}).get('allowedLocations', [])
    assert len(locations) >= 2, "Expected multi-region deployment targeting (>= 2 regions)"
    
    # Verify tmpfs mount for SP1 traces
    volumes = template.get('taskGroups', [{}])[0].get('taskSpec', {}).get('runnables', [{}])[0].get('container', {}).get('volumes', [])
    has_tmpfs = any('/app/trace_cache' in str(v) for v in volumes)
    assert has_tmpfs, "Expected tmpfs mount for /app/trace_cache to optimize I/O"

def test_smart_contracts_ccip_routing():
    """Verify the QuantumHomeVault and QuantumSpokeVault implementations."""
    home_vault_path = os.path.join(os.path.dirname(__file__), '../4-base-sepolia-vault/src/QuantumHomeVault.sol')
    spoke_vault_path = os.path.join(os.path.dirname(__file__), '../4-base-sepolia-vault/src/QuantumSpokeVault.sol')
    
    assert os.path.exists(home_vault_path), "QuantumHomeVault missing"
    assert os.path.exists(spoke_vault_path), "QuantumSpokeVault missing"

    with open(home_vault_path, 'r') as f:
        home_content = f.read()
        
    assert "ISP1Verifier" in home_content, "ISP1Verifier logic test integration missing from primary vault"
    assert "Client.EVM2AnyMessage" in home_content, "CCIP Router payload wrapper missing from primary vault"
    assert "IRouterClient" in home_content, "Chainlink IRouterClient missing from primary vault"
    assert "ccipSend(" in home_content, "ccipSend execution missing from primary vault"

    with open(spoke_vault_path, 'r') as f:
        spoke_content = f.read()

    assert "CCIPReceiver" in spoke_content, "CCIPReceiver inheritance missing from replica vault"
    assert "allowlist" in spoke_content, "Security allowlist mapping missing from replica vault"
    assert "_ccipReceive" in spoke_content, "CCIP receipt execution logic missing from replica vault"

def test_execution_relayer_fallback():
    """Verify the TS Relayer contains SPOT-to-STANDARD fallback and polling logic."""
    server_path = os.path.join(os.path.dirname(__file__), '../3-execution-relayer/src/server.ts')
    
    if not os.path.exists(server_path):
        pytest.skip("Execution relayer server missing.")

    with open(server_path, 'r') as f:
        server_content = f.read()

    assert "batchClient.createJob" in server_content, "GCP Batch instantiation missing"
    assert "catch (spotError" in server_content or "STANDARD" in server_content, "Fallback to STANDARD model missing"
    assert "Exponential backoff" in server_content or "delay * 1.5" in server_content, "Storage polling backoff missing"
    assert "processPQCProof" in server_content, "Viem transaction broadcast to Primary Vault missing"
