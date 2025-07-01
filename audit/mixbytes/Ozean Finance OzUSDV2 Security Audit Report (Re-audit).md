---
title: Ozean Finance OzUSDV2 Security Audit Report (Re-audit)
tags: [Ozean Finance, OzUSDV2]

---


**** FOR INTERNAL USE ONLY ****

---

# Ozean Finance OzUSDV2 Security Audit Report (Re-audit)

###### tags: `Ozean Finance`, `OzUSDV2`

## 1. INTRODUCTION

### 1.1 Disclaimer
The audit makes no statements or warranties regarding the utility, safety, or security of the code, the suitability of the business model, investment advice, endorsement of the platform or its products, the regulatory regime for the business model, or any other claims about the fitness of the contracts for a particular purpose or their bug-free status. 
    
The audit documentation is for discussion purposes only. The information presented in this report is confidential and privileged. If you are reading this report, you agree to keep it confidential, not to copy, disclose or disseminate without the agreement of the Client. If you are not the intended recipient(s) of this document, please note that any disclosure, copying or dissemination of its content is strictly forbidden.
    
### 1.2 Executive Summary
Ozean is a protocol that provides bridging and yield-bearing functionality. Users can deposit allowlisted stablecoins through the bridge contract to mint USDX tokens, which are then bridged to the Ozean L2 chain via LayerZero protocol. On the L2 side, users can deposit USDX into the OzUSDV2 vault contract to receive yield-bearing ozUSD tokens.

The audit was completed in one day by 3 auditors and included an in-depth manual review of the codebase, along with analysis using automated tools.

During the audit, in addition to verifying well-known attack vectors and items from our internal checklist, we thoroughly investigated the following areas:

* **Excess Value Refund Verification.**
The protocol utilizes LayerZero, which calculates messaging fees at the time of execution. These fees are paid by the user. As a result, there may be slight mismatches between the amount sent by the user and the actual required fee. We verified that in all such cases, any excess value is correctly refunded to the user.

* **ERC4626 Implementation Verification.**
The protocol leverages the ERC4626 standard to distribute yield among vault participants. We verified that the implementation adheres to the specification and behaves as expected in both deposit and withdrawal flows.

* **Access Control Enforcement.**
We verified that all critical administrative functions are properly protected by the **onlyOwner** modifier, preventing unauthorized users from executing sensitive operations. The protocol correctly restricts functions such as allowlist management, deposit cap modifications, fund withdrawals, yield distribution, and contract pausing to designated administrators only. Additionally, the access control model follows established best practices.

* **Token Allowlist Validation.**
The protocol supports deposits of various user-supplied tokens. We verified that tokens not explicitly whitelisted are correctly rejected. All bridge and staking contracts consult the allowlisted mapping before accepting token deposits, preventing malicious or unsupported assets from interacting with the protocol.

* **Fee-on-Transfer Token Protection.**
We verified that the protocol correctly rejects fee-on-transfer tokens by applying pre- and post-transfer balance checks. This ensures that the actual received token amount matches the expected value, mitigating risks posed by deflationary token mechanics.

* **Reentrancy Attack Prevention.**
Some protocol functions involve sending Ether back to users. We verified that all such state-changing functions are protected against reentrancy attacks using the nonReentrant modifier. The protocol leverages OpenZeppelin’s **ReentrancyGuard** to prevent nested calls that could manipulate contract state during execution.

* **Inflation Attack Protection.**
We verified that the vault is protected against inflation attacks. The `totalAssets()` function has been overridden to return a **totalDeposited** state variable rather than relying on the contract’s token balance. Additionally, during construction, shares are minted to a dead address to establish an initial share-to-asset ratio, preventing manipulation via direct token transfers.

* **LayerZero Integration Verification.**
The protocol integrates with LayerZero for token bridging. We verified that the integration is correctly implemented. The bridge function properly handles LayerZero messaging fees, checks for sufficient user payment, and ensures the bridging process proceeds with valid and consistent token flow.

* **Token Decimal Conversion Verification.**
We verified that the conversion between different tokens and USDX is correctly implemented. The `_getBridgeAmount()` helper function accurately normalizes token amounts to USDX’s 18-decimal format. This includes proper scaling for tokens like USDC and USDT (6 decimals) and DAI (18 decimals), ensuring 1:1 value consistency across all supported stablecoins. We also assessed the protocol’s resistance to economic attacks in scenarios involving major price deviations of the supported assets.

