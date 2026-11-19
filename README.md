# AgentStreak

A free daily check-in for **Agent ID** holders on BNB Chain. One check-in per day, gas only. Build your streak, prove you're active. Plus a free **Founding Badge** NFT — one per Agent ID, fully on-chain artwork.

Built for the [Binance Agent ID Hackathon](https://www.binance.com/en/support/announcement/detail/95f5dbe0ea674a48a739b59e046648bf) (submission period 18 Nov – 9 Dec 2026).

**Live site:** https://bebek22-jpg.github.io/agent-streak/
**Check-in contract (BNB Chain):** [`0x8eCd85A1d5ED398183699B8C07EE42C344046019`](https://bscscan.com/address/0x8eCd85A1d5ED398183699B8C07EE42C344046019) — verified on BscScan + Sourcify (exact match)
**Badge contract (BNB Chain):** [`0xC34c1eA7b3a0bea3AE9e473e645D172900e63748`](https://bscscan.com/address/0xC34c1eA7b3a0bea3AE9e473e645D172900e63748) — verified on Sourcify (exact match)

## How it works

- `checkIn()` — callable once per UTC day by any address holding an Agent ID (checked via `balanceOf` on the SPACE ID Agent ID registry, `0x60B9262456de011f7d15a54cdd8c48baaa8b022f`). Tracks current streak, best streak, and total check-ins. Emits `CheckedIn(agent, day, streak, total)`.
- Views: `streaks(address)`, `totalCheckIns`, `totalAgents`, `currentDay()`, `hasCheckedInToday(address)`.
- `mint()` (AgentStreakBadge) — mints one free Founding Badge NFT per Agent ID address, ever (tracked by address, so transferring the badge away does not unlock a second mint). Cap 10,000. Fully on-chain metadata: the SVG artwork is generated in `tokenURI`, no IPFS or external host. Views: `totalSupply`, `hasMinted(address)`, `MAX_SUPPLY`.

## Design principles

- **No owner, no fees, no token, no admin functions.** There is nothing privileged to disclose — the contract cannot move funds, pause, or change rules.
- **Free to use** — check-ins and badge mints cost only BNB gas (~0.000006–0.000007 BNB at 0.05 gwei).
- **Agent ID is the gate** — only Agent ID holders can check in, so every interaction on the contract is a verified agent.

## Development

Requires [Foundry](https://book.getfoundry.sh/).

```bash
forge build
forge test                                  # unit tests (mock registry etched at the real address)
forge test --match-contract 'AgentStreakForkTest|AgentStreakBadgeForkTest' --fork-url https://bsc-dataseed.binance.org/   # fork tests vs the live registry
```

Deploy (BSC mainnet):

```bash
forge script script/Deploy.s.sol --rpc-url https://bsc-dataseed.binance.org/ --broadcast
forge script script/DeployBadge.s.sol --rpc-url https://bsc-dataseed.binance.org/ --broadcast
```

Verify on Sourcify:

```bash
forge verify-contract --verifier sourcify --chain-id 56 <address> src/AgentStreak.sol:AgentStreak
forge verify-contract --verifier sourcify --chain-id 56 <address> src/AgentStreakBadge.sol:AgentStreakBadge
```

## License

MIT. This project is not affiliated with Binance.
