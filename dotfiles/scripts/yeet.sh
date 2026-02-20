#!/bin/sh
CYAN='\033[1;36m'
PURPLE='\033[1;35m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m'

# Parse arguments
PUSH_FLAG=false
COMMIT_MSG=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --push)
      PUSH_FLAG=true
      COMMIT_MSG="$2"
      shift 2
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Usage: yeet [--push \"commit message\"]"
      exit 1
      ;;
  esac
done

# Stage files
echo -e "${CYAN}Staging new files...${NC}"
git -C /etc/nixos add -A

# Only commit if --push flag is provided
if [ "$PUSH_FLAG" = true ]; then
  if git -C /etc/nixos diff-index --quiet HEAD --; then
    echo -e "${PURPLE}No changes to commit${NC}"
  else
    echo -e "${CYAN}Committing changes...${NC}"
    git -C /etc/nixos commit -m "$COMMIT_MSG"
  fi
fi

echo -e "${CYAN}Rebuilding NixOS system...${NC}"
BUILD_OUTPUT=$(doas nixos-rebuild switch --flake /etc/nixos 2>&1 | tee /dev/tty)

if echo "$BUILD_OUTPUT" | grep -q "activating the configuration" && \
   ! echo "$BUILD_OUTPUT" | grep -q "the following units failed"; then
    echo -e "${GREEN}Rebuild succeeded${NC}"
    
    # Only push if --push flag was provided and online
    if [ "$PUSH_FLAG" = true ]; then
      if ping -c 1 -W 1 8.8.8.8 &> /dev/null; then
        git -C /etc/nixos push 2>/dev/null || true
        echo -e "${GREEN}Push complete${NC}"
      else
        echo -e "${PURPLE}Offline - skipping git push${NC}"
      fi
    fi
else
    echo -e "${RED}Rebuild failed - skipping git operations${NC}"
    exit 1
fi
