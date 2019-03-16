# EM Token: The Electronic Money Token standard

Contributors: xxx

## Objective

The EM Token standard aims to enable the issuance of regulated electronic money on blockchain networks, and its practical usage in real financial applications.

* [Background](https://github.com/juliofaura/EM-Token/blob/master/README.md#background)
* [Overview](https://github.com/juliofaura/EM-Token/README.md#overview)
* [Methods and Events](https://github.com/juliofaura/EM-Token/blob/master/README.md#data-types-methods-and-events-minimal-standard-implementation)
* [Implementaion](https://github.com/juliofaura/EM-Token/blob/master/README.md#implementation)
* [Future work](https://github.com/juliofaura/EM-Token/blob/master/README.md#future-work)
* [To Do's](https://github.com/juliofaura/EM-Token/blob/master/README.md#to-dos)



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
* **Clearing**: In addition to the standard ERC20 "transfer" method, EM Token provides a way to submit transfers that need to be cleared by the token issuing authority offchain. These transfers are then executed in two steps: i) transfers are ordered, and ii) after clearing them, transfers are executed or rejected by the operator of the token contract
* **Holds**: token balances can be put on hold, which will make the held amount unavailable for further use until the hold is resolved (i.e. either executed or released). Holds have a payer, a payee, and a notary who is in charge of resolving the hold. Holds also implement expiration periods, after which anyone can release the hold. Holds are similar to escrows in that are firm and lead to final settlement. Holds can also be used to implement collateralization
* **Credit lines**: an EM Token wallet can have associated a credit line, which is automatically drawn when transfers or holds are performed and there is insufficient balance in the wallet - i.e. the `transfer` method will then not throw if there is enough available credit in the wallet. Credit lines generate interest that is automatically accrued in the relevant associated token wallets
* **Funding request**: users can ask for a wallet funding request by calling the smart contract and attaching a direct debit instruction string. The tokenizer reads this request, interprets the debit instructions, and triggers a transfer in the bank ledger to initiate the tokenization process  
* **Redeem**: users can request redemptions by calling the smart contract and attaching a payment instruction string. The (de)tokenizer reads this request, interprets the payment instructions, and triggers the transfer of funds (typically from the omnibus account) into the destination account, if possible

The EM Token is thus different from other tokens commonly referred to as "stable coins" in that it is designed to be issued, burnt and made available to users in a compliant manner (i.e. with full KYC and AML compliance) through a licensed vehicle (an electronic money entity, a bank, or a central bank), and in that it provides the additional functionality described above so it can be used by other smart contracts implementing more complex financial applications such as interbank payments, supply chain finance instruments, or the creation of EM-Token denominated bonds and equities with automatic delivery-vs-payment

## Data types, methods and events (minimal standard implementation)

The EM Token standard specifies a set of data types, methods and events that ensure interoperability between different implementations. All these elements are included and described in the ```interface/I*.sol``` files. The following picture schamtically describes the hierarchy of these interface files:

![EM Token standard structure](./diagrams/standard_structure.png?raw=true "EM Token standard structure")

* [Basic token information](https://github.com/juliofaura/EM-Token/blob/master/README.md#basic-token-information)
* [ERC 20](https://github.com/juliofaura/EM-Token/blob/master/README.md#erc20-standard)
* [Holds](https://github.com/juliofaura/EM-Token/blob/master/README.md#holds)
* [Overdrafts](https://github.com/juliofaura/EM-Token/blob/master/README.md#overdrafts)
* [Funding](https://github.com/juliofaura/EM-Token/blob/master/README.md#funding)
* [Payouts](https://github.com/juliofaura/EM-Token/blob/master/README.md#payouts)
* [Compliance](https://github.com/juliofaura/EM-Token/blob/master/README.md#compliance)
* [Compliance](https://github.com/juliofaura/EM-Token/blob/master/README.md#compliance)
* [Consolidated Ledger](https://github.com/juliofaura/EM-Token/blob/master/README.md#consolidated-ledger)


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
function transferFrom(address from, address to, uint256 value) external returns (bool);
function balanceOf(address owner) external view returns (uint256);
function allowance(address owner, address spender) external view returns (uint256);
```

And also the basic events:
```
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);
 ```

Note that in this case the ```balanceOf()``` method will only return the token balance amount without taking into account balances on hold or overdraft limits. Therefore a ```transfer``` may not necessarily succeed even if the balance as returned by ```balanceOf()``` is higher than the amount to be transferred, nor may it fail if the balance is low. Further down we will document some methods that retrieve the amount of _available_  funds, as well as the _net_ balance taking into account drawn overdraft lines

### _Holds_

EM Tokens provide the possibility to perform holds on tokens. A hold is created with the following fields:
* **issuer**: the address that issues the hold, be it the wallet owner or an approved holder
* **transactionId**: an unique transaction ID provided by the holder to identify the hold throughout its life cycle
* **from**: the wallet from which the tokens will be transferred in case the hold is executed (i.e. the payer)
* **to**: the wallet that will receive the tokens in case the hold is executed (i.e. the payee)
* **notary**: the address that will either execute or release the hold (after checking whatever condition)
* **amount**: the amount of tokens that will be transferred
* **expires**: a flag indicating whether the hold will have an expiration time or not
* **expiration**: the timestamp since which the hold is considered to be expired (in case ```expires==true```)
* **status**: the status of the hold, which can be one of the following as defined in the ```HoldStatusCode``` enum type (also part of the standard)

```
enum HoldStatusCode { Nonexistent, Created, ExecutedByNotary, ExecutedByOperator, ReleasedByNotary, ReleasedByOperator, ReleasedDueToExpiration }
```

Holds are to be created directly by wallet owners. Wallet owners can also approve others to perform holds on their behalf:

```
function approveToHold(address holder) external returns (bool);
function revokeApprovalToHold(address holder) external returns (bool);
```

Note that approvals are yes or no, without allowances (as in ERC20's approve method)

The key methods are ```hold``` and ```holdFrom```, which create holds on behalf of payers:

```
function hold(string calldata transactionId, address to, address notary, uint256 amount, bool expires, uint256 timeToExpiration) external returns (uint256 index);
function holdFrom(string calldata transactionId, address from, address to, address notary, uint256 amount, bool expires, uint256 timeToExpiration) external returns (uint256 index);
```

Unique transactionIDs are to be provided by the issuer of the hold. Internally, keys are to be built by hashing the address of the issuer and the transactionId, which therefore supports the possibility of different issuers of holds using the same transactionId.

Once the hold has been created, the hold can either be released (i.e. closed without further consequences, thus making the locked funds again available for transactions) or executed (i.e. executing the transfer between the payer and the payee). The issuer of the hold can also renew the hold (i.e. adding more time to the current expiration date):

```
function releaseHold(address issuer, string calldata transactionId) external returns (bool);
function executeHold(address issuer, string calldata transactionId) external returns (bool);
function renewHold(string calldata transactionId, uint256 timeToExpirationFromNow) external returns (bool);
```

The hold can be released (i.e. not executed) in four possible ways:
* By the notary
* By the operator or owner
* By the payee (as a way to reject the projected transfer)
* By the issuer, but only after the expiration time

The hold can be executed in two possible ways:
* By the notary (the normal)
* By the operator (e.g. in emergency cases)

The hold cannot be executed or renewed after expiration by any party. It can only be released in order to become closed.

Also, some ```view``` methods are provided to retrieve information about holds:

```
function isApprovedToHold(address wallet, address holder) external view returns (bool);
function retrieveHoldData(address issuer, string calldata transactionId) external view returns (uint256 index, address from, address to, address notary, uint256 amount, bool expires, uint256 expiration, HoldStatusCode status);
function balanceOnHold(address account) external view returns (uint256);
function totalSupplyOnHold() external view returns (uint256);
```

```balanceOnHold``` and ```totalSupplyOnHold``` return the addition of all the amounts of hold for an address or for all addresses, respectively

A number of events are to be sent as well:

```
event HoldCreated(address issuer, string indexed transactionId, address indexed from, address to, address indexed notary, uint256 amount, bool expires, uint256 expiration, uint256 index );
event HoldExecuted(address issuer, string indexed transactionId, HoldStatusCode status);
event HoldReleased(address issuer, string indexed transactionId, HoldStatusCode status);
event HoldRenewed(address issuer, string indexed transactionId, uint256 oldExpiration, uint256 newExpiration);
```

### _Overdrafts_

The EM Token implements the possibility of token balances to be negative through the implementation of unsecured overdraft lines subject to limits to be set by a CRO. Changes in overdraft limits results in sending events:

```
event UnsecuredOverdraftLimitSet(address indexed account, uint256 oldLimit, uint256 newLimit);
```

View methods allow to know the limits and the drawn amounts from the credit line:

```
function unsecuredOverdraftLimit(address account) external view returns (uint256);
function drawnAmount(address account) external view returns (uint256);
```

### _Cleared transfers_

EM Token contracts provide the possibility of ordering and managing transfers that are not atomically executed, but rather need to be cleared by the token issuing authority before being executed (or rejected). Cleared transfers then have a status which changes along the process, of type ```ClearedTransferRequestStatusCode```:

```
enum ClearedTransferRequestStatusCode { Nonexistent, Requested, InProcess, Executed, Rejected, Cancelled }
```

Cleared transfers can be ordered by wallet owners or by approved parties (again, no allowances are implemented):
```
function approveToRequestClearedTransfer(address requester) external returns (bool);
function revokeApprovalToRequestClearedTransfer(address requester) external returns (bool);
```

Cleared transfers are then submitted in a similar fashion to normal (ERC20) transfers, but using an unique identifier similar to the case of transactionIds in holds (again, internally the keys are built from the address of the requester and the transactionId). Upon submission of the cleared transfer request, a hold is performed on the ```fromWallet``` to secure the funds that will be transferred:

```
function orderClearedTransfer(string calldata transactionId, address to, uint256 amount) external returns (uint256 index);
function orderClearedTransferFrom(string calldata transactionId, address from, address to, uint256 amount) external returns (uint256 index);
```

Right after the transfer has been ordered (status is ```Requested```), the issuer can still cancel the transfer:

```
function cancelClearedTransferRequest(string calldata transactionId) external returns (bool);
```

The token contract owner / operator has then methods to manage the workflow process:

* The ```processClearedTransferRequest``` moves the status to ```InProcess```, which then forbids the issuer to be able to cancel the transfer request. This also can be used by the operator to freeze everything, e.g. in the case of a positive in AML screening

```
function processClearedTransferRequest(address requester, string calldata transactionId) external returns (bool);
```

* The ```executeClearedTransferRequest``` method allows the operator to approve the execution of the transfer, which effectively triggers the execution of the hold, which then moves the token from the ```from``` to the ```to```:

```
function executeClearedTransferRequest(address requester, string calldata transactionId) external returns (bool);
```

* The operator can also reject the transfer request by calling the ```rejectClearedTransferRequest```. In this case a reason can be provided:

```
function rejectClearedTransferRequest(address requester, string calldata transactionId, string calldata reason) external returns (bool);
```

Some ```view``` methods are also provided :

```
function isApprovedToRequestClearedTransfer(address wallet, address requester) external view returns (bool);
function retrieveClearedTransferData(address requester, string calldata transactionId) external view returns (uint256 index, address from, address to, uint256 amount, ClearedTransferRequestStatusCode status );
```

A number of events are also casted on eventful transactions:

```
event ClearedTransferRequested( address indexed requester, string indexed transactionId, address indexed fromWallet, address toWallet, uint256 amount, uint256 index );
event ClearedTransferRequestInProcess(address requester, string indexed transactionId);
event ClearedTransferRequestExecuted(address requester, string indexed transactionId);
event ClearedTransferRequestRejected(address requester, string indexed transactionId, string reason);
event ClearedTransferRequestCancelled(address requester, string indexed transactionId);
event ApprovalToRequestClearedTransfer(address indexed wallet, address indexed requester);
event RevokeApprovalToRequestClearedTransfer(address indexed wallet, address indexed requester);
```

### _Funding_

Token wallet owners (or approved addresses) can issue tokenization requests through the blockchain. This is done by calling the ```requestfunding``` or ```requestFundingFrom``` methods, which initiate the workflow for the token contract operator to either honor or reject the request. In this case, funding instructions are provided when submitting the request, which are used by the operator to determine the source of the funds to be debited in order to do fund the token wallet (through minting). In general, it is not advisable to place explicit routing instructions for debiting funds on a verbatim basis on the blockchain, and it is advised to use a private channel to do so (external to the blockchain ledger). Another (less desirable) possibility is to place these instructions on the instructions field on encrypted form.

A similar phillosophy to Cleared Transfers is applied to the case of funding requests, i.e.:

* A unique transactionId must be provided by the requester
* A similar workflow is provided with similar status codes
* The operator can execute and reject the funding request

Status codes are self-explanatory:

```
enum FundingRequestStatusCode { Nonexistent, Requested, InProcess, Executed, Rejected, Cancelled }
```

Transactional methods are provided to manage the whole cycle of the funding request:

```
function approveToRequestFunding(address requester) external returns (bool);
function revokeApprovalToRequestFunding(address requester) external returns (bool) ;
function requestFunding(string calldata transactionId, uint256 amount, string calldata instructions) external returns (uint256 index);
function requestFundingFrom(string calldata transactionId, address walletToFund, uint256 amount, string calldata instructions) external returns (uint256 index);
function cancelFundingRequest(string calldata transactionId) external returns (bool);
function processFundingRequest(address requester, string calldata transactionId) external returns (bool);
function executeFundingRequest(address requester, string calldata transactionId) external returns (bool);
function rejectFundingRequest(address requester, string calldata transactionId, string calldata reason) external returns (bool);
```

View methods are also provided:

```
function isApprovedToRequestFunding(address walletToFund, address requester) external view returns (bool);
function retrieveFundingData(address requester, string calldata transactionId) external view returns (uint256 index, address walletToFund, uint256 amount, string memory instructions, FundingRequestStatusCode status);
```

Events are to be sent on relevant transactions:

```
event FundingRequested(address indexed requester, string indexed transactionId, address indexed walletToFund, uint256 amount, string instructions, uint256 index);
event FundingRequestInProcess(address requester, string indexed transactionId);
event FundingRequestExecuted(address requester, string indexed transactionId);
event FundingRequestRejected(address requester, string indexed transactionId, string reason);
event FundingRequestCancelled(address requester, string indexed transactionId);
event ApprovalToRequestFunding(address indexed walletToFund, address indexed requester);
event RevokeApprovalToRequestFunding(address indexed walletToFund, address indexed requester);
```

### _Payouts_

Similary to funding requests, token wallet owners (or approved addresses) can issue payout requests through the blockchain. This is done by calling the ```requestPayout``` or ```requestPayoutFrom``` methods, which initiate the workflow for the token contract operator to either honor or reject the request.

In this case, the following movement of tokens are done as the process progresses:

* Upon launch of the payout request, the appropriate amount of funds are placed on a hold with no notary (i.e. it is an internal hold that cannot be released)
* The operator then puts the payout request ```InProcess```, which executes the hold and moves the funds to a suspense wallet
* The operator then moves the funds offchain from the omnibus account to the appropriate destination account, then burning the tokens from the suspense wallet
* Either before or after placing the request ```InProcess```, the operator can also reject the payout, which returns the funds to the payer and eliminates the hold

Also in this case, payout instructions are provided when submitting the request, which are used by the operator to determine the desination of the funds to be transferred from the omnibus account. In general, it is not advisable to place explicit routing instructions for debiting funds on a verbatim basis on the blockchain, and it is advised to use a private channel to do so (external to the blockchain ledger). Another (less desirable) possibility is to place these instructions on the instructions field on encrypted form.

Status codes are self-explanatory:

```
enum PayoutRequestStatusCode { Nonexistent, Requested, InProcess, Executed, Rejected, Cancelled }
```

Transactional methods are provided to manage the whole cycle of the payout request:

```
function approveToRequestPayout(address requester) external returns (bool);
function revokeApprovalToRequestPayout(address requester) external returns (bool);
function requestPayout(string calldata transactionId, uint256 amount, string calldata instructions) external returns (uint256 index);
function requestPayoutFrom(string calldata transactionId, address walletToDebit, uint256 amount, string calldata instructions) external returns (uint256 index);
function cancelPayoutRequest(string calldata transactionId) external returns (bool);
function processPayoutRequest(address requester, string calldata transactionId) external returns (bool);
function executePayoutRequest(address requester, string calldata transactionId) external returns (bool);
function rejectPayoutRequest(address requester, string calldata transactionId, string calldata reason) external returns (bool);
```

View methods are also provided:

```
function isApprovedToRequestPayout(address walletToDebit, address requester) external view returns (bool);
function retrievePayoutData(address requester, string calldata transactionId) external view returns (uint256 index, address walletToDebit, uint256 amount, string memory instructions, PayoutRequestStatusCode status);
```

Events are to be sent on relevant transactions:

```
event PayoutRequested(address indexed requester, string indexed transactionId, address indexed walletToDebit, uint256 amount, string instructions, uint256 index);
event PayoutRequestInProcess(address requester, string indexed transactionId);
event PayoutRequestExecuted(address requester, string indexed transactionId);
event PayoutRequestRejected(address requester, string indexed transactionId, string reason);
event PayoutRequestCancelled(address requester, string indexed transactionId);
event ApprovalToRequestPayout(address indexed walletToDebit, address indexed requester);
event RevokeApprovalToRequestPayout(address indexed walletToDebit, address indexed requester);
```

### _Compliance_

In EM Token, all user-initiated methods should be checked from a compliance point of view. To do this, a set of functions is provided that return a flag indicating whether a transaction can be done, and a reason in case the answer is no (if possible). These functions are ```view``` and can be called by the user, however the real transactional methods should ```require```these functions to return ```true``` to avoid non-authorized transactions to go through

```
function checkTransfer(address from, address to, uint256 value) external view returns (bool canDo, string memory reason);
function checkApprove(address allower, address spender, uint256 value) external view returns (bool canDo, string memory reason);

function checkHold(address from, address to, address notary, uint256 value) external view returns (bool canDo, string memory reason);
function checkApproveToHold(address from, address holder) external view returns (bool canDo, string memory reason);

function checkApproveToOrderClearedTransfer(address fromWallet, address requester) external view returns (bool canDo, string memory reason);
function checkOrderClearedTransfer(address fromWallet, address toWallet, uint256 value) external view returns (bool canDo, string memory reason);

function checkApproveToRequestFunding(address walletToFund, address requester) external view returns (bool canDo, string memory reason);
function checkRequestFunding(address walletToFund, address requester, uint256 value) external view returns (bool canDo, string memory reason);
    
function checkApproveToRequestPayout(address walletToDebit, address requester) external view returns (bool canDo, string memory reason);
function checkRequestPayout(address walletToDebit, address requester, uint256 value) external view returns (bool canDo, string memory reason);
```

### _Consolidated ledger_

The EM Token ledger is composed on the interaction of three main entries that determine the amount of available funds for transactions:

* **Token balances**, like the ones one would receive when calling the ```balanceOf``` method
* **Drawn overdrafts**, which are effectively negative balances
* **Balance on hold**, resulting from the active holds in each moment

The combination of these three determine the availability of funds in each mmoment. Two methods are given to know these amounts:

```
function availableFunds(address wallet) external view returns (uint256);
function netBalanceOf(address wallet) external view returns (int256);
function totalDrawnAmount() external view returns (uint256);
```

```availableFunds()``` is calculated as ```balanceOf()``` plus ```unsecuredOverdraftLimit()``` minus ```drawnAmount()``` minus ```balanceOnHold()```

```netBalanceOf()``` is calculated as ```balanceOf()``` minus ```drawnAmount()```, although it should be guaranteed that at least one of these two is zero at all times (i.e. one cannot have a positive token balance and a drawn overdraft at the same time)

```totalDrawnAmount()``` returns the total amount drawn from all overdraft lines in all wallets (analogous to the totalSupply() method)


## Implementation ##

A reference implementation is provided, as per the following diagram:

![EM Token example implementation](./diagrams/implmentation_structure.png?raw=true "EM Token example implementation")

Some highlights:

* Basic "ledger" contracts providing internal methods are used as the base (then consolidated in the ```ConsolidatedLedger``` contract), so then the top contracts can use these to do accounting with a holistic view (e.g. ```transfer``` taking into account balances on hold and overdraft limits)
* The ```Compliant``` contract only implements very bsaic compliance checks for all methods, namely whether the involved parties in the transaction are whitelisted (as per the ```Whitelistable``` contract). Other, more elaborated versions of this are based on the R-Token contract, which provides compliance check functions on a "regulator service" implemented on a external contract that is accessed through a registry
* A ```RoleControl``` contract is used to provide basic role management beyond ```Ownable```, i.e. to control roles for ledger operators, CROs, compliance officers, etc. And also to provide several addresses with the same role
* An eternal storage construct is used to facilitate migrations. Essentially, all the storage variables throughout the contracts are implemented as pointers to the actual storage, which is implemented in a separate ```EternalStorage``` contract. This way, new versions of the main contract can be deployed and directed to the same eternal storage (or even several contracts can be used at the same time over the same eternal storage)

These implementation details are not part of the standard, although they can be considered best practices

## Future work

* Interest in overdraft lines
* Ledger management utilities (i.e. direct methods to mint, burn, modify status of requests etc. by the operator
* Iteration utilities in some mappings (e.g. list of approved holders for a wallet)
* R-Token registry for compliance checks
* A ```requestWallet``` method to rquest whitelisting (so whitelisting can be honored on the basis of a request)

## To Do's:

* TO DO: propose a new name for ```transactionId```, so it is not confused with Ethereum transactions
* TO DO: consider adding roles to the standard
* TO DO: Check out ERC777 and extend this to comply with it, if appropriate
* TO DO: add interest payments and out-of-limit penalties
