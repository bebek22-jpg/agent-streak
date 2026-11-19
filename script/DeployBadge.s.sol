// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/AgentStreakBadge.sol";

contract DeployAgentStreakBadge is Script {
    function run() external returns (AgentStreakBadge) {
        vm.startBroadcast();
        AgentStreakBadge badge = new AgentStreakBadge();
        vm.stopBroadcast();
        console.log("AgentStreakBadge deployed at:", address(badge));
        return badge;
    }
}
