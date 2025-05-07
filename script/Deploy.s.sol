// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {GameAirdrop} from "../src/GameAirdrop.sol";
import {GameAirdropSigned} from "../src/GameAirdropSigned.sol";

contract DeployScript is Script {
    // Constants for deployment
    uint256 public constant INITIAL_ETH_ENTRY_FEE = 0.0001 ether;
    uint256 public constant INITIAL_USDC_ENTRY_FEE = 0.1e6; // 0.10 USDC
    uint256 public constant ETH_PAYOUT = 0.0001 ether;
    uint256 public constant USDC_PAYOUT = 1e6; // 1 USDC

    // USDC addresses
    address public constant BASE_USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; // Base Mainnet
    address public constant BASE_SEPOLIA_USDC = 0x036CbD53842c5426634e7929541eC2318f3dCF7e; // Base Sepolia

    function run() public returns (GameAirdrop, GameAirdropSigned) {
        // Get deployment parameters from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        bool isMainnet = vm.envBool("IS_MAINNET");
        
        // Select network and USDC address based on environment
        string memory rpcUrl = isMainnet ? vm.envString("BASE_RPC_URL") : vm.envString("BASE_SEPOLIA_RPC_URL");
        address usdcAddress = isMainnet ? BASE_USDC : BASE_SEPOLIA_USDC;

        console2.log("Deploying to:", isMainnet ? "Base Mainnet" : "Base Sepolia");
        console2.log("Using USDC address:", usdcAddress);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy GameAirdrop
        GameAirdrop gameAirdrop = new GameAirdrop(
            INITIAL_ETH_ENTRY_FEE,
            INITIAL_USDC_ENTRY_FEE,
            usdcAddress,
            ETH_PAYOUT,
            USDC_PAYOUT
        );

        // Deploy GameAirdropSigned
        GameAirdropSigned gameAirdropSigned = new GameAirdropSigned(
            INITIAL_ETH_ENTRY_FEE,
            INITIAL_USDC_ENTRY_FEE,
            usdcAddress,
            ETH_PAYOUT,
            USDC_PAYOUT
        );

        vm.stopBroadcast();

        // Log deployment addresses
        console2.log("GameAirdrop deployed to:", address(gameAirdrop));
        console2.log("GameAirdropSigned deployed to:", address(gameAirdropSigned));

        return (gameAirdrop, gameAirdropSigned);
    }
} 