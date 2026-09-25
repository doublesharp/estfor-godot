# Estfor Godot

GDScript bindings for the [Estfor Kingdom smart contracts](https://github.com/PaintSwap/estfor-contracts), generated with [abi-typegen](https://github.com/doublesharp/abi-typegen).

Use the bindings to encode contract calls, decode results, events, and errors, and make asynchronous JSON-RPC requests from Godot. Contracts include Players, PlayerNFT, ItemNFT, PetNFT, Clans, Shop, Quests, and WorldActions. See [`manifest.json`](manifest.json) for the complete contract list, source revision, generator version, and file hashes.

## Getting started

The included native extension supports development with Godot 4.7.2 on macOS with Apple Silicon.

```sh
git clone https://github.com/doublesharp/estfor-godot.git
cd estfor-godot
```

Import `project.godot` in Godot. For an existing project, copy `generated/` and `bin/` into its root. Keep the extension descriptor and the `bin/macos/` directory together.

The bundled extension is a locally built macOS arm64 debug binary. Release exports and other platforms require an appropriate extension build. See the [upstream Godot integration](https://github.com/doublesharp/abi-typegen/tree/v0.6.0/integrations/godot/extension) for build requirements. Use the version recorded in the manifest when building the runtime for these bindings.

## Read a contract

Attach a script like this to a node in your scene. Pass the RPC URL, deployed PlayerNFT address, and account address for the network you intend to use.

```gdscript
extends Node

const PlayerNFT = preload("res://generated/player_nft.gd")

var client: AbiTypegenClient

func _ready() -> void:
    client = AbiTypegenClient.new()
    add_child(client)

func read_balance(rpc_url: String, contract_address: String, account: String) -> Dictionary:
    client.rpc_url = rpc_url
    var player_id := AbiTypegenCodec.word_from_u64(1)
    var request = PlayerNFT.call_balance_of(client, contract_address, account, player_id)
    var result: Dictionary = await request.finished
    if not result.get("ok", false):
        push_error(str(result.get("error")))
    return result
```

Call `read_balance` after `_ready` and await its result. A successful result contains the balance in `result["value"]` as a 32-byte ABI word.

| Solidity value | GDScript representation |
| --- | --- |
| Address | Hex `String` with a `0x` prefix |
| Integer | 32-byte big-endian `PackedByteArray` |
| Bytes | `PackedByteArray` |
| Boolean | `bool` |
| String | `String` |
| Array | `Array` |
| Tuple | `Dictionary` keyed by generated field names |

Keep integer values as ABI words to preserve the full Solidity range. Use the generated `encode_*` and `decode_*` methods when you want to manage RPC requests yourself. Transaction wrappers require an application-provided signer; this repository does not include a wallet or key store.

## Regenerate bindings

Python 3 and the exact abi-typegen version recorded in [`manifest.json`](manifest.json) are required. Download the generator from [abi-typegen releases](https://github.com/doublesharp/abi-typegen/releases).

```sh
python3 scripts/regenerate.py
python3 scripts/regenerate.py --check
```

If the generator is not on your `PATH`, set its location explicitly:

```sh
ABI_TYPEGEN_BIN=/path/to/abi-typegen python3 scripts/regenerate.py --check
```

The script checks the generator version, wraps the raw ABI arrays in named artifacts, and generates the GDScript files. Edit ABI inputs rather than generated scripts.

The ABI inputs come from the upstream repository's checked-in exports. Regeneration does not compile Solidity or verify deployed bytecode. When updating inputs, record the source commit and refresh the contract list and hashes in the manifest, then regenerate and validate the bindings. A generator upgrade also requires updating the version check in `scripts/regenerate.py` and checking native extension compatibility.

## Validate

Run these commands from the repository root, with Godot available as `godot`:

```sh
python3 scripts/regenerate.py --check
godot --headless --path . --editor --import
godot --headless --path . --script res://tests/smoke.gd
```

The smoke test loads every generated binding and checks PlayerNFT calldata encoding for scalar and dynamic-array arguments, plus lossless decoding of a large uint256. Keep its expected binding count in sync when adding or removing contracts. Check Godot output for `ERROR:` and `SCRIPT ERROR:` messages as well as the process exit code. These checks run locally without sending transactions or contacting a live chain.

## Repository layout

| Path | Contents |
| --- | --- |
| `abi/` | Upstream ABI exports |
| `artifacts/` | Named artifact inputs for the generator |
| `generated/` | Generated GDScript bindings |
| `bin/` | Native extension and Godot extension descriptor |
| `scripts/` | Regeneration tooling |
| `tests/` | Headless smoke test |
| `manifest.json` | Input provenance and generated-file hashes |

## License

Repository code and documentation are available under the [MIT license](LICENSE). Third-party notices are retained in [`licenses/`](licenses/). ABI inputs come from PaintSwap's Estfor contracts, whose source package declares MIT licensing.
