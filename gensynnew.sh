#!/bin/bash

# Color codes
YELLOW='\033[1;33m'
BOLD='\033[1m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
PINK='\033[38;5;198m'
RED='\033[1;31m'
MAGENTA='\033[1;35m'
NC='\033[0m'

# --- Header ---
print_header() {
    clear
    echo -e "${YELLOW}${BOLD}=====================================================${NC}"
    echo -e "${YELLOW}${BOLD} # # # # # 🟡 BENGAL AIRDROP GENSYN 🟡 # # # # #${NC}"
    echo -e "${YELLOW}${BOLD} # # # # # #   MADE BY PRODIP   # # # # # #${NC}"
    echo -e "${YELLOW}${BOLD}=====================================================${NC}"
    echo -e "${CYAN}🌐 Follow on Twitter : https://x.com/prodipmandal10${NC}"
    echo -e "${CYAN}📩 DM on Telegram    : @prodipgo${NC}"
    echo -e ""
}

# --- Functions (Existing ones omitted for brevity) ---
# install_dependencies, start_gen_session, start_loc_session, move_swarm_pem, check_gen_session_status, save_login_data, restore_login_data, gensyn_fixed_run

# --- Step 9: Download, Extract & Move swarm.pem ---
download_extract_and_move_swarm() {
    echo -e "\n========== STEP 9: DOWNLOAD, EXTRACT & MOVE SWARM.PEM =========="

    # Virtual environment setup
    VENV_DIR="$HOME/pipe_gdown_venv"
    if [ ! -d "$VENV_DIR" ]; then
        echo "⚙️ Creating Python venv for gdown..."
        python3 -m venv "$VENV_DIR"
    fi
    source "$VENV_DIR/bin/activate"
    pip install --upgrade pip
    pip install gdown --break-system-packages

    DOWNLOAD_DIR="$HOME/pipe_downloads"
    EXTRACT_DIR="$HOME/pipe_extracted"
    RL_SWARM_DIR="$HOME/rl-swarm"
    mkdir -p "$DOWNLOAD_DIR" "$EXTRACT_DIR" "$RL_SWARM_DIR"

    # Google Drive zip link input
    read -p "🔗 Enter Google Drive zip link: " link
    [ -z "$link" ] && { echo "❌ No link provided. Exiting."; deactivate; return; }

    ZIP_FILE="$DOWNLOAD_DIR/temp.zip"
    echo "⚙️ Downloading zip file..."
    gdown --fuzzy "$link" -O "$ZIP_FILE"

    if [ ! -f "$ZIP_FILE" ]; then
        echo "❌ Download failed!"
        deactivate
        return
    fi

    # Extract zip
    echo "📂 Extracting zip file..."
    unzip -q "$ZIP_FILE" -d "$EXTRACT_DIR"

    # List extracted folders
    echo -e "\n📂 Extracted folders:"
    folders=($(find "$EXTRACT_DIR" -mindepth 1 -maxdepth 1 -type d))
    for i in "${!folders[@]}"; do
        folder_name=$(basename "${folders[$i]}")
        echo "$((i+1)). $folder_name"
    done

    # User selects folder
    read -p "👉 Enter folder number to move swarm.pem from: " choice
    selected_folder="${folders[$((choice-1))]}"

    SWARM_FILE="$selected_folder/swarm.pem"
    if [ -f "$SWARM_FILE" ]; then
        mv "$SWARM_FILE" "$RL_SWARM_DIR/"
        echo "✅ swarm.pem moved to $RL_SWARM_DIR/"
    else
        echo "❌ swarm.pem not found in selected folder!"
    fi

    deactivate
    echo "✅ Step 9 completed."
}

# --- Main Menu ---
while true; do
    print_header
    echo -e "${YELLOW}${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${BOLD}║      🔵 BENGAL AIRDROP GENSYN MENU 🔵    ║${NC}"
    echo -e "${YELLOW}${BOLD}╠══════════════════════════════════════════════╣${NC}"
    echo -e "${YELLOW}${BOLD}║ [${YELLOW}1${NC}${BOLD}] ${PINK}📦 Install All Dependencies               ${YELLOW}${BOLD}  ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [${YELLOW}2${NC}${BOLD}] ${PINK}🚀 Start GEN Tmux Session (Gensyn Node)  ${YELLOW}${BOLD}  ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [${YELLOW}3${NC}${BOLD}] ${PINK}🔐 Start LOC Tmux Session (Firewall+Tunnel) ${YELLOW}${BOLD}  ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [${YELLOW}4${NC}${BOLD}] ${PINK}📂 Move swarm.pem to rl-swarm/           ${YELLOW}${BOLD}  ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [${YELLOW}5${NC}${BOLD}] ${PINK}🔍 Check GEN Session Status             ${YELLOW}${BOLD}  ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [${YELLOW}6${NC}${BOLD}] ${PINK}💾 Save Login Data (Backup)             ${YELLOW}${BOLD}  ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [${YELLOW}7${NC}${BOLD}] ${PINK}♻️ Restore Login Data (Backup)           ${YELLOW}${BOLD}  ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [${YELLOW}8${NC}${BOLD}] ${PINK}🛠️ GENSYN FIXED RUN (3 Times)          ${YELLOW}${BOLD}  ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [${YELLOW}9${NC}${BOLD}] ${PINK}📥 Download, Extract & Move swarm.pem   ${YELLOW}${BOLD}  ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [${YELLOW}0${NC}${BOLD}] ${PINK}👋 Exit Script                           ${YELLOW}${BOLD}  ║${NC}"
    echo -e "${YELLOW}${BOLD}╚══════════════════════════════════════════════╝${NC}"
    echo -e ""

    read -p "${PINK}👉 Enter your choice [0-9]: ${NC}" choice
    case $choice in
        1) install_dependencies ;;
        2) start_gen_session ;;
        3) start_loc_session ;;
        4) move_swarm_pem ;;
        5) check_gen_session_status ;;
        6) save_login_data ;;
        7) restore_login_data ;;
        8) gensyn_fixed_run ;;
        9) download_extract_and_move_swarm ;;
        0) echo -e "${CYAN}🚪 Exiting... Goodbye! 👋${NC}"; exit 0 ;;
        *) echo -e "${RED}❌ Invalid option! Please enter a number between 0-9.${NC}";;
    esac
    echo -e ""
    read -p "${CYAN}Press Enter to continue...${NC}"
done
