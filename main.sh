#!/usr/bin/env bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

echo "=== Ensuring submodules are set up ==="
git submodule update --init --recursive

SRC="qmk-fw"
KEYBOARD=""
KEYMAP="default"
ACTION=""
while [[ $# -gt 0 ]]; do
    case $1 in
    -s | --src)
        SRC="$2"
        shift 2
        ;;
    -kb | --keyboard)
        KEYBOARD="$2"
        shift 2
        ;;
    -km | --keymap)
        KEYMAP="$2"
        shift 2
        ;;
    *)
        if [[ -z "$ACTION" ]]; then
            ACTION="$1"
        else
            echo "Error: only 1 action is supported"
            exit 1
        fi
        shift
        ;;

    esac
done

if [[ -z "$ACTION" ]]; then
    ACTION="compile"
fi

if [[ -z "$KEYBOARD" ]]; then
    echo "Error: a keyboard must be specified"
    exit 1
fi

SRC_PATH="$SCRIPT_DIR/submodules/$SRC"

if [[ -d "$SRC_PATH" ]]; then
    echo "=== Using $SRC_PATH as qmk firmware source ==="
else
    echo "Error: Could not find $SRC_PATH"
    exit 1
fi

pushd "$SRC_PATH" >/dev/null

echo "=== Doing QMK setup ==="
qmk setup -y --home "$(pwd)" </dev/null

# Doesn't seem to work for keychron fork?
#echo "Setting overlay dir"
#qmk config user.overlay_dir="$SCRIPT_DIR"
echo "=== Copying over keymaps ==="
cp -r $SCRIPT_DIR/keyboards .

echo "=== Patching out dependency check ==="
sed -i "s/if _broken_module_imports('requirements.txt'):/if False:/" "lib/python/qmk/cli/__init__.py"

cmd="qmk $ACTION -kb "$KEYBOARD" -km "$KEYMAP""
echo "=== Running command '$cmd' ==="
eval "$cmd"

echo "=== Moving outputs to '$SCRIPT_DIR' ==="
mv *.bin $SCRIPT_DIR

echo "=== Cleaning up ==="
git checkout .
git clean -fd

popd >/dev/null
