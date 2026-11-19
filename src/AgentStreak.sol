// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title AgentStreak
/// @notice Free daily check-in for Binance Agent ID holders on BNB Chain.
/// @dev No owner, no fees, no token, no admin functions. The only gate is
///      holding an Agent ID (SPACE ID Agent ID registry, ERC-721, non-transferable).
///      One check-in per UTC day per address. Streaks count consecutive UTC days.
///      Built for the Binance Agent ID Hackathon (Nov–Dec 2026).
interface IAgentIDRegistry {
    function balanceOf(address owner) external view returns (uint256);
}

contract AgentStreak {
    IAgentIDRegistry public constant AGENT_ID =
        IAgentIDRegistry(0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F);

    struct Streak {
        uint64 lastDay;
        uint32 currentStreak;
        uint32 bestStreak;
        uint32 totalCheckIns;
    }

    mapping(address => Streak) public streaks;
    uint256 public totalCheckIns;
    uint256 public totalAgents;

    event CheckedIn(address indexed agent, uint64 indexed day, uint32 streak, uint32 total);

    error NotAgentIDHolder();
    error AlreadyCheckedInToday();

    /// @notice Current UTC day number (days since Unix epoch).
    function currentDay() public view returns (uint64) {
        return uint64(block.timestamp / 1 days);
    }

    /// @notice Check in for today. Requires holding an Agent ID. Gas only, no fee.
    function checkIn() external {
        if (AGENT_ID.balanceOf(msg.sender) == 0) revert NotAgentIDHolder();
        uint64 today = currentDay();
        Streak storage s = streaks[msg.sender];
        // totalCheckIns > 0 distinguishes "never checked in" (lastDay == 0)
        // from "checked in on day 0".
        if (s.totalCheckIns > 0 && s.lastDay == today) revert AlreadyCheckedInToday();

        if (s.totalCheckIns > 0 && s.lastDay == today - 1) {
            s.currentStreak += 1;
        } else {
            s.currentStreak = 1;
        }
        if (s.currentStreak > s.bestStreak) s.bestStreak = s.currentStreak;
        s.totalCheckIns += 1;
        s.lastDay = today;
        if (s.totalCheckIns == 1) totalAgents += 1;
        totalCheckIns += 1;

        emit CheckedIn(msg.sender, today, s.currentStreak, s.totalCheckIns);
    }

    /// @notice True if `agent` already checked in today.
    function hasCheckedInToday(address agent) external view returns (bool) {
        Streak storage s = streaks[agent];
        return s.totalCheckIns > 0 && s.lastDay == currentDay();
    }
}
