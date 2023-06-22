#!/usr/bin/env bash
# Original source: https://repo.jellyfin.org/install-debuntu.sh
shopt -s extglob

# Lists of supported architectures, Debian, and Ubuntu releases
SUPPORTED_ARCHITECTURES='@(amd64|armhf|arm64)'
SUPPORTED_DEBIAN_RELEASES='@(buster|bullseye|bookworm)'
SUPPORTED_UBUNTU_RELEASES='@(trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar)'

# Check that /etc/apt exists; if not, this isn't a valid distro for this script
if [[ ! -d /etc/apt ]]; then
    echo "This script is for Debian-based distributions using APT only."
    echo "See our downloads page at https://jellyfin.org/downloads/server for more options."
    exit 1
fi

# Check that we're root; if not, fail out
if [[ $(whoami) != "root" ]]; then
    echo "This script must be run as 'root' or with 'sudo' to function."
    echo "Try using the command: curl https://repo.jellyfin.org/install-debuntu.sh | sudo bash"
    exit 1
fi

# Fail out if we can't find /etc/os-release
if [[ ! -f /etc/os-release ]]; then
    echo
    echo "Failed to find file '/etc/os-release'. This script requires '/etc/os-release' to autodetect repository settings, and this is likely an unsupported operating system."
    echo "Consider using the manual instructions or files from https://jellyfin.org/downloads/server instead, or use https://jellyfin.org/contact to find us for troubleshooting."
    exit 1
fi

# Get the paths to curl and wget
CURL=$( which curl )
WGET=$( which wget )

# Create our array of to-be-installed packages
INSTALL_PKGS=()

# Pick our optimal fetching program (curl, then wget, then install curl)
if [[ -n ${CURL} ]]; then
    FETCH="${CURL} -fsSL"
elif [[ -n ${WGET} ]]; then
    FETCH="${WGET} -O-"
else
    echo "Failed to find a suitable download program. We're not sure how you dowloaded this script, but we'll install 'curl' automatically."
    # shellcheck disable=SC2206
    # We are OK with word-splitting here since we control the contents
    INSTALL_PKGS=( ${INSTALL_PKGS[@]} curl )
    FETCH="${CURL} -fsSL"
    echo
fi

# Get the path to gpg or install it
GNUPG=$( which gpg )
if [[ -z ${GNUPG} ]]; then
    echo "Failed to find the GNUPG binary, but we'll install 'gnupg' automatically."
    # shellcheck disable=SC2206
    # We are OK with word-splitting here since we control the contents
    INSTALL_PKGS=( ${INSTALL_PKGS[@]} gnupg )
    echo
fi

echo "> Determining optimal repository settings."

# Get the (dpkg) architecture and base OS from /etc/os-release
ARCHITECTURE="$( dpkg --print-architecture )"
BASE_OS="$( awk -F'=' '/^ID=/{ print $NF }' /etc/os-release )"

# Validate that we're running on a supported (dpkg) architecture
# shellcheck disable=SC2254
# We cannot quote this extglob expansion or it doesn't work
case "${ARCHITECTURE}" in
    ${SUPPORTED_ARCHITECTURES})
        true
    ;;
    *)
        echo "Sorry, we don't support the CPU architecture '${ARCHITECTURE}'."
        exit 1
    ;;
esac

# Handle some known alternative base OS values with 1-to-1 mappings
# Use the result as our repository base OS
case "${BASE_OS}" in
    raspbian)
        # Raspbian uses our Debian repository
        REPO_OS="debian"
    ;;
    linuxmint)
        # Linux Mint can either be Debian- or Ubuntu-based, so pick the right one
        if grep -q "DEBIAN_CODENAME=" /etc/os-release &>/dev/null; then
            VERSION="$( awk -F'=' '/^DEBIAN_CODENAME=/{ print $NF }' /etc/os-release )"
            REPO_OS="debian"
        else
            VERSION="$( awk -F'=' '/^UBUNTU_CODENAME=/{ print $NF }' /etc/os-release )"
            REPO_OS="ubuntu"
        fi
    ;;
    neon)
        # Neon uses our Ubuntu repository
        REPO_OS="ubuntu"
    ;;
    *)
        REPO_OS="${BASE_OS}"
        VERSION="$( awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release )"
    ;;
esac

# Validate that we're running a supported release (variables at top of file)
case "${REPO_OS}" in
    debian)
        # shellcheck disable=SC2254
        # We cannot quote this extglob expansion or it doesn't work
        case "${VERSION}" in
            ${SUPPORTED_DEBIAN_RELEASES})
                true
            ;;
            *)
                echo "Sorry, we don't support the Debian codename '${VERSION}'."
                exit 1
            ;;
        esac
    ;;
    ubuntu)
        # shellcheck disable=SC2254
        # We cannot quote this extglob expansion or it doesn't work
        case "${VERSION}" in
            ${SUPPORTED_UBUNTU_RELEASES})
                true
            ;;
            *)
                echo "Sorry, we don't support the Ubuntu codename '${VERSION}'."
                exit 1
            ;;
        esac
    ;;
    *)
        echo "Sorry, we don't support the base OS '${REPO_OS}'."
        exit 1
    ;;
esac