The codebase is of high quality, and no critical security issues were identified during the audit. Nonetheless, we have highlighted several opportunities for improvement that would strengthen the protocol’s robustness, clarity, and maintainability. These are detailed in the **Findings Report** below.

### 1.3 Project Overview

#### Summary
    
Title | Description
--- | ---
Client Name| Ozean Finance
Project Name| OzUSDV2
Type| Solidity
Platform| EVM
Timeline| 17.06.2025 - 25.06.2025
    
#### Scope of Audit

File | Link
--- | ---
src/L2/OzUSDV2.sol | https://github.com/Ozean-L2/Ozean-Contracts/blob/e8e342ab1a62a94f13b81b00d781e6801d1238a2/src/L2/OzUSDV2.sol
src/L1/USDXBridgeAlt.sol | https://github.com/Ozean-L2/Ozean-Contracts/blob/e8e342ab1a62a94f13b81b00d781e6801d1238a2/src/L1/USDXBridgeAlt.sol
    
#### Versions Log

Date                                      | Commit Hash | Note
-------------------------------------------| --- | ---
17.06.2025 | e8e342ab1a62a94f13b81b00d781e6801d1238a2 | Initial Commit
25.06.2025 | 0b26f627693fae5b68f89fc3b5b436c9b39e128d | Re-audit Commit
    
#### Mainnet Deployments

File| Address | Blockchain
--- | --- | ---
TBA | TBA | TBA
    
### 1.4 Security Assessment Methodology
    
#### Project Flow

| **Stage** | **Scope of Work** |
|-----------|------------------|
| **Interim Audit** | **Project Architecture Review:**<br> - Review project documentation <br> - Conduct a general code review <br> - Perform reverse engineering to analyze the project’s architecture based solely on the source code <br> - Develop an independent perspective on the project’s architecture <br> - Identify any logical flaws in the design <br> **Objective:** Understand the overall structure of the project and identify potential security risks. |
| **Interim Audit** | **Core Review with a Hacker Mindset:**<br> - Each team member independently conducts a manual code review, focusing on identifying unique vulnerabilities. <br> - Perform collaborative audits (pair auditing) of the most complex code sections, supervised by the Team Lead. <br> - Develop Proof-of-Concepts (PoCs) and conduct fuzzing tests using tools like Foundry, Hardhat, and BOA to uncover intricate logical flaws. <br> - Review test cases and in-code comments to identify potential weaknesses. <br> **Objective:** Identify and eliminate the majority of vulnerabilities, including those unique to the industry. |
| **Interim Audit** | **Code Review with a Nerd Mindset:**<br> - Conduct a manual code review using an internally maintained checklist, regularly updated with insights from past hacks, research, and client audits. <br> - Utilize static analysis tools (e.g., Slither, Mythril) and vulnerability databases (e.g., Solodit) to uncover potential undetected attack vectors. <br> **Objective:** Ensure comprehensive coverage of all known attack vectors during the review process. |
| **Interim Audit** | **Consolidation of Auditors' Reports:**<br> - Cross-check findings among auditors <br> - Discuss identified issues <br> - Issue an interim audit report for client review <br> **Objective:** Combine interim reports from all auditors into a single comprehensive document. |
| **Re-Audit** | **Bug Fixing & Re-Audit:**<br> - The client addresses the identified issues and provides feedback. <br> - Auditors verify the fixes and update their statuses with supporting evidence. <br> - A re-audit report is generated and shared with the client. <br> **Objective:** Validate the fixes and reassess the code to ensure all vulnerabilities are resolved and no new vulnerabilities are added. |
| **Final Audit** | **Final Code Verification & Public Audit Report:**<br> - Verify the final code version against recommendations and their statuses. <br> - Check deployed contracts for correct initialization parameters. <br> - Confirm that the deployed code matches the audited version. <br> - Issue a public audit report, published on our official GitHub repository. <br> - Announce the successful audit on our official X account. <br> **Objective:** Perform a final review and issue a public report documenting the audit. |

### 1.5 Risk Classification

#### Severity Level Matrix

| Severity  | Impact: High | Impact: Medium | Impact: Low |
|-----------|-------------|---------------|-------------|
| **Likelihood: High**   | Critical   | High    | Medium  |
| **Likelihood: Medium** | High       | Medium  | Low     |
| **Likelihood: Low**    | Medium     | Low     | Low     |

