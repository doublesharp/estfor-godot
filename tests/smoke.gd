extends SceneTree

func _init() -> void:
    var files := DirAccess.get_files_at("res://generated")
    var count := 0
    for file in files:
        if file.ends_with(".gd"):
            var binding = load("res://generated/" + file)
            if binding == null or not binding.can_instantiate():
                push_error("Cannot load " + file)
                quit(1)
                return
            count += 1
    if count != 59:
        push_error("Expected 59 bindings, got %d" % count)
        quit(1)
        return
    var nft = load("res://generated/player_nft.gd")
    var one := AbiTypegenCodec.word_from_u64(1)
    var owner := "0x0000000000000000000000000000000000000001"
    var encoded: Dictionary = nft.encode_balance_of(owner, one)
    var expected := "00fdd58e" + "0".repeat(63) + "1" + "0".repeat(63) + "1"
    if not encoded.get("ok", false) or encoded["value"].hex_encode() != expected:
        push_error("balanceOf calldata mismatch: " + str(encoded))
        quit(1)
        return
    var big := "0000000000000100000000000000000000000000000000000000000000001234".hex_decode()
    var decoded: Dictionary = nft.decode_balance_of_result(big)
    if not decoded.get("ok", false) or decoded["value"] != big:
        push_error("uint256 decode mismatch: " + str(decoded))
        quit(1)
        return
    var batch: Dictionary = nft.encode_balance_of_batch([owner], [one])
    var expected_batch := "4e1273f4" + "0".repeat(62) + "40" + "0".repeat(62) + "80" + "0".repeat(63) + "1" + "0".repeat(63) + "1" + "0".repeat(63) + "1" + "0".repeat(63) + "1"
    if not batch.get("ok", false) or batch["value"].hex_encode() != expected_batch:
        push_error("balanceOfBatch calldata mismatch: " + str(batch))
        quit(1)
        return
    print("PASS: 59 bindings load; balanceOf and balanceOfBatch calldata; lossless uint256 decode")
    quit(0)
