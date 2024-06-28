# Totolin-x5000r_Zbit_Support--openwrt

OpenWRT compiled with Zbit support for Totolink X5000R | SPI-NOR chip: Zbit Semiconductor part #ZB25VQ128ASIG.

This OpenWRT build is the same as the official version, except that I have patched the firmware with Zbit support and compiled it.  
Patch info for Zbit: [GitHub Pull Request](https://github.com/openwrt/openwrt/pull/12475/commits/387ed1aecfe1a0c9c01fbcb3f8d7a873afa5a885)

Initially, I flashed OpenWRT without verifying my flash chip, ignoring the large warning at [OpenWRT Totolink X5000R](https://openwrt.org/toh/totolink/x5000r). This resulted in my router entering a bootloop. I fixed it using the serial flash method as described in this [thread](https://forum.openwrt.org/t/got-stuck-on-system-running-in-recovery-initramfs-mode-totolink-x5000r/160442/117).

## Steps to Recover from Bootloop

1. Interrupt the boot sequence:
    ```text
    regValue=[0x0]
    Port3 Link DOWN!

    Please choose the operation:
       1: Load system code to SDRAM via TFTP.
       2: Load system code then write to Flash via TFTP.
       3: Boot system code via Flash (default).
       4: Entr boot command line interface.
       6: Load Flash code then burn to Flash via TFTP.
       7: Load Boot Loader code then write to Flash via Serial.
       9: Load Boot Loader code then write to Flash via TFTP.
    default: 3

    You chose 1
    ```

2. Load the firmware onto SDRAM using option 1 and flash OpenWRT initramfs (using tftpd64).
3. When OpenWRT boots up in initramfs mode, log into LuCI, navigate to Sysupgrade, and flash the `openwrt_zbit_support sysupgrade.bin` image.
4. Reboot.

The latest version of OpenWRT that I could find was compiled by wopo at [GitHub](https://github.com/ThranduilII/openwrt). Therefore, I decided to compile the latest version of OpenWRT 23.05 (as of June 28, 2024) since it was not officially available.

## Versions Compiled

### 23.05.2
**Changelog:**
- Used the same `config.buildinfo` as found at [OpenWRT 23.05.2](https://downloads.openwrt.org/releases/23.05.3/targets/ramips/mt7621/), so my build should be almost identical to the official release.
- Added packages: `luci-app-sqm`, `luci-app-adblock`, `luci-app-banip`, `luci-app-statistics`, `luci-app-bcp38`.

### 23.05.3
**Changelog:**
- Used the same `config.buildinfo` as found at [OpenWRT 23.05.3](https://downloads.openwrt.org/releases/23.05.3/targets/ramips/mt7621/), so this build too should be identical to the official one.
- Only added `luci-app-sqm` to keep the build as close to the official release as possible.
- Added all extra themes of LuCI (e.g., Argon theme, LuCI Legacy theme). To switch to the default theme of LuCI (if desired), log into LuCI -> System -> Language and Style -> choose your desired theme.

I have also posted my `build.sh`. Although imperfect, you may use it to compile your own builds (note that the script isn't well tested). Additionally, I have posted `fix-pfring.sh` that patches the PF_RING compile bug for 23.05.3, as per this [thread](https://github.com/openwrt/packages/issues/23621). After updating and installing feeds, execute the `fix-pfring.sh`.

I have also posted the actual Zbit patch: `001-mtd-spi-nor-add-support-for-zbit-zb25vq128.patch`, which should add Zbit support for Totolink X5000R. Just copy-paste this patch into the following directory:
```plaintext
openwrt/target/ramips/patches-5.15/
example like : /home/akm/Git/Git_Cloned/Official/openwrt/target/linux/ramips/patches-5.15/001-mtd-spi-nor-add-support-for-zbit-zb25vq128.patch

