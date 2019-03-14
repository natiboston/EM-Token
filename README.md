# EM Token: The Electronic Money Token standard

Contributors: xxx

## Objective

The EM Token standard aims to enable the issuance of regulated electronic money on blockchain networks, and its practical usage in real financial applications.

## Background

Financial institutions work today with electronic systems which hold account balances in databases on core banking systems. In order for an institution to be allowed to maintain records of client balances segregated and available for clients, such institution must be regulated under a known legal framework and must possess a license to do so. Maintaining a license under regulatory supervision entails ensuring compliance (i.e. performing KYC on all clients and ensuring good AML practices before allowing transactions) and demonstrating technical and operational solvency through periodic audits, so clients depositing funds with the institution can rest assured that their money is safe.

There are only a number of potential regulatory license frameworks that allow institutions to issue and hold money balances for customers (be it retail corporate or institutional types). The most important and practical ones are three:
* **Electronic money entities**: these are leanly regulated vehicles that are mostly used today for cash and payments services, instead of more complex financial services. For example prepaid cards or online payment systems such as PayPal run on such schemes. In most jurisdictions, electronic money balances are required to be 100% backed by assets, which often entails hold cash on an omnibus account at a bank with 100% of the funds issued to clients in the electronic money ledger   
* **Banking licenses**: these include commercial and investment banks, which segregate client funds using current and other type of accounts implemented on core banking systems. Banks can create money by lending to clients, so bank money can be backed by promises to pay and other illiquid assets 
* **Central banks**: central banks hold balances for banks in RTGS systems, similar to core banking systems but with much more restricted yet critical functionality. Central banks create money by lending it to banks, which pledge their assets to central banks as a lender of last resort for an official interest rate

Regulations for all these types of electronic money are local, i.e. only valid for each jurisdiction and not valid in others. And regulations can vary dramatically in different jurisdictions - for example there are places with no electronic money frameworks, on everything has to be done through banking licenses or directly with a central bank. But in all cases compliance with existing regulation needs to ensured, in particular:
* **Know Your Customer (KYC)**: the institution needs to identify the client before providing her with the possibility of depositing money or transact. In different jurisdictions and for different types of licenses there are different levels of balance and activity that can be allowed for different levels of KYC. For example, low KYC requirements with little checks or even no checks at all can usually be acceptable in many jurisdictions if cashin balances are kept low (i.e. hundreds of dollars)
* **Anti Money Laundering (AML)**: the institution needs to perform checks of parties transacting with its clients, typically checking against black lists and doing sanction screening, most notably in the context international transactions

Beyond cash, financial instruments such as equities or bonds are also registered in electronic systems in most cases, although all these systems and the bank accounting systems are only connected through rudimentary messaging means, which leads to the need for reconciliations and manual management in many cases. Cash systems to provide settlement of transactions in the capital markets are not well connected to the transactional systems, and often entail delays and settlement risk

## Overview

The EM Token builds on Ethereum standards currently in use such as ERC20, but it extends them to provide few key additional pieces of functionality, needed in the regulated financial world:
* **Compliance**: EM Tokens implement a set of methods to check in advance whether user-initiated transactions can be done from a compliance point of view. Implementations must require that these methods return "true" before executing the transaction
* **Clearing**: In addition to the standard ERC20 "transfer" method, EM Token provides a way to subnit transfers that need to be cleared by the token issuing authority offchain. These transfers are then executed in two steps: i) transfers are ordered, and ii) after clearing them, transfers are executed or rejected by the operator of the token contract
* **Holds**: token balances can be put on hold, which will make the held amount unavailable for further use until the hold is resolved (i.e. either executed or released). Holds have a payer, a payee, and a notary who is in charge of resolving the hold. Holds also implement expiration periods, after which anyone can release the hold Holds are similar to escrows in that are firm and lead to final settlement. Holds can also be used to implement collateralization
* **Credit lines**: an EM Token wallet can have associated a credit line, which is automatically drawn when transfers or holds are performed and there is insufficient balance in the wallet - i.e. the `transfer` method will then not throw if there is enough available credit in the wallet. Credit lines generate interest that is automatically accrued in the relevant associated token wallets
* **Funding request**: users can ask for a wallet funding request by calling the smart contract and attaching a direct debit instruction string. The tokenizer reads this request, interprets the debit instructions, and triggers a transfer in the bank ledger to initiate the tokenization process  
* **Redeem**: users can request redemptions by calling the smart contract and attaching a payment instruction string. The (de)tokenizer reads this request, interprets the payment instructions, and triggers the transfer of funds (typically from the omnibus account) into the destination account, if possible

The EM Token is thus different from other tokens commonly referred to as "stable coins" in that it is designed to be issued, burnt and made available to users in a compliant manner (i.e. with full KYC and AML compliance) through a licensed vehicle (an electronic money entity, a bank, or a central bank), and in that it provides the additional functionality described above so it can be used by other smart contracts implementing more complex financial applications such as interbank payments, supply chain finance instruments, or the creation of EM-Token denominated bonds and equities with automatic delivery-vs-payment

## Data types, methods and events (minimal standard implementation)

