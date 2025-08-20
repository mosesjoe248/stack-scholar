Stack-Scholar Smart Contract

The **Stack-Scholar** smart contract enables **decentralized scholarship funding** on the Stacks blockchain.  
It provides a transparent, secure, and efficient way for sponsors to fund scholarships and for students to apply and receive awards directly on-chain.

---

Features

- **Create Scholarships** – Sponsors can create scholarships with funding criteria (amount, deadline, eligibility).  
- **Fund Scholarships** – Contributors can securely add STX funds to scholarship pools.  
- **Apply for Scholarships** – Students can submit applications on-chain with unique identifiers.  
- **Award Scholarships** – Sponsors or administrators can award funds directly to selected recipients.  
- **Transparency** – All transactions, applications, and awards are recorded on-chain for accountability.

---

Smart Contract Functions

- `create-scholarship` → Initialize a new scholarship.  
- `fund-scholarship` → Allow sponsors/contributors to fund a scholarship in STX.  
- `apply-scholarship` → Students apply for available scholarships.  
- `award-scholarship` → Distribute scholarship funds to selected recipients.  
- `get-scholarship-info` → Retrieve details of a scholarship.  

---

Getting Started

Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed for local development and testing.  
- Basic knowledge of [Clarity Smart Contracts](https://docs.stacks.co/write-smart-contracts/clarity-overview).  

Setup
```bash
# Clone the repository
git clone https://github.com/your-username/stack-scholar.git

# Navigate to project folder
cd stack-scholar

# Run tests
clarinet test
