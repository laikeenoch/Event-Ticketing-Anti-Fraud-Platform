# Event Ticketing Anti-Fraud Platform

A comprehensive blockchain-based event ticketing system built on Stacks that prevents fraud through cryptographic verification and smart contract automation.

## Overview

This platform addresses common ticketing fraud issues including fake tickets, unauthorized resales, double-spending, and fraudulent event creation through a suite of interconnected smart contracts.

## System Architecture

### Core Contracts

1. **Organizer Verification Contract** (`organizer-verification.clar`)
    - Validates legitimate event creators
    - Maintains reputation scoring system
    - Handles organizer registration and verification

2. **Ticket Issuance Contract** (`ticket-issuance.clar`)
    - Creates tamper-proof event tickets as NFTs
    - Manages ticket metadata and pricing
    - Controls ticket supply and distribution

3. **Resale Regulation Contract** (`resale-regulation.clar`)
    - Controls secondary ticket market transactions
    - Enforces price caps and transfer restrictions
    - Tracks ownership history

4. **Attendance Verification Contract** (`attendance-verification.clar`)
    - Confirms ticket usage at events
    - Prevents double-entry fraud
    - Records attendance data

5. **Refund Processing Contract** (`refund-processing.clar`)
    - Handles ticket cancellation and refunds
    - Manages refund policies and timelines
    - Processes automated refunds

## Key Features

- **Fraud Prevention**: Cryptographic verification prevents counterfeit tickets
- **Organizer Verification**: Multi-step verification process for event creators
- **Controlled Resale**: Regulated secondary market with price protection
- **Attendance Tracking**: Real-time verification and fraud detection
- **Automated Refunds**: Smart contract-based refund processing
- **Reputation System**: Trust scoring for organizers and participants

## Security Features

- Immutable ticket records on blockchain
- Multi-signature verification for high-value events
- Rate limiting to prevent spam and abuse
- Emergency pause functionality for critical issues
- Comprehensive audit trails

## Getting Started

### Prerequisites

- Clarinet CLI installed
- Node.js 18+ for testing
- Stacks wallet for interaction

### Installation

\`\`\`bash
git clone <repository-url>
cd event-ticketing-platform
npm install
clarinet check
\`\`\`

### Testing

\`\`\`bash
npm test
\`\`\`

### Deployment

\`\`\`bash
clarinet deploy --testnet
\`\`\`

## Usage Examples

### Register as Event Organizer

\`\`\`clarity
(contract-call? .organizer-verification register-organizer
"Event Company LLC"
"contact@eventcompany.com"
"https://eventcompany.com")
\`\`\`

### Create Event and Issue Tickets

\`\`\`clarity
(contract-call? .ticket-issuance create-event
"Summer Music Festival"
"2024-07-15T18:00:00Z"
"Central Park, NYC"
u1000
u50000000)
\`\`\`

### Purchase Ticket

\`\`\`clarity
(contract-call? .ticket-issuance purchase-ticket u1)
\`\`\`

### Verify Attendance

\`\`\`clarity
(contract-call? .attendance-verification verify-attendance u1 u1)
\`\`\`

## Contract Interactions

The contracts work together to provide a complete ticketing ecosystem:

1. Organizers must be verified before creating events
2. Tickets are issued as unique NFTs with embedded metadata
3. Resales are tracked and regulated through the resale contract
4. Attendance is verified to prevent fraud
5. Refunds are processed automatically based on predefined rules

## Error Codes

- `ERR-NOT-AUTHORIZED` (u100): Caller lacks required permissions
- `ERR-INVALID-INPUT` (u101): Invalid input parameters
- `ERR-NOT-FOUND` (u102): Requested resource not found
- `ERR-ALREADY-EXISTS` (u103): Resource already exists
- `ERR-INSUFFICIENT-FUNDS` (u104): Insufficient payment
- `ERR-EVENT-EXPIRED` (u105): Event has already occurred
- `ERR-TICKET-USED` (u106): Ticket already used for entry
- `ERR-TRANSFER-RESTRICTED` (u107): Transfer not allowed
- `ERR-REFUND-EXPIRED` (u108): Refund period has expired

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

For technical support or questions, please open an issue on GitHub or contact the development team.