#### Impact

- **High** – Theft from 0.5% OR partial/full blocking of funds (>0.5%) on the contract without the possibility of withdrawal OR loss of user funds (>1%) who interacted with the protocol.
- **Medium** – Contract lock that can only be fixed through a contract upgrade OR one-time theft of rewards or an amount up to 0.5% of the protocol's TVL OR funds lock with the possibility of withdrawal by an admin.
- **Low** – One-time contract lock that can be fixed by the administrator without a contract upgrade.

#### Likelihood

- **High** – The event has a 50-60% probability of occurring within a year and can be triggered by any actor (e.g., due to a likely market condition that the actor cannot influence).
- **Medium** – An unlikely event (10-20% probability of occurring) that can be triggered by a trusted actor.
- **Low** – A highly unlikely event that can only be triggered by the owner.

#### Action Required

- **Critical** – Must be fixed as soon as possible.
- **High** – Strongly advised to be fixed to minimize potential risks.
- **Medium** – Recommended to be fixed to enhance security and stability.
- **Low** – Recommended to be fixed to improve overall robustness and effectiveness.

#### Finding Status

- **Fixed** – The recommended fixes have been implemented in the project code and no longer impact its security.
- **Partially Fixed** – The recommended fixes have been partially implemented, reducing the impact of the finding, but it has not been fully resolved.
- **Acknowledged** – The recommended fixes have not yet been implemented, and the finding remains unresolved or does not require code changes.

### 1.6 Summary of Findings

#### Findings Count

| Severity  | Count |
|-----------|-------|
| **Critical** | 0 |
| **High**     | 0 |
| **Medium**   | 3 |
| **Low**      | 14 |

## 2. Findings Report

### 2.1 Critical

Not found
    
---

### 2.2 High

Not found

---

### 2.3 Medium

#### 1. `bridge()` Fails When `bridgeAmount` Contains Dust
##### Found by @cartlex
##### Merged by @cartlex
##### Verified by @DmitriZaharov
##### Status
Fixed in https://github.com/Ozean-L2/Ozean-Contracts/commit/0b26f627693fae5b68f89fc3b5b436c9b39e128d

##### Description
The `USDXBridgeAlt.bridge()` function passes the same `bridgeAmount` value for both `amountLD` and `minAmountLD` parameters in the `SendParam` struct. However, the LayerZero OFT implementation applies the `OFTCoreUpgradeable._removeDust()` method to `amountLD` during processing, which removes precision below `decimalConversionRate` (last 12 digits for 18-decimal tokens). This creates a situation where `amountReceivedLD` after dust removal may become less than `minAmountLD`, causing the transaction to revert in the `OFTCoreUpgradeable._debitView()` function.

For example, when bridging `1000000000000000001` wei:
- `amountReceivedLD` becomes `1000000000000000000` (dust removed)
- `minAmountLD` remains `1000000000000000001` (original)
- The slippage check in `_debitView()` will cause a revert: `1000000000000000000 < 1000000000000000001`

Since this scenario can occur frequently when users bridge amounts with non-zero dust, it leads to failed transactions and degraded user experience. For this reason, the issue has been classified as **Medium** severity.

##### Recommendation
We recommend allowing users to specify their own slippage tolerance in the `bridge()` function instead of automatically setting it equal to `bridgeAmount`.

> **Client's Commentary:**
> Fixed. Important finding!

---

#### 2. Missing Pause Checks on User Functions
##### Found by @cartlex
##### Merged by @cartlex
##### Verified by @DmitriZaharov
##### Status
Acknowledged

##### Description
The `OzUSDV2` contract implements inconsistent pause behavior. While `deposit()` and `mint()` functions correctly include the `whenNotPaused` modifier to prevent execution during contract pause, the `withdraw()` and `redeem()` functions do not have this protection.

This issue is classified as **Medium** severity because during an emergency situation users or more dangerously, a malicious attacker can continue to withdraw funds from the protocol.

##### Recommendation
We recommend adding the `whenNotPaused` modifier to all user functions listed above.

> **Client's Commentary:**
> Won’t fix. Standard ERC4626 does not introduce pause and unpause functionality, as it is not a REQUIRED feature. We implemented a pause mechanism specifically for deposit and mint operations, keeping it simple because our intention is to apply pause only to deposit-related actions

