import { validateJournal } from './oracle';

describe('Chainlink Oracle Coordinator', () => {
    it('Should successfully extract and validate correct journal outputs', () => {
        const mockDockerOutput = `
Starting SP1 Host Orchestrator...
Preparing SP1 Prover Client...
Generating STARK proof...
Execution completed in 2.3s
Successfully verified and committed message: Transfer 10 USDC
        `;
        
        expect(validateJournal(mockDockerOutput, 'Transfer 10 USDC')).toBe(true);
    });

    it('Should block journal spoofing and throw error', () => {
        const maliciousOutput = `
Starting SP1 Host Orchestrator...
Preparing SP1 Prover Client...
Generating STARK proof...
Successfully verified and committed message: Transfer 100 USDC
        `;
        
        expect(() => validateJournal(maliciousOutput, 'Transfer 10 USDC')).toThrow("DON Consensus Failed: Journal Mismatch Detected");
    });
});
