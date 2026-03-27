#!/bin/bash

ADB="/Users/$USER/Library/Android/sdk/platform-tools/adb"

# Verifica se o emulador já está a correr
if $ADB devices | grep -q "emulator-5554"; then
    echo "Emulator already running"
    exit 0
fi

# Lança o emulador numa sessão completamente separada via osascript
osascript -e 'tell application "Terminal" to do script "/Users/$USER/Library/Android/sdk/emulator/emulator -avd Pixel_9_Pro > /tmp/emulator.log 2>&1"'

# Dá tempo ao emulador para se registar no adb
sleep 5

# Espera que o boot complete
echo "Waiting for emulator to boot..."
until $ADB shell getprop sys.boot_completed 2>/dev/null | grep -q "1"; do
    sleep 2
done

echo "Emulator ready!"