echo
echo -e "Found the following details from '/etc/os-release':"
echo -e "  Real OS:            ${BASE_OS}"
echo -e "  Repository OS:      ${REPO_OS}"
echo -e "  Repository Release: ${VERSION}"
echo -e "  CPU Architecture:   ${ARCHITECTURE}"

# COMMENTED OUT because it needs input from user
# echo -en "If this looks correct, press <Enter> now to continue installing Jellyfin. "
# Use < /dev/tty construct to ensure we stop even in a curl|bash scenario
# See https://stackoverflow.com/a/6562852/5253131
# shellcheck disable=SC2162
# We are OK with this read stripping backslashes, as it is just a pause and is discarded
# read < /dev/tty

echo

# If we have at least 1 dependency package to install (either curl or gnupg), do so
if [[ ${#INSTALL_PKGS[@]} -gt 0 ]]; then
    echo "> Updating APT repositories."
    apt update
    echo
    echo "> Installing required dependencies."
    apt install --yes "${INSTALL_PKGS[@]}"
    echo
fi

# If the keyring directory is absent, create it
if [[ ! -d /etc/apt/keyrings ]]; then
    echo "> Creating APT keyring directory."
    mkdir -p /etc/apt/keyrings
    echo
fi

# Download our repository signing key and install it to the keyring directory
echo "> Fetching repository signing key."
$FETCH https://repo.jellyfin.org/jellyfin_team.gpg.key | gpg --dearmor --yes --output /etc/apt/keyrings/jellyfin.gpg
# shellcheck disable=SC2181
# We don't want to explicitly include the command in the 'if' for readibility
if [[ $? -gt 0 ]]; then
    echo "Failed to install key. Use https://jellyfin.org/contact to find us for troubleshooting."
    exit 1
fi
echo

# Check for and remove the obsoleted jellyfin.list configuration if present
if [[ -f /etc/apt/sources.list.d/jellyfin.list ]]; then
    echo "> Found old-style '/etc/apt/sources.list.d/jellyfin.list' configuration; removing it."
    rm -f /etc/apt/sources.list.d/jellyfin.list
    echo
fi

# Install the Deb822 format jellyfin.sources entry
echo "> Installing Jellyfin repository into APT."
cat <<EOF | tee /etc/apt/sources.list.d/jellyfin.sources
Types: deb
URIs: https://repo.jellyfin.org/${REPO_OS}
Suites: ${VERSION}
Components: main
Architectures: ${ARCHITECTURE}
Signed-By: /etc/apt/keyrings/jellyfin.gpg
EOF
echo

# Update the apt repositories to fetch the new Jellyfin repository
echo "> Updating APT repositories."
apt update
# shellcheck disable=SC2181
# We don't want to explicitly include the command in the 'if' for readibility
if [[ $? -gt 0 ]]; then
    echo "Failed to update APT repositories. Something is wrong with your APT sources, GPG keys, or Internet connection. Try again shortly or use https://jellyfin.org/contact to find us for troubleshooting."
    exit 1
fi
echo

# You can now do other things like install Jellyfin, however, we only need to install a specific version of jellyfin-ffmpeg,
# and we don't need jellyfin actually installed and running in the container.

###
### COMMENTED OUT:
###
# # Install Jellyfin using the metapackage (which will fetch jellyfin-server, jellyfin-web, and jellyfin-ffmpeg[5]
# echo "> Installing Jellyfin."
# apt install --yes jellyfin
# # shellcheck disable=SC2181
# # We don't want to explicitly include the command in the 'if' for readibility
# if [[ $? -gt 0 ]]; then
#     echo "Failed to install Jellyfin. Use https://jellyfin.org/contact to find us for troubleshooting."
#     exit 1
# fi
# echo

# # Wait for Jellyfin to actually start up, preempting quick users who might click the link below too quickly
# echo "> Waiting 15 seconds for Jellyfin to fully start up."
# sleep 15
# echo

# # Output the result of systemctl status (or service status for init.d/upstart) to validate Jellyfin is running
# echo "-------------------------------------------------------------------------------"
# export SYSTEMD_PAGER=
# systemctl status jellyfin.service || service jellyfin status
# echo "-------------------------------------------------------------------------------"
# echo
#
# # Determine the IP address of the interface which contains the default gateway
# # This is a relatively sure bet to be the IP address that Jellyfin can be accessed on, for later display
# GATEWAY_IFACE="$( ip route \
#                   | grep '^default' \
#                   | head -1 \
#                   | grep -o 'dev [a-z0-9]* ' \
#                   | awk '{ print $NF }' )"
# IP_ADDRESS="$( ip address show dev "${GATEWAY_IFACE}" \
#                | grep -w "inet .* scope global ${GATEWAY_IFACE}$" \
#                | awk '{ print $2 }' \
#                | awk -F '/' '{ print $1 }' )"

# # Output the explanation of the above output, next-step including link with IP address/port, and welcome message
# echo "You should see the service as 'active (running)' above. If not, use https://jellyfin.org/contact to find us for troubleshooting."
# echo
# echo "You can access your new instance now at http://${IP_ADDRESS}:8096 in your web browser to finish setting up Jellyfin."
# echo
# echo "Thank you for installing Jellyfin, and happy watching!"
# echo

# Explicitly exit cleanly
exit 0
