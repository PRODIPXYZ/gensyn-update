#!/bin/bash

# ---------- Color Codes ----------
YELLOW='\033[1;33m'
BOLD='\033[1m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m'

# ---------- Directories ----------
BASE_DIR="$HOME/rl-swarm"
TEMP_DIR="$BASE_DIR/modal-login/temp-data"
VENVDIR="$HOME/gensyn_venv"

# ---------- Header ----------
print_header() {
    clear
    echo -e "${YELLOW}${BOLD}=====================================================${NC}"
    echo -e "${YELLOW}${BOLD} # # # # # 🟡 BENGAL AIRDROP GENSYN 🟡 # # # # #${NC}"
    echo -e "${YELLOW}${BOLD} # # # # # #    MADE BY PRODIP    # # # # # #${NC}"
    echo -e "${YELLOW}${BOLD}=====================================================${NC}"
    echo -e "${CYAN}🌐 Follow on Twitter : https://x.com/prodipmandal10${NC}"
    echo -e "${CYAN}📩 DM on Telegram    : @prodipgo${NC}"
    echo -e ""
}

# ---------- Install dependencies ----------
install_dependencies() {
    echo -e "${GREEN}Installing system packages...${NC}"
    sudo apt update
    sudo apt install -y sudo tmux python3 python3-pip python3-venv python3-distutils curl wget git lsof ufw screen gnupg
}

# ---------- Start GEN Tmux ----------
start_gen_session() {
    if tmux has-session -t GEN 2>/dev/null; then
        echo -e "${YELLOW}GEN session already exists.${NC}"
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

# ---------- Start LOC Tmux ----------
start_loc_session() {
    if tmux has-session -t LOC 2>/dev/null; then
        echo -e "${YELLOW}LOC session already exists.${NC}"
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

# ---------- Move existing swarm.pem ----------
move_swarm_pem() {
    if [ -f "swarm.pem" ]; then
        mkdir -p "$BASE_DIR"
        mv swarm.pem "$BASE_DIR/"
        echo -e "${GREEN}✅ swarm.pem moved successfully!${NC}"
    else
        echo -e "${RED}❌ swarm.pem not found!${NC}"
    fi
}

# ---------- Download swarm.pem from Google Drive (MODIFIED) ----------
download_swarm_pem() {
    # Check for venv and create if it doesn't exist
    if [ ! -d "$VENVDIR" ]; then
        echo -e "${CYAN}⚡ Creating virtual environment for gdown...${NC}"
        # This will create the venv and handle missing dependencies
        python3 -m venv "$VENVDIR" || {
            echo -e "${RED}❌ Failed to create virtual environment. Trying to install missing dependencies...${NC}"
            sudo apt update
            sudo apt install -y python3-venv python3-distutils
            python3 -m venv "$VENVDIR"
        }
    fi
    
    # Check if venv was created successfully
    if [ ! -d "$VENVDIR" ]; then
        echo -e "${RED}❌ Virtual environment could not be created. Exiting.${NC}"
        return 1
    fi

    # Activate venv
    source "$VENVDIR/bin/activate"

    # Install gdown inside venv
    echo -e "${CYAN}Installing gdown package...${NC}"
    pip install --upgrade pip --quiet
    pip install gdown --quiet

    # Ask for Google Drive Folder ID or URL
    read -p "👉 Enter Google Drive Folder ID or URL: " FOLDER

    TMPDIR="gdrive_temp"
    mkdir -p "$TMPDIR" && cd "$TMPDIR"

    echo -e "${CYAN}📂 Listing files in folder...${NC}"
    # Try with both --folder and --url flags for better compatibility
    gdown --folder "$FOLDER" --quiet --dry-run || gdown --url "$FOLDER" --quiet --dry-run
    
    echo -e "${CYAN}⬇️ Downloading swarm.pem ...${NC}"
    gdown --folder "$FOLDER" --fuzzy --quiet || gdown --url "$FOLDER" --fuzzy --quiet

    if [ -f "swarm.pem" ]; then
        mkdir -p "$BASE_DIR"
        mv swarm.pem "$BASE_DIR/"
        echo -e "${GREEN}✅ swarm.pem downloaded & moved to $BASE_DIR/${NC}"
    else
        echo -e "${RED}❌ swarm.pem not found in folder!${NC}"
    fi

    cd ..
    deactivate
}

# ---------- Check GEN session ----------
check_gen_session_status() {
    if tmux has-session -t GEN 2>/dev/null; then
        echo -e "${GREEN}✅ GEN session is running.${NC}"
    else
        echo -e "${RED}❌ GEN session is NOT running.${NC}"
    fi
}

# ---------- Backup login data ----------
save_login_data() {
    SRC="$TEMP_DIR"
    DEST="$BASE_DIR/backup-login"
    mkdir -p "$DEST"
    cp "$SRC/userApiKey.json" "$SRC/userData.json" "$DEST/" 2>/dev/null \
        && echo -e "${GREEN}✅ Backup saved in $DEST${NC}" \
        || echo -e "${RED}❌ Login data not found!${NC}"
}

# ---------- Restore login data ----------
restore_login_data() {
    SRC="$BASE_DIR/backup-login"
    DEST="$TEMP_DIR"
    mkdir -p "$DEST"
    cp "$SRC/userApiKey.json" "$SRC/userData.json" "$DEST/" 2>/dev/null \
        && echo -e "${GREEN}✅ Backup restored to $DEST${NC}" \
        || echo -e "${RED}❌ Backup files not found!${NC}"
}

# ---------- Gensyn Fixed Run ----------
gensyn_fixed_run() {
    if ! tmux has-session -t GEN 2>/dev/null; then
        tmux new-session -d -s GEN
    fi

    CORE_RUN_COMMANDS="
        cd \"$BASE_DIR\" &&
        python3 -m venv .venv &&
        source .venv/bin/activate &&
        pip install --force-reinstall transformers==4.51.3 trl==0.19.1 &&
        bash run_rl_swarm.sh;
        exec bash
    "
    for i in 1 2 3; do
        tmux send-keys -t GEN "$CORE_RUN_COMMANDS" C-m
        sleep 5
    done
    tmux attach-session -t GEN
}

# ---------- Main Menu ----------
while true; do
    print_header
    echo -e "${YELLOW}${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${BOLD}║      🔵 BENGAL AIRDROP GENSYN MENU 🔵        ║${NC}"
    echo -e "${YELLOW}${BOLD}╠══════════════════════════════════════════════╣${NC}"
    echo -e "${YELLOW}${BOLD}║ [1] 📦 Install All Dependencies              ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [2] 🚀 Start GEN Tmux Session                ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [3] 🔐 Start LOC Tmux Session                ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [4] 📂 Move swarm.pem to rl-swarm/           ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [5] ⬇️ Download swarm.pem from Google Drive ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [6] 🔍 Check GEN Session Status              ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [7] 💾 Save Login Data (Backup)              ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [8] ♻️ Restore Login Data (Backup)            ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [9] 🛠️ GENSYN FIXED RUN (3 Times)            ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [0] 👋 Exit Script                           ║${NC}"
    echo -e "${YELLOW}${BOLD}╚══════════════════════════════════════════════╝${NC}"

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
