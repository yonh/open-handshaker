# HandShaker Open

An open-source reimplementation of Smartisan HandShaker (锤子 HandShaker) — the
discontinued phone↔desktop file/media management tool — built with Flutter.

- **Host (desktop manager):** macOS first, Windows/Linux planned
- **Agent (phone companion):** Android; iOS planned (network channel only)
- **Protocol:** reverse-engineered SSP (Smartisan Sync Protocol) — see
  [`docs/PROTOCOL.md`](docs/PROTOCOL.md) for the full wire spec, recovered
  protobuf schema, and verifiable Dart codec examples

## Repository layout

```
lib/ssp/     # pure-Dart protocol layer (framing, RSA-signed envelope, handshake)
lib/host/    # desktop manager app
lib/agent/   # Android companion (SSP server :10086 + HTTP file server :19999)
docs/        # reverse-engineering notes and design docs
```

## Status

Early stage. Protocol reverse engineering is complete and documented
(`docs/PROTOCOL.md`, `docs/HTTP_API.md`,
`docs/SmartSyncProtocol.recovered.proto`); implementation is in progress.
See `docs/DESIGN.md` for architecture and roadmap.

## Legal / provenance

This project was produced by clean-room-style analysis of the publicly
distributed HandShaker binaries for interoperability research. No original
Smartisan binaries, resources, or code are distributed in this repository.

## License

MIT — see [LICENSE](LICENSE).
