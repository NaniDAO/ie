#!/bin/bash
echo $(cast keccak $(cast concat-hex "$(forge inspect $1 bytecode)" "$(cast abi-encode "constructor($(forge inspect $1 abi \
    | jq -r '.[] | select(.type == "constructor") | .inputs | map(.type) | join(",")'))" ${@:2})"))