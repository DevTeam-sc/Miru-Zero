# Miru & Shamiko Pairing Guide

To ensure Miru (Zygisk Mode) works with Shamiko:

1.  **Magisk Settings**:
    -   Enable **Zygisk**: ON
    -   **Enforce Denylist**: OFF (Crucial! Let Shamiko handle it)
    -   **Configure Denylist**: Add `ktbcs.netbank` (Check all processes)

2.  **Shamiko**:
    -   Install Shamiko module.
    -   Shamiko will read the Denylist and hide Root/Zygisk from KTB.
    -   Because "Enforce Denylist" is OFF, Magisk *will* still load Zygisk modules (like Miru) into KTB.

3.  **Miru Logic**:
    -   Miru detects `ktbcs.netbank`.
    -   Injects `libmiru.so` (Frida Gadget).
    -   **Note**: Miru's internal "Ghost Mode" is active but should not conflict with Shamiko. If instability occurs, use `frs7` (Daemon Mode) instead.
