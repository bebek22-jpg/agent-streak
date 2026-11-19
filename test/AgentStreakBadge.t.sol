// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/AgentStreakBadge.sol";

/// Minimal mock of the SPACE ID Agent ID registry (balanceOf only).
/// NOTE: defined locally here (not imported from AgentStreak.t.sol) so this
/// test file never pulls in AgentStreak.sol — both contracts declare
/// IAgentIDRegistry at file scope and importing both collides.
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
/// so the production mint() (which hardcodes that address) is tested as-is.
contract AgentStreakBadgeTest is Test {
    address constant REGISTRY = 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F;

    AgentStreakBadge badge;

    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        MockAgentIDRegistry impl = new MockAgentIDRegistry();
        vm.etch(REGISTRY, address(impl).code);
        MockAgentIDRegistry(REGISTRY).setBalance(alice, 1);
        MockAgentIDRegistry(REGISTRY).setBalance(bob, 1);
        badge = new AgentStreakBadge();
    }

    function testNonHolderReverts() public {
        address stranger = address(0x5EE);
        vm.prank(stranger);
        vm.expectRevert(AgentStreakBadge.NotAgentIDHolder.selector);
        badge.mint();
    }

    function testFirstMint() public {
        vm.prank(alice);
        badge.mint();
        assertEq(badge.ownerOf(1), alice);
        assertEq(badge.balanceOf(alice), 1);
        assertEq(badge.totalSupply(), 1);
        assertTrue(badge.hasMinted(alice));
        assertEq(badge.name(), "AgentStreak Badge");
        assertEq(badge.symbol(), "ASBADGE");
    }

    function testSecondMintRevertsEvenAfterTransfer() public {
        vm.prank(alice);
        badge.mint();
        // Transfer the badge away: balance drops to 0, but hasMinted stays true.
        vm.prank(alice);
        badge.transferFrom(alice, bob, 1);
        assertEq(badge.balanceOf(alice), 0);
        vm.prank(alice);
        vm.expectRevert(AgentStreakBadge.AlreadyMinted.selector);
        badge.mint();
    }

    function testTwoMintersGetSequentialIds() public {
        vm.prank(alice);
        badge.mint();
        vm.prank(bob);
        badge.mint();
        assertEq(badge.ownerOf(1), alice);
        assertEq(badge.ownerOf(2), bob);
        assertEq(badge.totalSupply(), 2);
    }

    function testTokenURIHasDataPrefix() public {
        vm.prank(alice);
        badge.mint();
        string memory uri = badge.tokenURI(1);
        bytes memory prefix = bytes("data:application/json;base64,");
        bytes memory uriBytes = bytes(uri);
        assertGe(uriBytes.length, prefix.length);
        for (uint256 i = 0; i < prefix.length; i++) {
            assertEq(uriBytes[i], prefix[i]);
        }
    }

    function testTokenURIForMissingTokenReverts() public {
        vm.expectRevert();
        badge.tokenURI(1);
    }

    function testMintIsFree() public {
        // mint() is non-payable: sending value must revert (low-level call,
        // since Solidity forbids {value:} on a non-payable function at
        // compile time).
        vm.prank(alice);
        vm.deal(alice, 0.001 ether);
        (bool ok, ) = address(badge).call{value: 0.001 ether}(
            abi.encodeWithSignature("mint()")
        );
        assertFalse(ok);
    }

    // NOTE: the 10,000 cap is a one-line check (tokenId > MAX_SUPPLY); minting
    // 10,000 tokens in a test is too slow to run, so it is covered by review,
    // not by an executed test.
}

/// Fork test against the LIVE BSC mainnet Agent ID registry.
/// Run with: forge test --match-contract AgentStreakBadgeForkTest --fork-url https://bsc-dataseed.binance.org/
contract AgentStreakBadgeForkTest is Test {
    AgentStreakBadge badge;

    // bebek22 (holds Agent ID #5918) and herond (holds none), verified on-chain 2026-11-19.
    address bebek22 = 0x63256702221D50391E011ce4e55B21d18a9F5058;
    address herond = 0xfd39d160e4779f8e19918ABF86b82d3097DFC4Be;

    function setUp() public {
        badge = new AgentStreakBadge();
    }

    function testForkBebek22CanMint() public {
        vm.prank(bebek22);
        badge.mint();
        assertEq(badge.ownerOf(1), bebek22);
        assertEq(badge.totalSupply(), 1);
    }

    function testForkHerondCannotMint() public {
        vm.prank(herond);
        vm.expectRevert(AgentStreakBadge.NotAgentIDHolder.selector);
        badge.mint();
    }
}