---

#### 3. Under-Collateralized Mint When Stablecoin Depegs
##### Found by @neartyom
##### Merged by @cartlex
##### Verified by @DmitriZaharov
##### Status
Acknowledged

##### Description
`USDXBridgeAlt.bridge()` mints USDX on a hard-coded 1:1 basis with the deposited stablecoin. If an allow-listed coin loses its peg (e.g., trades at 0.80 USD), an attacker can buy it cheaply, deposit it, and receive the full USDX amount on L2. The protocol becomes under-collateralized while the attacker pockets the price differential. 

Because only `depositCap` is checked and no oracle price guard exists, the risk compromises economic soundness and user confidence, warranting **Medium** severity.

##### Recommendation
We recommend integrating a trusted USD oracle for every allow-listed stablecoin and reject deposits whose oracle price deviates from 1 USD beyond a configurable threshold.

> **Client's Commentary:**
> Won’t fix. The current design accepts the risk of depegging but mitigates potential damage by enforcing per-token depositCap. This current code was considered an acceptable trade-off between simplicity and risk. It seems easier to explain to customer if the exchange ratio is 1:1.

---

### 2.4 Low

#### 1. `OzUSDV2` View Functions Inconsistent with Pause Logic
##### Found by @cartlex
##### Merged by @cartlex
##### Verified by @DmitriZaharov
##### Status
Fixed in https://github.com/Ozean-L2/Ozean-Contracts/commit/0b26f627693fae5b68f89fc3b5b436c9b39e128d

##### Description
The `OzUSDV2` contract's view functions `maxRedeem()`, `maxWithdraw()`, `maxMint()`, and `maxDeposit()` do not account for the contract's paused state. These functions continue to return non-zero values even when the contract is paused, providing misleading information to users and external integrations about the actual available limits.

##### Recommendation
We recommend returning zero when contract is on pause by overriding these functions to check the paused state before returning the calculated values.

> **Client's Commentary:**
> Fixed

---

#### 2. `lzReceive` Gas Limit Should Be Adjustable
##### Found by @cartlex
##### Merged by @cartlex
##### Verified by @DmitriZaharov
##### Status
Fixed in https://github.com/Ozean-L2/Ozean-Contracts/commit/0b26f627693fae5b68f89fc3b5b436c9b39e128d

##### Description
The `USDXBridgeAlt.bridge()` function uses a hardcoded gas limit of `65000` for LayerZero receive operations on the destination chain.

However, gas costs on destination chains can increase over time due to network upgrades, added complexity, or changes in infrastructure. The current implementation lacks flexibility to adapt to evolving network conditions or optimize gas usage across different chains.

##### Recommendation
We recommend introducing a state variable to store the gas limit, along with an owner-only setter function to allow dynamic adjustment of the gas limit used in `lzReceive` operations.

> **Client's Commentary:**
> Fixed

---

#### 3. Lack of Validation That `_amount` Is Greater Than Zero in `distributeYield()` Function
##### Found by @cartlex
##### Merged by @cartlex
##### Verified by @DmitriZaharov
##### Status
Fixed in https://github.com/Ozean-L2/Ozean-Contracts/commit/0b26f627693fae5b68f89fc3b5b436c9b39e128d

##### Description
The `OzUSDV2.distributeYield()` function does not validate that the `_amount` parameter is greater than zero. Currently, if an admin passes zero tokens to the function, it successfully executes and emits the `YieldDistributed` event without any actual yield distribution occurring. This behavior can be misleading to users and monitoring systems that rely on event logs to track yield distributions, as they may incorrectly assume that yield has been distributed when none actually occurred.

##### Recommendation
We recommend adding a validation check to ensure `_amount` is greater than zero before proceeding with the yield distribution process.

> **Client's Commentary:**
> Fixed

---

#### 4. Misleading Comment To `totalAssets()` Function
##### Found by @cartlex
##### Merged by @cartlex
##### Verified by @DmitriZaharov
##### Status
Fixed in https://github.com/Ozean-L2/Ozean-Contracts/commit/0b26f627693fae5b68f89fc3b5b436c9b39e128d

##### Description
The comment for the `totalAssets()` function contains misleading documentation that states it returns the amount "excluding yield", however the function actually returns `totalDeposited` which includes distributed yield:

