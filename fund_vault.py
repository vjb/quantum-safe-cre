import subprocess
import sys

if len(sys.argv) < 2:
    print("Usage: python fund_vault.py <VAULT_ADDRESS>")
    sys.exit(1)

vault_address = sys.argv[1]
link_address = "0xE4aB69C077896252FAFBD49EFD26B5D171A32410"
amount = "1000000000000000000" # 1 LINK
private_key = "0xfb466a6f0ea5f2ce83b52e22f4f80fccd13964d9d25ad18b5646e68fbc95e7e1"
rpc_url = "https://sepolia.base.org"

cmd = f'cast send {link_address} "transfer(address,uint256)" {vault_address} {amount} --rpc-url {rpc_url} --private-key {private_key}'

print(f"Funding vault {vault_address} with 1 LINK...")
res = subprocess.run(cmd, shell=True, capture_output=True, text=True)

if res.returncode == 0:
    print("Successfully funded the vault!")
    print(res.stdout)
else:
    print("Failed to fund the vault!")
    print(res.stderr)
    sys.exit(1)
