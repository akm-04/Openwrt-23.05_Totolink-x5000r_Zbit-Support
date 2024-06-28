#!/bin/bash

# Exit immediately if a command exits with a non-zero status
#set -e

cd openwrt
# Define colors for echo statements
YELLOW='\033[1;33m'
RED='\033[1;31m'
GREEN='\033[1;32m'  # Bright green
BLUE='\033[1;36m'   # Bright cyan
NC='\033[0m'        # Reset color
# Define variables
REPO_URL="https://git.openwrt.org/openwrt/openwrt.git"
TARGET="ramips/mt7621"
RELEASE="23.05.3"  # Update to the desired release version
CONFIG_URL="https://downloads.openwrt.org/releases/$RELEASE/targets/$TARGET/config.buildinfo"

# Function to log a section header in blue color
log_section() {
  echo -e "${BLUE}======================================${NC}"
  echo -e "${GREEN}$1${NC}"
  echo -e "${BLUE}======================================${NC}"
  echo  # Output a blank line for spacing
}



rev_date() {
  # Sync feeds to the same date as the checked-out version
  echo -e "${YELLOW}Syncing feeds to the same date as the checked-out version...${NC}"
  sed -e "/^src-git\S*/s//src-git-full/" feeds.conf.default > feeds.conf
  ./scripts/feeds update -a

  REV_DATE="$(git log -1 --format=%cd --date=iso8601-strict)"
  sed -n -e "/^src-git\S*\s/{s///;s/\s.*$//p}" feeds.conf | while read -r FEED_ID
  do
    REV_HASH="$(git -C feeds/${FEED_ID} rev-list -n 1 --before=${REV_DATE} master)"
    sed -i -e "/\s${FEED_ID}\s.*\.git$/s/$/^${REV_HASH}/" feeds.conf
  done
}


# Function to perform debug compilation
debug_compile() {
    log_section "Running prerequisite checks"
    make prereq || { echo -e "${RED}Failed prerequisite checks${NC}"; exit 1; }

    log_section "Downloading source files"
    make -j$(nproc) download || { echo -e "${RED}Failed to download source files${NC}"; exit 1; }

    log_section "Installing toolchain"
    make -j$(nproc) toolchain/install || { echo -e "${RED}Failed to install toolchain${NC}"; exit 1; }

    log_section "Compiling target kernel and filesystem"
    make -j$(nproc) target/compile V=sw || { echo -e "${RED}Failed to compile target${NC}"; exit 1; }

    log_section "Cleaning up package directories"
    make package/cleanup V=sw || { echo -e "${RED}Failed to clean up packages${NC}"; exit 1; }

    log_section "Compiling selected packages"
    make -j$(nproc) package/compile || { echo -e "${RED}Failed to compile packages${NC}"; exit 1; }

    log_section "Installing compiled packages into target filesystem"
    make package/install V=sw || { echo -e "${RED}Failed to install packages${NC}"; exit 1; }

    #log_section "Preconfiguring packages"
    #make package/preconfig V=sw || { echo -e "${RED}Failed to preconfigure packages${NC}"; exit 1; }

    log_section "Installing target kernel and filesystem"
    make target/install V=sw || { echo -e "${RED}Failed to install target${NC}"; exit 1; }

    log_section "Indexing compiled packages"
    make package/index V=sw || { echo -e "${RED}Failed to index packages${NC}"; exit 1; }
}

log_section "Target selected $TARGET"


# Log section for branch operations
log_section "Branch Operations"

# Check current branch
echo -e "${YELLOW}Current Branch${NC}"
git branch

# Fetch tags from the repository
echo -e "${YELLOW}Fetching tags ...${NC}"
git fetch --tags || { echo -e "${RED}Failed to fetch tags${NC}"; exit 1; }

# Checkout the main branch
echo -e "${YELLOW}Checkout correct branch${NC}"
git checkout v$RELEASE || { echo -e "${RED}Failed to checkout stable branch${NC}"; exit 1; }


# Check branch status after switching
echo -e "${YELLOW}After switching branch${NC}"
git branch

log_section "Feed Operations"
rev_date
# Update feeds
echo -e "${YELLOW}Updating Feeds${NC}"
./scripts/feeds update -a || { echo -e "${RED}Failed to update feeds${NC}"; exit 1; }
# Install feeds
echo -e "${YELLOW}Now Installing feeds${NC}"
./scripts/feeds install -a || { echo -e "${RED}Failed to install feeds${NC}"; exit 1; }
read -p "if compiling 23.05.3, please apply fix-pfring.sh and then Press Enter to continue..."

log_section "Downloading and applying config.buildinfo for stable releases"
wget $CONFIG_URL -O .config || { echo -e "${RED}Failed to download config.buildinfo${NC}"; exit 1; }

read -p "Add Zbit.patch to appripiate directory and then Press Enter to continue..."

log_section "Configuring menuconfig, please select appropiate target (Target Profile -> TOTOLINK X5000r)"
make menuconfig || { echo -e "${RED}Failed to run menuconfig${NC}"; exit 1; }

log_section "Starting Full Compile ..."
#debug_compile
make V=sw -j$(nproc) download world 2>&1 | tee ../build.log || { echo -e "${RED}Failed during full build process, run in debug mode for more info${NC}"; exit 1; }