```md 
// Returns the total amount of USDX deposited in the vault (excluding yield).
```

The `totalDeposited` variable is increased when `distributeYield()` is called, meaning it includes both user deposits and distributed yield.

##### Recommendation
We recommend correcting the comment to accurately reflect that the function returns the total amount including distributed yield.

> **Client's Commentary:**
> Fixed

---

#### 5. Centralized Privilege Separation
##### Found by @buggzy2
##### Merged by @cartlex
##### Verified by @DmitriZaharov
##### Status
Fixed in https://github.com/Ozean-L2/Ozean-Contracts/commit/0b26f627693fae5b68f89fc3b5b436c9b39e128d

##### Description
A single owner account in the `OzUSDV2` contract holds three critical privileges:
1. Pausing the contract
2. Unpausing the contract
3. Distributing yield

This concentration of power creates a single point of failure—compromise of that one account could allow an attacker to halt all user deposits/withdrawals or manipulate yield distribution in the vault contract.

##### Recommendation
We recommend implementing three distinct roles with tailored security thresholds to minimize risk and ensure that compromise of one role cannot affect the others:
- PAUSER_ROLE – a fast-response role authorized only to pause the contract.
- UNPAUSER_ROLE – authorized only to unpause the contract.
- YIELD_DISTRIBUTOR_ROLE – authorized only to call `distributeYield()` function, suitable for automated bots or a dedicated service account.

> **Client's Commentary:**
> Fixed. Only add YIELD_DISTRIBUTOR_ROLE.

---

#### 6. Unnecessary `totalAssets()` Function Invocation
##### Found by @buggzy2
##### Merged by @cartlex
##### Verified by @DmitriZaharov
##### Status
Fixed in https://github.com/Ozean-L2/Ozean-Contracts/commit/0b26f627693fae5b68f89fc3b5b436c9b39e128d

##### Description
In the `OzUSDV2.distributeYield()` function, the event emission invokes `OzUSDV2.totalAssets()` twice to compute the previous and new balances. Since `totalAssets()` simply returns the `totalDeposited` state variable, and since `_amount` is already known, these calls are redundant.

##### Recommendation
We recommend storing the previous deposited balance in a local variable before updating it, and then emitting the event using that value directly. For example:
```solidity
uint256 previous = totalDeposited;
IERC20Metadata(asset()).safeTransferFrom(msg.sender, address(this), _amount);
totalDeposited += _amount;
emit YieldDistributed(previous, totalDeposited);
```

This simplifies the logic, avoids unnecessary function calls, and clearly illustrates the intended change in balances.

> **Client's Commentary:**
> Fixed

---

#### 7. Suboptimal `_getBridgeAmount()` Function Implementation
##### Found by @buggzy2
##### Merged by @cartlex
##### Verified by @DmitriZaharov
##### Status
Fixed in https://github.com/Ozean-L2/Ozean-Contracts/commit/0b26f627693fae5b68f89fc3b5b436c9b39e128d

##### Description
The internal view function `USDXBridge._getBridgeAmount` currently reads both token decimals and performs two exponentiations per call:
```solidity
uint8 depositDecimals = IERC20Decimals(_stablecoin).decimals();
uint8 usdxDecimals    = l1USDX.decimals();
return (_amount * 10 ** usdxDecimals) / (10 ** depositDecimals);
```
This incurs unnecessary gas costs due to two expensive `10 ** x` operations every time a user initiates a bridge.

##### Recommendation
We recommend optimizing this by performing only one exponentiation per call by comparing decimals and applying a single multiplication or division. For example:

```solidity
function _getBridgeAmount(
    address _stablecoin,
    uint256 _amount
) internal view returns (uint256) {
    uint8 depositDecimals = IERC20Decimals(_stablecoin).decimals();
    uint8 usdxDecimals = l1USDX.decimals();

    if (usdxDecimals == depositDecimals) {
        return _amount;
    } else if (usdxDecimals > depositDecimals) {
        return _amount * (10 ** (usdxDecimals - depositDecimals));
    } else {
        return _amount / (10 ** (depositDecimals - usdxDecimals));
    }
}
```
    
> **Client's Commentary:**
> Fixed

---

