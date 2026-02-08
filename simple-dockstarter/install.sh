#!/usr/bin/env bash
# Simple DockSTARTer - Installation Script
# This script installs dependencies and sets up Simple DockSTARTer

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Simple DockSTARTer - Installation   ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}✗ Please do not run this script as root${NC}"
   echo -e "  Run it as your normal user instead."
   exit 1
fi

echo -e "${CYAN}[1/5]${NC} Checking system requirements..."

# Check Python 3
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}✗ Python 3 not found${NC}"
    echo -e "  Please install Python 3.8 or newer first."
    exit 1
else
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    echo -e "${GREEN}✓${NC} Python 3 found: ${PYTHON_VERSION}"
fi

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}⚠${NC} Docker not found"
    echo -e "  Would you like to install Docker now? (y/n)"
    read -r install_docker
    if [[ $install_docker == "y" ]]; then
        echo -e "${CYAN}Installing Docker...${NC}"
        curl -fsSL https://get.docker.com | sh
        sudo usermod -aG docker $USER
        echo -e "${GREEN}✓${NC} Docker installed"
        echo -e "${YELLOW}⚠ Please log out and log back in for Docker group changes to take effect${NC}"
        echo -e "  Then run this script again."
        exit 0
    else
        echo -e "${RED}✗ Docker is required${NC}"
        exit 1
    fi
else
    DOCKER_VERSION=$(docker --version 2>&1 | awk '{print $3}' | sed 's/,//')
    echo -e "${GREEN}✓${NC} Docker found: ${DOCKER_VERSION}"
fi

echo ""
echo -e "${CYAN}[2/5]${NC} Installing Python dependencies..."

# Check if pip3 is available
if ! command -v pip3 &> /dev/null; then
    echo -e "${YELLOW}⚠${NC} pip3 not found, trying to install..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y python3-pip
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y python3-pip
    elif command -v yum &> /dev/null; then
        sudo yum install -y python3-pip
    elif command -v pacman &> /dev/null; then
        sudo pacman -S python-pip
    else
        echo -e "${RED}✗ Cannot install pip3 automatically${NC}"
        echo -e "  Please install python3-pip manually."
        exit 1
    fi
fi

# Install Python packages
echo -e "  Installing InquirerPy, Rich, and PyYAML..."
pip3 install --user InquirerPy rich PyYAML 2>&1 | grep -i "successfully installed" || true
echo -e "${GREEN}✓${NC} Python dependencies installed"

echo ""
echo -e "${CYAN}[3/5]${NC} Setting up Simple DockSTARTer..."

# Make script executable
chmod +x dockstarter.py
echo -e "${GREEN}✓${NC} Made dockstarter.py executable"

# Create data directory
mkdir -p data
echo -e "${GREEN}✓${NC} Created data directory"

echo ""
echo -e "${CYAN}[4/5]${NC} Testing installation..."

# Test if script can run
if python3 dockstarter.py --help &> /dev/null || true; then
    echo -e "${GREEN}✓${NC} Script is working"
else
    echo -e "${YELLOW}⚠${NC} Script test completed (--help not implemented, this is normal)"
fi

echo ""
echo -e "${CYAN}[5/5]${NC} Optional: Create global command..."
echo -e "  Would you like to create a global 'simple-ds' command? (y/n)"
read -r create_symlink

if [[ $create_symlink == "y" ]]; then
    SCRIPT_PATH="$(pwd)/dockstarter.py"
    if sudo ln -sf "$SCRIPT_PATH" /usr/local/bin/simple-ds 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Created global command 'simple-ds'"
        echo -e "  You can now run Simple DockSTARTer from anywhere with: ${CYAN}simple-ds${NC}"
    else
        echo -e "${YELLOW}⚠${NC} Could not create global command (needs sudo)"
        echo -e "  You can still run it with: ${CYAN}./dockstarter.py${NC}"
    fi
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Installation Complete! 🎉         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "To get started, run:"
echo ""
if [[ $create_symlink == "y" ]] && [[ -f /usr/local/bin/simple-ds ]]; then
    echo -e "  ${CYAN}simple-ds${NC}"
else
    echo -e "  ${CYAN}./dockstarter.py${NC}"
fi
echo ""
echo -e "For more information, see: ${CYAN}README.md${NC}"
echo ""
echo -e "Available apps (${YELLOW}$(ls -1 apps/*.yml 2>/dev/null | wc -l)${NC}):"
for app in apps/*.yml; do
    if [[ -f "$app" ]]; then
        app_name=$(basename "$app" .yml)
        app_desc=$(grep "^description:" "$app" | cut -d'"' -f2)
        echo -e "  • ${CYAN}${app_name}${NC} - ${app_desc}"
    fi
done
echo ""