The EM Token standard specifies a set of data types, methods and events that ensure interoperability between different implementations. All these elements are included and described in the interface/I*.sol files. The following picture schamtically describes the hierarchy of these interface files:

![EM Token standard structure](./diagrams/standard_structure.png?raw=true "EM Token standard structure")

### _Basic token information_

EM Tokens implement some basic informational methods, only used for reference:
```
function name() external view returns (string memory);
function symbol() external view returns (string memory);
function currency() external view returns (string memory);
function decimals() external view returns (uint8);
function version() external pure returns (string memory);
```

The ```Created``` event is sent upon contract instantiation:
```
event Created(string name, string symbol, string currency, uint8 decimals, string version);
```

### _ERC20 standard_

EM Tokens implement the basic ERC20 methods:
```
function transfer(address to, uint256 value) external returns (bool);
function approve(address spender, uint256 value) external returns (bool);
function increaseApproval(address spender, uint256 value) external returns (bool);
function decreaseApproval(address spender, uint256 value) external returns (bool);
function transferFrom(address from, address to, uint256 value) external returns (bool);
function balanceOf(address owner) external view returns (uint256);
function allowance(address owner, address spender) external view returns (uint256);
 ```

 And also the basic events:
 ```
 event Transfer(address indexed from, address indexed to, uint256 value);
 event Approval(address indexed owner, address indexed spender, uint256 value);
 ```

### _Holds_

EM Tokens implement the basic ERC20 methods:
```
```

## Implementation

Blah

## Implementation ##

![EM Token example implementation](./diagrams/implmentation_structure.png?raw=true "EM Token example implementation")

## Future work

Blah



================

Considerations:

* **EMToken**: This is just a top level wrapper with some informational constants (Symbol, currency, decimals, etc.)
* **Fundable, Redeemable, Clearable**: These add workflows to manage requests from clients, either to i) fund wallets, ii) pay out from wallets, or iii) make transfers that need to be cleared. In all cases the flow implies a two step process with intervention of an authorized operator on behalf of the tokenization entity, i.e.: i) the client requests a {funding, redemption, transfer that needs to be cleared}, and ii) the operator either honors or rejects such request. The wallet owner should also be able to cancel the request. 

=> need to provide consistency between all three, i.e. with names, types of parameters, etc.
=> not sure the request ID should be set by the user when placing the request, given that different actors may ask for redemptions simultaneously and competitively and that could result in inconsistencies. An implementation with an array and an index seems a better option (with the possibility to store a user-specific reference for convenience)

* **Holdable, Overdraftable**: These add holding and overdrafting capabilities. They are cumulative and each one should re-implement the user-initiated methods from the previous one - e.g. Overdraftable should re-implement "transfer" since the transfer should work if an overdraft limit is available; and Holdable should re-implement it as well since balances on hold should not be available for transfers

=> Same comment for holds: the hold ID should be set by the system, as it is a competitive resource. Again, it can contain a custom reference provided by the holder if needed

* **ManagedERC20**: This is the main ERC20 implementation, but adds the possibility for the operator to manually annotate the ledger

* **ERC20Ledger**: This is the base ERC20 ledger with balances and allowances (as private variables). This contract also adds the reference to the ServiceRegistry and the RegulatorService so it can be referenced from the rest of the hierarchy (because the basic ledger operations such as mints, burns and transfers happen here, although other operations happen at upper levels - e.g. changes to drawn credit lines)

* **EternalStorageWrapper**: This is a wrapper to use the eternal storage, so it can be consistently referenced from all the contracts (i.e. pointing to the same EternalStorage)

* **EternalStorage**: This is the generic, raw eternal data repository where all the storage data will be kept. No storage variables should be used in any contract, other than permissioning data etc. (i.e. owner-style addresses). All client-related data (balances, allowances, requests, etc.) should always be kept in this instance, so all the logic in the rest of the contracts can be safely migrated

* **ServiceRegistry** and **RegulatorService**: This is consistent with the RegulatedToken construct. The RegulatorService contract should have check methods for all user-initiated functions from all the contracts, i.e. transfers, approves, holds, funding/redemption requests, etc. Also, it should have "recording" functions to call evertime something happens in the ledger, i.e. a token is mint in a wallet or a transfer is made. All these functions will be referenced through the registry construct from all the contracts

=> "Owner"-type permissions will not be managed in the RegulatorService, and will be added instead in each contract. For instance the Chief Risk Officer permissioning will be added in the Overdraftable contract, instead of being referenced in the RegulatorService. The RegulatorService is intended to be used only to clear client-initiated functions
=> All client-initiated functions should have alternative versions to delegate the calls - e.g. "requestFunding" should have a "requestFundingFor" equivalent, and an "approveFundingRequester" function as well. Allowances should then be provided as well, rather than simple permissioning - except in the case of holds, which should be the normal way to move money from third parties. In this case, the requesters of holds should simply be waitlisted, and not subject to amount-specific approvals. As a matter of fact, it may be beneficial to restrict holders to be contracts always, and not individual users - so the contracts can be authorized once their logic is audited by the wallet owner