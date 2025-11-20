#!/bin/bash

# --------------------------------------------
# Colors
# --------------------------------------------
RED="\e[31m"
GREEN="\e[92m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

echo -e "${BLUE}Java Installer & Version Switcher     {RESET}"
echo ""

read -p "Enter Java version (e.g. 11, 17, 21): " VERSION
PKG_NAME="openjdk-${VERSION}-jdk"

# --------------------------------------------
# Check if requested version exists in apt
# --------------------------------------------
if ! apt-cache policy "$PKG_NAME" | grep -q "Candidate:"; then
    echo -e "${RED}Java version $VERSION is not available.${RESET}"
    echo -e "${YELLOW}Please enter a valid version installed in your system or available in apt.${RESET}"
    exit 1
fi

# --------------------------------------------
# Detect previous JDK version
# --------------------------------------------
# Detect previous JDK version
PREV_VERSION=$(java -version 2>&1 | head -n 1 | grep -oP '(?<=version ")\d+')
[ -z "$PREV_VERSION" ] && PREV_VERSION="none"

echo -e "${YELLOW}Previous JDK:${RESET} $PREV_VERSION"
echo ""


# --------------------------------------------
# Check if target JDK already installed
# --------------------------------------------
ALT_PATH=$(sudo update-alternatives --list java 2>/dev/null | grep "java-${VERSION}" | head -n 1)

if [ -n "$ALT_PATH" ]; then
    echo -e "${YELLOW}switching to JDK $VERSION${RESET}"
    INSTALL_DIR=$(dirname "$(dirname "$ALT_PATH")")
else
    echo -e "${GREEN}installing jdk $VERSION ${RESET}"

    # Quiet install
    sudo apt update -qq >/dev/null 2>&1
    sudo apt install -y "$PKG_NAME" >/dev/null 2>&1

    # Recheck path
    ALT_PATH=$(sudo update-alternatives --list java | grep "java-${VERSION}" | head -n 1)

    if [ -z "$ALT_PATH" ]; then
        echo -e "${RED}no jdk found${RESET}"
        exit 1
    fi

    INSTALL_DIR=$(dirname "$(dirname "$ALT_PATH")")
fi

# --------------------------------------------
# Switch alternatives
# --------------------------------------------
sudo update-alternatives --set java "$INSTALL_DIR/bin/java" >/dev/null 2>&1
sudo update-alternatives --set javac "$INSTALL_DIR/bin/javac" >/dev/null 2>&1

# --------------------------------------------
# Update ~/.bashrc
# --------------------------------------------
sed -i '/export JAVA_HOME=/d' ~/.bashrc
sed -i '/export PATH=.JAVA_HOME/d' ~/.bashrc

{
    echo "export JAVA_HOME=$INSTALL_DIR"
    echo 'export PATH=$JAVA_HOME/bin:$PATH'
} >> ~/.bashrc

export JAVA_HOME="$INSTALL_DIR"
export PATH="$JAVA_HOME/bin:$PATH"

# --------------------------------------------
# Final clean output
# --------------------------------------------
echo ""
echo -e "${BLUE}Java $VERSION is now active         ${RESET}"
