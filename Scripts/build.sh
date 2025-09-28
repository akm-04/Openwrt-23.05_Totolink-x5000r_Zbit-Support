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
RELEASE="24.10.3"  # Update to the desired release version
CONFIG_URL="https://downloads.openwrt.org/releases/$RELEASE/targets/$TARGET/config.buildinfo"
FEEDS_URL="https://downloads.openwrt.org/releases/$RELEASE/targets/$TARGET/feeds.buildinfo"

# Function to log a section header in blue color
log_section() {
  echo -e "${BLUE}======================================${NC}"
  echo -e "${GREEN}$1${NC}"
  echo -e "${BLUE}======================================${NC}"
  echo  # Output a blank line for spacing
}


# Function to perform debug compilation
debug_compile() {
    log_section "Running prerequisite checks"
    make prereq || { echo -e "${RED}Failed prerequisite checks${NC}"; exit 1; }

    log_section "Downloading source files"
    make -j$(nproc) download V=w || { echo -e "${RED}Failed to download source files${NC}"; exit 1; }

    log_section "Installing toolchain"
    make -j$(nproc) toolchain/install || { echo -e "${RED}Failed to install toolchain${NC}"; exit 1; }

    log_section "Compiling target kernel and filesystem"
    make -j$(nproc) target/compile V=sw || { echo -e "${RED}Failed to compile target${NC}"; exit 1; }

    log_section "Cleaning up package directories"
    make package/cleanup V=sw || { echo -e "${RED}Failed to clean up packages${NC}"; exit 1; }

    log_section "Compiling selected packages"
    make -j$(nproc) package/compile V=w || { echo -e "${RED}Failed to compile packages${NC}"; exit 1; }

    log_section "Installing compiled packages into target filesystem"
    make package/install V=sw || { echo -e "${RED}Failed to install packages${NC}"; exit 1; }

    #log_section "Preconfiguring packages"
    #make package/preconfig V=sw || { echo -e "${RED}Failed to preconfigure packages${NC}"; exit 1; }

    log_section "Installing target kernel and filesystem"
    make target/install V=sw || { echo -e "${RED}Failed to install target${NC}"; exit 1; }

    log_section "Indexing compiled packages"
    make package/index V=sw || { echo -e "${RED}Failed to index packages${NC}"; exit 1; }
}


full_clean() {
    log_section "Running distclean ...."
    make distclean
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
# Clean before starting to compile?
#full_clean

log_section "Feed Operations"
#rev_date
# Update feeds
# Update feeds to match  buildinfo
echo -e "${YELLOW}Downloading feeds.buildinfo${NC}"
wget $FEEDS_URL -O feeds.conf || error "Failed to download feeds.buildinfo"
log_section "Custom feeds Operations"
echo "None!"
#echo -e "Adding purpl mesh to feeds"
#echo "src-link ninja file://$(pwd)/package/ninja" >> feeds.conf
#echo "src-git prpl https://gitlab.com/prpl-foundation/prplmesh/prplMesh.git" >> feeds.conf
#echo "src-git prplmesh https://github.com/prplfoundation/prplMesh-openwrt.git" >> feeds.conf
#echo "src-git feed_prpl https://gitlab.com/prpl-foundation/prplOS/feed-prpl.git" >> feeds.conf
#echo "src-git prpl https://gitlab.com/prpl-foundation/prplmesh/prplMesh.git" >> feeds.conf.default

#read -p "Press Enter to continue..."

echo -e "${YELLOW}Updating Feeds${NC}"
./scripts/feeds update -a || { echo -e "${RED}Failed to update feeds${NC}"; exit 1; }
# Install feeds
echo -e "${YELLOW}Now Installing feeds${NC}"
./scripts/feeds install -a || { echo -e "${RED}Failed to install feeds${NC}"; exit 1; }
#./scripts/feeds install ninja
#read -p "if compiling 23.05.3, please apply fix-pfring.sh and then Press Enter to continue..."

log_section "Downloading and applying config.buildinfo for stable releases"
wget $CONFIG_URL -O .config || { echo -e "${RED}Failed to download config.buildinfo${NC}"; exit 1; }
read -p "Press Enter to continue..."

#read -p "Add Zbit.patch to appripiate directory and then Press Enter to continue..."

log_section "Configuring menuconfig, please select appropiate target (Target Profile -> TOTOLINK X5000r)"
make menuconfig || { echo -e "${RED}Failed to run menuconfig${NC}"; exit 1; }

log_section "Starting Full Compile ..."
debug_compile
#make V=w -j$(nproc) download world 2>&1 | tee ../build.log || { echo -e "${RED}Failed during full build process, run in debug mode for more info${NC}"; exit 1; }

