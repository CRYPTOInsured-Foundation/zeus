++ Begin Content
# Zeus Contracts

> Cairo / Starknet smart contracts and deployment helpers for the Zeus protocol.

This package contains the Cairo contracts, ABI artifacts, and helper scripts used by the Zeus backend and apps.

## Quick summary
- Contracts are authored for Cairo (Starknet) and managed with `Scarb` + `snforge`/`starknet-foundry` compatibility.
- Build artifacts are generated under `target/` and ABIs are available in `abis/`.
- Deployment helpers exist in `scripts/deploy.py` (calls `starkli` to declare & deploy contract classes).

## Prerequisites
- Scarb (https://docs.swmansion.com/scarb/) — package manager for Cairo projects.
- Python 3.10+ (for `scripts/deploy.py` and helper tooling).
- `starkli` / Starknet CLI or Foundry-compatible tooling for declare/deploy operations.
- (Optional) Docker if you want to run a local devnet or isolated toolchain.

Notes: `Scarb.toml` is configured to allow prebuilt plugins (`snforge_std`) so installing Rust is optional for some workflows.

## Common commands

From the `zeus_contracts` directory:

```bash
# install scarb (see scarb docs for platform-specific instructions)
# build contract classes and artifacts
scarb build

# build specific target (if needed)
scarb build --target starknet-contract

# run the deploy helper (interactive)
python3 scripts/deploy.py
```

For advanced testing using Starknet Foundry (`snfoundry`), consult `snfoundry.toml` and the Foundry docs.

## Project structure

```
zeus_contracts/
├─ Scarb.toml
├─ snfoundry.toml
├─ Scarb.lock
├─ scripts/
│  └─ deploy.py
├─ abis/                # generated contract ABIs
├─ src/
│  ├─ lib.cairo         # shared Cairo library helpers
│  ├─ constants/
│  ├─ contracts/
│  │  ├─ bridges/       # bridge contracts (Starknet-side)
│  │  ├─ core/          # core protocol contracts
│  │  ├─ mock/          # mocks for testing
│  │  └─ tokens/        # token contracts / test tokens
│  ├─ enums/
│  ├─ errors/
│  ├─ event_structs/
│  ├─ interfaces/
│  ├─ libraries/
│  ├─ structs/
│  └─ utils/
├─ target/              # build artifacts (generated)
└─ .tool-versions
```

## Recommended workflow
1. Ensure `scarb` is installed and available on your PATH.
2. Run `scarb build` to compile contracts and populate `target/` and `abis/`.
3. Use `scripts/deploy.py` to declare and deploy contract classes to your chosen network (it will call `starkli`).
4. Update backend `zeus_service` configuration with deployed contract addresses and ABIs if needed.

## Notes for developers
- `Scarb.toml` includes dependency pins for OpenZeppelin Cairo libs and `snforge_std` — consult the file when updating or adding dependencies.
- The repo includes `snfoundry.toml` for optional Foundry-style config when using `starknet-foundry` tooling.
- ABI JSONs are kept in `abis/` for consumption by `zeus_service` and client tooling.

If you'd like, I can also add example `scarb` and `snforge` install commands for Linux/macOS and a small CI job snippet to compile contracts on push.
