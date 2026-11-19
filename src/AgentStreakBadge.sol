// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title AgentStreakBadge
/// @notice Free founding badge NFT for Binance Agent ID holders on BNB Chain.
/// @dev No owner, no fees, no admin functions, no payment accepted. One mint
///      per Agent ID address, ever (tracked by address, not by current balance,
///      so transferring the badge away does not unlock a second mint).
///      Fully on-chain metadata: the SVG artwork and JSON are generated in
///      tokenURI, so the badge needs no IPFS or external host.
///      Companion contract to AgentStreak (free daily check-in). Both are
///      submitted to the Binance Agent ID Hackathon (Nov-Dec 2026).
interface IAgentIDRegistry {
    function balanceOf(address owner) external view returns (uint256);
}

contract AgentStreakBadge is ERC721 {
    using Strings for uint256;

    IAgentIDRegistry public constant AGENT_ID =
        IAgentIDRegistry(0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F);

    uint256 public constant MAX_SUPPLY = 10_000;

    /// @notice Total badges minted so far. Only grows (there is no burn).
    uint256 public totalSupply;

    /// @notice True once an address has minted, forever.
    mapping(address => bool) public hasMinted;

    uint256 private _nextTokenId = 1;

    error NotAgentIDHolder();
    error AlreadyMinted();
    error SoldOut();

    constructor() ERC721("AgentStreak Badge", "ASBADGE") {}

    /// @notice Mint one free badge. Requires holding an Agent ID. Gas only.
    function mint() external {
        if (AGENT_ID.balanceOf(msg.sender) == 0) revert NotAgentIDHolder();
        if (hasMinted[msg.sender]) revert AlreadyMinted();
        uint256 tokenId = _nextTokenId;
        if (tokenId > MAX_SUPPLY) revert SoldOut();
        _nextTokenId = tokenId + 1;
        totalSupply += 1;
        hasMinted[msg.sender] = true;
        _safeMint(msg.sender, tokenId);
    }

    /// @notice Fully on-chain metadata: base64 JSON with an embedded SVG badge.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        string memory id = tokenId.toString();
        string memory svg = string(
            abi.encodePacked(
                "<svg xmlns='http://www.w3.org/2000/svg' width='512' height='512' viewBox='0 0 512 512'>",
                "<rect width='512' height='512' rx='64' fill='#0b0e11'/>",
                "<circle cx='256' cy='205' r='110' fill='none' stroke='#f0b90b' stroke-width='10'/>",
                "<path d='M206 207 l34 34 l74 -78' fill='none' stroke='#f0b90b' stroke-width='16' stroke-linecap='round' stroke-linejoin='round'/>",
                "<text x='256' y='362' font-family='Arial, sans-serif' font-size='34' font-weight='bold' fill='#f0b90b' text-anchor='middle'>AGENTSTREAK</text>",
                "<text x='256' y='402' font-family='Arial, sans-serif' font-size='20' fill='#eaecef' text-anchor='middle'>FOUNDING BADGE</text>",
                "<text x='256' y='448' font-family='Arial, sans-serif' font-size='20' fill='#848e9c' text-anchor='middle'>#",
                id,
                "</text></svg>"
            )
        );
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name":"AgentStreak Badge #',
                        id,
                        '","description":"Founding badge for Agent ID holders who joined AgentStreak, the free daily check-in dApp built for the Binance Agent ID Hackathon. One per Agent ID, free forever. Fully on-chain.",',
                        '"image":"data:image/svg+xml;base64,',
                        Base64.encode(bytes(svg)),
                        '","attributes":[{"trait_type":"Badge","value":"Founding"},{"trait_type":"Mint #","value":',
                        id,
                        '}]}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}
