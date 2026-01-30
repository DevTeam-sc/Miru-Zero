#!/system/bin/sh
# Miru Zero Service Script
MODDIR=${0%/*}
# Log to tmp for reliability
LOGfile="/data/local/tmp/miru_service.log"
exec > "$LOGfile" 2>&1
set -x

echo "[Miru] Service started at $(date)"

# ==============================================================================
# 0. DNS Spoofing (bypass.miru.work -> 127.0.0.1)
# ==============================================================================
echo "[Miru] Configuring DNS..." >> $LOGfile
HOSTS_LINE="127.0.0.1 bypass.miru.work"
if ! grep -q "bypass.miru.work" /system/etc/hosts; then
    # Clone hosts to tmp
    cp /system/etc/hosts /data/local/tmp/hosts_miru
    # Append our entry
    echo "$HOSTS_LINE" >> /data/local/tmp/hosts_miru
    # Bind mount over system hosts
    mount --bind /data/local/tmp/hosts_miru /system/etc/hosts
    echo "[Miru] DNS spoofed: bypass.miru.work" >> $LOGfile
fi

# ==============================================================================
# 1. TSupport/Tricky Store Logic (Integrity & Prop Spoofing)
# ==============================================================================
echo "[Miru] Applying Integrity Fixes..." >> $LOGfile

# SafetyNet / Play Integrity Props (Zygisk Assistant Logic)
resetprop -n ro.boot.verifiedbootstate green
resetprop -n ro.boot.flash.locked 1
resetprop -n ro.boot.vbmeta.device_state locked
resetprop -n ro.boot.veritymode enforcing
resetprop -n ro.secure 1
resetprop -n ro.debuggable 0
resetprop -n sys.oem_unlock_allowed 0
resetprop -n ro.build.type user
resetprop -n ro.build.tags release-keys
resetprop -n ro.build.selinux 1

# Extended Warranty/Bootloader Hiding (Samsung/Vendor)
resetprop -n ro.boot.warranty_bit 0
resetprop -n ro.warranty_bit 0
resetprop -n ro.vendor.boot.warranty_bit 0
resetprop -n ro.vendor.warranty_bit 0
resetprop -n ro.boot.qemu 0
resetprop -n ro.kernel.qemu 0

# Hide vbmeta digest (common detection vector)
resetprop -n --delete ro.boot.vbmeta.digest

SAFE_PRINT="google/husky/husky:14/AP1A.240305.019.A1/11445699:user/release-keys"
resetprop -n ro.build.fingerprint $SAFE_PRINT
resetprop -n ro.bootimage.build.fingerprint $SAFE_PRINT

# TSupport Advance: Full Prop Spoofing (Pixel 8 Pro)
resetprop -n ro.product.brand google
resetprop -n ro.product.device husky
resetprop -n ro.product.manufacturer Google
resetprop -n ro.product.model "Pixel 8 Pro"
resetprop -n ro.product.name husky
resetprop -n ro.build.version.security_patch 2024-03-05
resetprop -n ro.build.version.release 14
resetprop -n ro.build.id AP1A.240305.019.A1

# TSupport Advance: Samsung/Knox Hiding
resetprop -n ro.boot.warranty_bit 0
resetprop -n ro.warranty_bit 0
resetprop -n ro.boot.qemu 0
resetprop -n ro.kernel.qemu 0
resetprop -n ro.hardware.keystore mtk
# Note: Adjust 'mtk' if device is Qualcomm, but 'mtk' is often safer for generic hiding

# Hide USB Debugging traces
resetprop -n init.svc.adbd stopped
resetprop -n sys.usb.state none

# ==============================================================================
# 2. Start frs7 (Frida Server)
# ==============================================================================
if [ -f "$MODDIR/system/bin/frs7" ]; then
    echo "[Miru] Starting frs7..." >> $LOGfile
    chmod 755 "$MODDIR/system/bin/frs7"
    
    pkill -9 -f frs7
    pkill -9 -f frida-server
    
    "$MODDIR/system/bin/frs7" -D
    echo "[Miru] frs7 started" >> $LOGfile
fi

# 5. HMA (Hide My Applist) Auto-Setup
PKG_HMA="com.tsng.hidemyapplist"
if ! pm list packages | grep -q "$PKG_HMA"; then
    if [ -f "$MODDIR/apk/HMA.apk" ]; then
        pm install "$MODDIR/apk/HMA.apk"
    fi
fi

# Inject HMA Config (Enforce Miru Standard)
HMA_DATA="/data/data/$PKG_HMA"
if [ -d "$HMA_DATA" ]; then
    mkdir -p "$HMA_DATA/files"
    mkdir -p "$HMA_DATA/shared_prefs"
    
    if [ -f "$MODDIR/apk/hma_config.json" ]; then
        cp "$MODDIR/apk/hma_config.json" "$HMA_DATA/files/config.json"
    fi
    
    if [ -f "$MODDIR/apk/hma_settings.xml" ]; then
        cp "$MODDIR/apk/hma_settings.xml" "$HMA_DATA/shared_prefs/settings.xml"
    fi
    
    # Fix Permissions
    HMA_UID=$(stat -c %u "$HMA_DATA")
    HMA_GID=$(stat -c %g "$HMA_DATA")
    
    if [ ! -z "$HMA_UID" ]; then
        chown $HMA_UID:$HMA_GID "$HMA_DATA/files/config.json"
        chown $HMA_UID:$HMA_GID "$HMA_DATA/shared_prefs/settings.xml"
        chmod 600 "$HMA_DATA/files/config.json"
        chmod 660 "$HMA_DATA/shared_prefs/settings.xml"
    fi
    
    # Reload HMA to apply config
    am force-stop "$PKG_HMA"
fi

# Enable HMA in LSPosed (Auto)
LSP_CLI="/data/adb/lspd/bin/cli"
if [ -f "$LSP_CLI" ]; then
    echo "[Miru] Waiting for LSPd..." >> $LOGfile
    # Wait for LSPd to be ready (max 30s)
    for i in $(seq 1 10); do
        if pgrep -f "lspd" > /dev/null; then
            echo "[Miru] LSPd is running, enabling HMA..." >> $LOGfile
            # Enable HMA Module
            sh "$LSP_CLI" enable-module "$PKG_HMA" >> $LOGfile 2>&1
            # Ensure Scope is Active? (HMA handles scope internally via config)
            break
        fi
        sleep 3
    done
fi

# 6. WebUI Auto-Start
if [ -f "$MODDIR/system/bin/miru-web" ]; then
    echo "[Miru] Starting WebUI..." >> $LOGfile
    chmod 755 "$MODDIR/system/bin/miru-web"
    "$MODDIR/system/bin/miru-web" &
    echo "[Miru] WebUI started at port 8888" >> $LOGfile
fi

echo "[Miru] All Systems Go." >> $LOGfile