#### 8. Inconsistent `depositCap` Decimal Units
##### Found by @buggzy2
##### Merged by @cartlex
##### Verified by @DmitriZaharov
##### Status
Fixed in https://github.com/Ozean-L2/Ozean-Contracts/commit/0b26f627693fae5b68f89fc3b5b436c9b39e128d

##### Description
The `depositCap` mapping currently stores and compares limits in USDX’s **18-decimal** units rather than the native decimals of the deposited asset. This is counterintuitive given the parameter name `depositCap` suggests a cap on the number of tokens deposited. For example, USDC uses **6** decimals. If the owner sets:

```solidity
depositCap[USDC] = 1e6; // they expect to cap at 1 USDC
```
The contract will interpret that as 1 000 000 USDX units (i.e. 0.000001 USDX), effectively disallowing any USDC deposits.

##### Recommendation
We recommend storing  and enforcing `depositCap` in the deposited asset’s decimals.

> **Client's Commentary:**
> Fixed

---

#### 9. Missing Explicit Pause Mechanism
##### Found by @buggzy2
##### Merged by @cartlex
##### Verified by @DmitriZaharov
##### Status
Acknowledged

##### Description
Currently, halting all bridge operations requires individually un-allowlisting every token in the `allowlisted` mapping. This pattern is error-prone, unintuitive, and lacks a clear “emergency stop” for the entire contract.

##### Recommendation
We recommend integrating OpenZeppelin’s `Pausable` (or a simple `bool paused` flag) into the contract:
- Add `pause()` and `unpause()` functions, restricted to `onlyOwner` or to dedicated PAUSER/UNPAUSER roles.
- Apply the `whenNotPaused` modifier (or `require(!paused)`) to the `bridge` function.
- Emit `Paused` and `Unpaused` events in the respective functions for on-chain transparency.

> **Client's Commentary:**
> Won’t fix. The absence does not cause harm as we accept 1 stablecoin only, which is USDC.

---

#### 10. Yield Distribution Front-running via Deposits
##### Found by @cartlex, @neartyom
##### Merged by @cartlex
##### Verified by @DmitriZaharov
##### Status
Acknowledged

##### Description
The `OzUSDV2` contract is vulnerable to a front-running attack on yield distribution. An attacker can monitor pending `distributeYield` transactions and deposit a large amount immediately before the yield is distributed.

The root cause is that yield distribution immediately increases `totalDeposited`, proportionally raising the value of all shares, without considering how long users have held their shares. As a result, new deposits made just before distribution receive the same share of yield as long-term holders, enabling attackers to capture disproportionate profits.

For example:
1. Alice deposits 5,000 USDX and remains in the pool for a long period.
2. Bob deposits 100,000 USDX just before a 100,000 USDX yield distribution.
3. Bob can withdraw about 195,237 USDX (a ~95% profit), while Alice receives only about 9,762 USDX.

As the contract is planned for deployment on an L2 with a centralized sequencer—where front-running is less feasible—the severity is classified as **Low**.

##### Recommendation
We recommend implementing linear yield distribution over time to prevent front-running of the `distributeYield()` function.

Instead of applying the entire yield instantly, each distribution event should define an accrual window with the following parameters:
- startTime: the timestamp when the yield distribution is initiated,
- endTime: a future timestamp when the distribution ends (e.g., startTime + 1 day),
- startTotalAssets: the total assets in the vault before yield distribution,
- endTotalAssets: the total assets after adding the yield.

During this interval, the vault's `totalAssets()` should grow linearly from `startTotalAssets` to `endTotalAssets`, proportional to the elapsed time. This ensures that the share value increases gradually rather than instantaneously, making it ineffective for attackers to capture disproportionate rewards by depositing just before yield is distributed.

> **Client's Commentary:**
> Won’t fix. Frontrunning is acceptable in this case as it does not harm the protocol

---

#### 11. Duplicate `MessagingFee` Import Name Causes Compilation Ambiguity
##### Found by @neartyom, @buggzy2
##### Merged by @cartlex
##### Verified by @DmitriZaharov
##### Status
Fixed in https://github.com/Ozean-L2/Ozean-Contracts/commit/0b26f627693fae5b68f89fc3b5b436c9b39e128d

##### Description
`USDXBridgeAlt` contract imports `MessagingFee` from two different LayerZero paths without aliasing. The identical identifier can lead to silent type collisions or failed builds when upstream libraries change.

##### Recommendation
We recommend removing the redundant import or aliasing one of them.

