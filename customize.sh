SKIPUNZIP=1

ui_print "*******************************"
ui_print "   Miru Zero (Ultimate AIO)    "
ui_print "*******************************"

# 1. Clean up Conflicts (Miru Core)
ui_print "- Cleaning up old conflicts..."
rm -rf /data/adb/modules/zygisk_shamiko
rm -rf /data/adb/modules/playintegrityfix
rm -rf /data/adb/modules/tricky_store
rm -rf /data/adb/modules/tsupport-advance
# Note: We DON'T remove zygisk_lsposed here, we overwrite/update it.
ui_print "  > Removed old Shamiko/PIF/Tricky/TSupport modules."

# 2. Extract Miru Files
ui_print "- Extracting Miru Core..."
unzip -o "$ZIPFILE" -d "$MODPATH" >&2

# 3. Setup Shamiko (Integrated)
ui_print "- Integrating Shamiko Core..."
mkdir -p "$MODPATH/zygisk"

# Check if files exist and move if necessary (handling different naming conventions)
if [ -f "$MODPATH/zygisk/shamiko_64.so" ]; then
    mv "$MODPATH/zygisk/shamiko_64.so" "$MODPATH/zygisk/arm64-v8a.so"
fi
if [ -f "$MODPATH/zygisk/shamiko_32.so" ]; then
    mv "$MODPATH/zygisk/shamiko_32.so" "$MODPATH/zygisk/armeabi-v7a.so"
fi

# Verify Shamiko installation
if [ ! -f "$MODPATH/zygisk/arm64-v8a.so" ]; then
    ui_print "!! WARNING: Shamiko arm64 binary NOT FOUND !!"
    ui_print "!! Listing zygisk dir for debug:"
    ls -R "$MODPATH/zygisk"
else
    ui_print "  > Shamiko arm64 installed."
fi


# 4. Setup LSPosed (Bundled)
ui_print "- Installing Bundled LSPosed..."
LSP_PATH="/data/adb/modules/zygisk_lsposed"

# Clean install
rm -rf "$LSP_PATH"

# Move directory (Rename)
if [ -d "$MODPATH/bundled_lsp" ]; then
    mv "$MODPATH/bundled_lsp" "$LSP_PATH"
else
    ui_print "!! ERROR: bundled_lsp folder missing!"
    exit 1
fi

# Set LSPosed permissions
set_perm_recursive "$LSP_PATH" 0 0 0755 0644
set_perm_recursive "$LSP_PATH/bin" 0 0 0755 0755
set_perm "$LSP_PATH/service.sh" 0 0 0755
set_perm "$LSP_PATH/post-fs-data.sh" 0 0 0755
set_perm "$LSP_PATH/uninstall.sh" 0 0 0755
set_perm "$LSP_PATH/daemon" 0 0 0755

# Ensure LSPosed is enabled
touch "$LSP_PATH/disable"
rm -f "$LSP_PATH/disable"
rm -f "$LSP_PATH/remove"

ui_print "  > LSPosed Updated/Installed."

# 5. Setup Zygisk-Assistant (Bundled)
ui_print "- Installing Miru Zygisk Assistant..."
ZA_PATH="/data/adb/modules/miru_zassistant"

# Remove standalone version to avoid conflicts
rm -rf "/data/adb/modules/zygisk_assistant"

# Clean install
rm -rf "$ZA_PATH"

# Move directory (Rename)
if [ -d "$MODPATH/zassistant" ]; then
    mv "$MODPATH/zassistant" "$ZA_PATH"
else
    ui_print "!! ERROR: zassistant folder missing!"
    exit 1
fi

# Set ZA permissions
set_perm_recursive "$ZA_PATH" 0 0 0755 0644
set_perm "$ZA_PATH/post-fs-data.sh" 0 0 0755
set_perm "$ZA_PATH/service.sh" 0 0 0755
set_perm "$ZA_PATH/common_func.sh" 0 0 0755
set_perm_recursive "$ZA_PATH/zygisk" 0 0 0755 0644

# Ensure ZA is enabled
rm -f "$ZA_PATH/disable"
rm -f "$ZA_PATH/remove"

ui_print "  > Zygisk Assistant Installed."

# 6. Set Miru Permissions
ui_print "- Setting Miru permissions..."
set_perm_recursive "$MODPATH/system/bin" 0 0 0755 0755
set_perm_recursive "$MODPATH/system/etc" 0 0 0755 0644
set_perm "$MODPATH/service.sh" 0 0 0755

# 6. Config Executables
chmod +x "$MODPATH/system/bin/frs7"
chmod +x "$MODPATH/system/bin/miru-inject"
chmod +x "$MODPATH/system/bin/miru"
chmod +x "$MODPATH/system/bin/miru-web"

ui_print "*******************************"
ui_print " Miru ULTIMATE Installed!     "
ui_print " * Core: Miru Agent + WebUI   "
ui_print " * Hide: Shamiko + Zygisk Assistant"
ui_print " * Framework: Miru LSPosed (Bundled)"
ui_print " Please REBOOT to activate.   "
ui_print "*******************************"
