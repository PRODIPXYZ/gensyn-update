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

# --- Function to print the main header ---
print_header() {
    clear
    echo -e "${YELLOW}${BOLD}=====================================================${NC}"
    echo -e "${YELLOW}${BOLD} # # # # # 🟡 BENGAL AIRDROP GENSYN 🟡 # # # # #${NC}"
    echo -e "${YELLOW}${BOLD} # # # # # #   MADE BY PRODIP   # # # # # #${NC}"
    echo -e "${YELLOW}${BOLD}=====================================================${NC}"
    echo -e "${CYAN}🌐 Follow on Twitter : https://x.com/prodipmandal10${NC}"
    echo -e "${CYAN}📩 DM on Telegram    : @prodipgo${NC}"
    echo -e ""
}

# --- Function: Install all dependencies ---
install_dependencies() {
    echo -e "${GREEN}========== STEP 1: INSTALL ALL DEPENDENCIES ==========${NC}"
    sudo apt update
    sudo apt install -y sudo tmux python3 python3-pip python3-venv python3-distutils curl wget screen git lsof ufw gnupg
    echo -e "${CYAN}📦 Installing Yarn...${NC}"
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/yarn.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list >/dev/null
    sudo apt update && sudo apt install -y yarn
    echo -e "${CYAN}🚀 Running Gensyn node setup script from ABHIEBA...${NC}"
    curl -sSL https://raw.githubusercontent.com/ABHIEBA/Gensyn/main/node.sh | bash
}

# --- Function: Start GEN tmux session ---
start_gen_session() {
    if tmux has-session -t GEN 2>/dev/null; then
        echo -e "${YELLOW}⚠️ GEN session already exists.${NC}"
    else
        tmux new-session -d -s GEN "bash -c '
            cd \$HOME &&
            rm -rf gensyn-testnet &&
            git clone https://github.com/zunxbt/gensyn-testnet.git &&
            chmod +x gensyn-testnet/gensyn.sh &&
            ./gensyn-testnet/gensyn.sh;
            exec bash
        '"
    fi
    tmux attach-session -t GEN
}

# --- Function: Start LOC tmux session ---
start_loc_session() {
    if tmux has-session -t LOC 2>/dev/null; then
        echo -e "${YELLOW}⚠️ LOC session already exists.${NC}"
    else
        tmux new-session -d -s LOC "bash -c '
            sudo ufw allow 22 &&
            sudo ufw allow 3000/tcp &&
            echo y | sudo ufw enable &&
            wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb &&
            sudo dpkg -i cloudflared-linux-amd64.deb &&
            cloudflared tunnel --url http://localhost:3000;
            exec bash
        '"
    fi
    tmux attach-session -t LOC
}

# --- Function: Move swarm.pem manually ---
move_swarm_pem() {
    if [ -f "swarm.pem" ]; then
        mkdir -p rl-swarm
        mv swarm.pem rl-swarm/
        echo -e "${GREEN}✅ swarm.pem moved successfully!${NC}"
    else
        echo -e "${RED}❌ swarm.pem not found!${NC}"
    fi
}

# --- Function: Download swarm.pem from Google Drive (with venv logic) ---
download_swarm_pem() {
    VENV_DIR="$HOME/gensyn_venv"

    # Check/install venv
    if [ ! -d "$VENV_DIR" ]; then
        echo -e "${CYAN}⚡ Creating virtual environment for gdown...${NC}"
        python3 -m venv "$VENV_DIR" || { echo -e "${RED}❌ venv creation failed. Install python3-venv and python3-distutils.${NC}"; return 1; }
    fi

    # Activate venv
    source "$VENV_DIR/bin/activate"

    # Install gdown inside venv
    pip install --upgrade pip
    pip install --upgrade gdown

    read -p "👉 Enter Google Drive Folder ID or URL: " FOLDER_ID
    TMP_DIR="gdrive_temp"
    mkdir -p "$TMP_DIR" && cd "$TMP_DIR"

    echo -e "${CYAN}📂 Listing files in folder...${NC}"
    gdown --folder "$FOLDER_ID" --quiet --dry-run

    echo -e "${CYAN}⬇️ Downloading swarm.pem ...${NC}"
    gdown --folder "$FOLDER_ID" --quiet --fuzzy

    if [ -f "swarm.pem" ]; then
        mkdir -p ../rl-swarm
        mv swarm.pem ../rl-swarm/
        echo -e "${GREEN}✅ swarm.pem downloaded & moved to rl-swarm/${NC}"
    else
        echo -e "${RED}❌ swarm.pem not found in folder!${NC}"
    fi

    cd ..
    deactivate
}

