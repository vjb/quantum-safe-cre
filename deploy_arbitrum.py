import json
import subprocess
import sys

def run(cmd):
    return subprocess.run(cmd, shell=True, capture_output=True, text=True)

print("Fetching bytecode...")
with open("c:/Users/vjbel/hacks/quantum-safe-cre/4-base-sepolia-vault/out/QuantumSpokeVault.sol/QuantumSpokeVault.json", "r") as f:
    data = json.load(f)
    bytecode = data["bytecode"]["object"]

print("Fetching constructor args...")
res = run("cast abi-encode \"constructor(address)\" 0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165")
if res.returncode != 0:
    print("Failed to encode args", res.stderr)
    sys.exit(1)

# Sometimes cast outputs warnings, we want the last line
args = res.stdout.strip().split("\n")[-1]

full_bytecode = bytecode + args[2:]

cmd = f"cast send --rpc-url https://sepolia-rollup.arbitrum.io/rpc --private-key 0xfb466a6f0ea5f2ce83b52e22f4f80fccd13964d9d25ad18b5646e68fbc95e7e1 --create {full_bytecode}"
print("Sending transaction...")
res = run(cmd)
print(res.stdout)
if res.returncode != 0:
    print(res.stderr)