> **Client's Commentary:**
> Fixed

---

#### 12. Missing `bridgeAmount > 0` Validation Can Burn Deposits
##### Found by @neartyom
##### Merged by @cartlex
##### Verified by @DmitriZaharov
##### Status
Fixed in https://github.com/Ozean-L2/Ozean-Contracts/commit/0b26f627693fae5b68f89fc3b5b436c9b39e128d

##### Description
Although `_amount > 0` is enforced, `USDXBridgeAlt.bridge()` does not ensure that the calculated `bridgeAmount` is positive. Small deposits of high-decimals tokens can round down to zero, transferring the user’s stablecoins while minting no USDX.

##### Recommendation
We recommend adding a check for `bridgeAmount > 0` immediately after computing it.

> **Client's Commentary:**
> Fixed

---

#### 13. State Update After External Call Enables Hypothetical Re-entrancy
##### Found by @neartyom
##### Merged by @cartlex
##### Verified by @DmitriZaharov
##### Status
Fixed in https://github.com/Ozean-L2/Ozean-Contracts/commit/0b26f627693fae5b68f89fc3b5b436c9b39e128d

##### Description
In `OzUSDV2._withdraw()` the contract reduces `totalDeposited` **after** calling `super._withdraw()`, which performs an external token transfer. If USDX were ever upgraded to an ERC-777–style token with hooks, an attacker could re-enter before the state update and withdraw more than their fair share. The threat is currently theoretical but becomes real if a callback-capable asset is registered.

##### Recommendation
We recommend following the checks-effects-interactions pattern by moving `totalDeposited -= _assets;` to before the external call, or use a re-entrancy guard to `withdraw` and `redeem` functions.

> **Client's Commentary:**
> Fixed

---

#### 14. Generic `require` Strings Instead of Custom Errors
##### Found by @neartyom
##### Merged by @cartlex
##### Verified by @DmitriZaharov
##### Status
Fixed in https://github.com/Ozean-L2/Ozean-Contracts/commit/0b26f627693fae5b68f89fc3b5b436c9b39e128d

##### Description
`USDXBridgeAlt` and `OzUSDV2` employ string-based `require` reverts. Since Solidity 0.8.24, require statement supports custom errors, which are cheaper and produce smaller bytecode, directly benefiting users.

##### Recommendation
We recommend replacing strings with typed errors.

> **Client's Commentary:**
> Client: Fixed.
> MixBytes: Custom errors have been implemented, but they are currently used with `if` statements. Although the current compiler version supports `require(success, CustomError())`, this form has not been used yet.

---

## 3.About MixBytes
    
MixBytes is a leading provider of smart contract audit and research services, helping blockchain projects enhance security and reliability. Since its inception, MixBytes has been committed to safeguarding the Web3 ecosystem by delivering rigorous security assessments and cutting-edge research tailored to DeFi projects.
    
Our team comprises highly skilled engineers, security experts, and blockchain researchers with deep expertise in formal verification, smart contract auditing, and protocol research. With proven experience in Web3, MixBytes combines in-depth technical knowledge with a proactive security-first approach.
    
#### Why MixBytes?
    
- **Proven Track Record:** Trusted by top-tier blockchain projects like Lido, Aave, Curve, and others, MixBytes has successfully audited and secured billions in digital assets.
- **Technical Expertise:** Our auditors and researchers hold advanced degrees in cryptography, cybersecurity, and distributed systems.
- **Innovative Research:** Our team actively contributes to blockchain security research, sharing knowledge with the community.
    
#### Our Services
- **Smart Contract Audits:** A meticulous security assessment of DeFi protocols to prevent vulnerabilities before deployment.
- **Blockchain Research:** In-depth technical research and security modeling for Web3 projects.
- **Custom Security Solutions:** Tailored security frameworks for complex decentralized applications and blockchain ecosystems.
    
MixBytes is dedicated to securing the future of blockchain technology by delivering unparalleled security expertise and research-driven solutions. Whether you are launching a DeFi protocol or developing an innovative dApp, we are your trusted security partner.


### Contact Information

- [**Website**](https://mixbytes.io/)  
- [**GitHub**](https://github.com/mixbytes/audits_public)  
- [**X**](https://x.com/MixBytes)  
- **Mail:** [hello@mixbytes.io](mailto:hello@mixbytes.io)  