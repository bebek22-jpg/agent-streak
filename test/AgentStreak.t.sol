// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/AgentStreak.sol";

/// Minimal mock of the SPACE ID Agent ID registry (balanceOf only).
contract MockAgentIDRegistry {
    mapping(address => uint256) public balances;

    function setBalance(address owner, uint256 amount) external {
        balances[owner] = amount;
    }

    function balanceOf(address owner) external view returns (uint256) {
        return balances[owner];
    }
}

/// Unit tests: the mock registry's code is etched at the REAL registry address,
/// so the production checkIn() (which hardcodes that address) is tested as-is.
contract AgentStreakTest is Test {
    address constant REGISTRY = 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F;

    AgentStreak streak;

    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        // Realistic mainnet timestamp so currentDay() is far from day 0.
        vm.warp(1_760_000_000);
        MockAgentIDRegistry impl = new MockAgentIDRegistry();
        vm.etch(REGISTRY, address(impl).code);
        MockAgentIDRegistry(REGISTRY).setBalance(alice, 1);
        MockAgentIDRegistry(REGISTRY).setBalance(bob, 1);
        streak = new AgentStreak();
    }

    function testNonHolderReverts() public {
        address stranger = address(0x5EE);
        vm.prank(stranger);
        vm.expectRevert(AgentStreak.NotAgentIDHolder.selector);
        streak.checkIn();
    }

    function testFirstCheckIn() public {
        vm.prank(alice);
        streak.checkIn();
        (uint64 lastDay, uint32 cur, uint32 best, uint32 total) = streak.streaks(alice);
        assertEq(cur, 1);
        assertEq(best, 1);
        assertEq(total, 1);
        assertEq(lastDay, streak.currentDay());
        assertEq(streak.totalCheckIns(), 1);
        assertEq(streak.totalAgents(), 1);
        assertTrue(streak.hasCheckedInToday(alice));
    }

    function testDoubleCheckInSameDayReverts() public {
        vm.prank(alice);
        streak.checkIn();
        vm.prank(alice);
        vm.expectRevert(AgentStreak.AlreadyCheckedInToday.selector);
        streak.checkIn();
    }

    function testConsecutiveDaysGrowStreak() public {
        vm.prank(alice);
        streak.checkIn();
        vm.warp(vm.getBlockTimestamp() + 1 days);
        vm.prank(alice);
        streak.checkIn();
        (, uint32 cur, uint32 best, uint32 total) = streak.streaks(alice);
        assertEq(cur, 2);
        assertEq(best, 2);
        assertEq(total, 2);
    }

    function testMissedDayResetsStreakKeepsBest() public {
        vm.prank(alice);
        streak.checkIn();
        vm.warp(vm.getBlockTimestamp() + 1 days);
        vm.prank(alice);
        streak.checkIn();
        vm.warp(vm.getBlockTimestamp() + 2 days); // skip a day
        vm.prank(alice);
        streak.checkIn();
        (, uint32 cur, uint32 best, uint32 total) = streak.streaks(alice);
        assertEq(cur, 1);
        assertEq(best, 2);
        assertEq(total, 3);
    }

    function testTwoAgents() public {
        vm.prank(alice);
        streak.checkIn();
        vm.prank(bob);
        streak.checkIn();
        assertEq(streak.totalAgents(), 2);
        assertEq(streak.totalCheckIns(), 2);
    }

    function testHasCheckedInTodayFalseBeforeCheckIn() public {
        assertFalse(streak.hasCheckedInToday(alice));
    }

    function testCheckedInEvent() public {
        vm.expectEmit(true, true, false, true, address(streak));
        emit AgentStreak.CheckedIn(alice, streak.currentDay(), 1, 1);
        vm.prank(alice);
        streak.checkIn();
    }
}

/// Fork test against the LIVE BSC mainnet Agent ID registry.
/// Run with: forge test --match-contract AgentStreakForkTest --fork-url https://bsc-dataseed.binance.org/
contract AgentStreakForkTest is Test {
    AgentStreak streak;

    // bebek22 (holds Agent ID #5918) and herond (holds none), verified on-chain 2026-11-19.
    address bebek22 = 0x63256702221D50391E011ce4e55B21d18a9F5058;
    address herond = 0xfd39d160e4779f8e19918ABF86b82d3097DFC4Be;

    function setUp() public {
        streak = new AgentStreak();
    }

    function testForkBebek22CanCheckIn() public {
        vm.prank(bebek22);
        streak.checkIn();
        (, uint32 cur, uint32 best, uint32 total) = streak.streaks(bebek22);
        assertEq(cur, 1);
        assertEq(best, 1);
        assertEq(total, 1);
        assertEq(streak.totalAgents(), 1);
    }

    function testForkHerondCannotCheckIn() public {
        vm.prank(herond);
        vm.expectRevert(AgentStreak.NotAgentIDHolder.selector);
        streak.checkIn();
    }
}
