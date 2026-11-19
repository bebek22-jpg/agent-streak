// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/AgentStreak.sol";

contract DeployAgentStreak is Script {
    function run() external returns (AgentStreak) {
        vm.startBroadcast();
        AgentStreak streak = new AgentStreak();
        vm.stopBroadcast();
        console.log("AgentStreak deployed at:", address(streak));
        return streak;
    }
}