# --- Function: Check GEN session status ---
check_gen_session_status() {
    if tmux has-session -t GEN 2>/dev/null; then
        echo -e "${GREEN}✅ GEN session is running.${NC}"
    else
        echo -e "${RED}❌ GEN session is NOT running.${NC}"
    fi
}

# --- Function: Save login data ---
save_login_data() {
    src_path="${HOME}/rl-swarm/modal-login/temp-data"
    dest_path="${HOME}/rl-swarm/backup-login"
    mkdir -p "$dest_path"
    cp "$src_path/userApiKey.json" "$src_path/userData.json" "$dest_path/" 2>/dev/null \
        && echo -e "${GREEN}✅ Backup saved in $dest_path${NC}" \
        || echo -e "${RED}❌ Login data not found!${NC}"
}

# --- Function: Restore login data ---
restore_login_data() {
    src_path="${HOME}/rl-swarm/backup-login"
    dest_path="${HOME}/rl-swarm/modal-login/temp-data"
    mkdir -p "$dest_path"
    cp "$src_path/userApiKey.json" "$src_path/userData.json" "$dest_path/" 2>/dev/null \
        && echo -e "${GREEN}✅ Backup restored to $dest_path${NC}" \
        || echo -e "${RED}❌ Backup files not found!${NC}"
}

# --- Function: Gensyn Fixed Run ---
gensyn_fixed_run() {
    if ! tmux has-session -t GEN 2>/dev/null; then
        tmux new-session -d -s GEN
    fi

    CORE_RUN_COMMANDS="cd \"${HOME}/rl-swarm\" && python3 -m venv .venv && source .venv/bin/activate && pip install --force-reinstall transformers==4.51.3 trl==0.19.1 && bash run_rl_swarm.sh; exec bash"
    for i in 1 2 3; do
        tmux send-keys -t GEN "$CORE_RUN_COMMANDS" C-m
        sleep 5
    done
    tmux attach-session -t GEN
}

# --- Main Menu Loop ---
while true; do
    print_header
    echo -e "${YELLOW}${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${BOLD}║      🔵 BENGAL AIRDROP GENSYN MENU 🔵        ║${NC}"
    echo -e "${YELLOW}${BOLD}╠══════════════════════════════════════════════╣${NC}"
    echo -e "${YELLOW}${BOLD}║ [1] 📦 Install All Dependencies              ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [2] 🚀 Start GEN Tmux Session                ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [3] 🔐 Start LOC Tmux Session                ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [4] 📂 Move swarm.pem to rl-swarm/           ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [5] ⬇️ Download swarm.pem from Google Drive  ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [6] 🔍 Check GEN Session Status              ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [7] 💾 Save Login Data (Backup)              ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [8] ♻️ Restore Login Data (Backup)            ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [9] 🛠️ GENSYN FIXED RUN (3 Times)            ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [0] 👋 Exit Script                           ║${NC}"
    echo -e "${YELLOW}${BOLD}╚══════════════════════════════════════════════╝"

    read -p "👉 Enter your choice [0-9]: " choice
    case $choice in
        1) install_dependencies ;;
        2) start_gen_session ;;
        3) start_loc_session ;;
        4) move_swarm_pem ;;
        5) download_swarm_pem ;;
        6) check_gen_session_status ;;
        7) save_login_data ;;
        8) restore_login_data ;;
        9) gensyn_fixed_run ;;
        0) exit 0 ;;
        *) echo -e "${RED}❌ Invalid option!${NC}" ;;
    esac
    read -p "Press Enter to continue..."
done
