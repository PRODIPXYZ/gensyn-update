#!/bin/bash

# ---------- Colors ----------
YELLOW='\033[1;33m'     
BOLD='\033[1m'          
CYAN='\033[1;36m'       
GREEN='\033[1;32m'      
PINK='\033[38;5;198m'   
RED='\033[1;31m'        
MAGENTA='\033[1;35m'    
NC='\033[0m'            

# ---------- Header ----------
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

# ---------- Install dependencies ----------
install_dependencies() {
    echo -e "${GREEN}========== STEP 1: INSTALL DEPENDENCIES ==========${NC}"

    # Basic packages
    sudo apt update && sudo apt install -y sudo tmux python3 python3-venv python3-pip curl wget screen git lsof ufw gnupg unzip

    # Yarn installation
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/yarn.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list >/dev/null
    sudo apt update && sudo apt install -y yarn

    # Node.js v20
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs

    echo -e "${GREEN}✅ All dependencies installed (Python, Node.js v20, Yarn, etc.)!${NC}"
}

# ---------- Start GEN session ----------
start_gen_session() {
    echo -e "${GREEN}========== STEP 2: START GEN SESSION ==========${NC}"
    if tmux has-session -t GEN 2>/dev/null; then
        echo -e "${YELLOW}⚠️ GEN session exists. Attaching...${NC}"
    else
        tmux new-session -d -s GEN "bash -c '
            cd \$HOME &&
            rm -rf gensyn-testnet &&
            git clone https://github.com/zunxbt/gensyn-testnet.git &&
            chmod +x gensyn-testnet/gensyn.sh &&
            ./gensyn-testnet/gensyn.sh;
            exec bash
        '"
        echo -e "${GREEN}✅ GEN session started!${NC}"
    fi
    tmux attach-session -t GEN
}

# ---------- Start LOC session ----------
start_loc_session() {
    echo -e "${GREEN}========== STEP 3: START LOC SESSION ==========${NC}"
    if tmux has-session -t LOC 2>/dev/null; then
        echo -e "${YELLOW}⚠️ LOC session exists. Attaching...${NC}"
    else
        tmux new-session -d -s LOC "bash -c '
            sudo ufw allow 22
            sudo ufw allow 3000/tcp
            echo y | sudo ufw enable
            wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
            sudo dpkg -i cloudflared-linux-amd64.deb
            cloudflared tunnel --url http://localhost:3000
            exec bash
        '"
        echo -e "${GREEN}✅ LOC session started!${NC}"
    fi
    tmux attach-session -t LOC
}

# ---------- Move swarm.pem ----------
move_swarm_pem() {
    echo -e "${GREEN}========== STEP 4: MOVE SWARM.PEM ==========${NC}"
    if [ -f "swarm.pem" ]; then
        mkdir -p "$HOME/rl-swarm"
        mv -f swarm.pem "$HOME/rl-swarm/"
        echo -e "${GREEN}✅ swarm.pem moved to $HOME/rl-swarm/${NC}"
    else
        echo -e "${RED}❌ swarm.pem not found!${NC}"
    fi
}

# ---------- Check GEN session ----------
check_gen_session_status() {
    echo -e "${GREEN}========== STEP 5: CHECK GEN SESSION ==========${NC}"
    if tmux has-session -t GEN 2>/dev/null; then
        echo -e "${GREEN}✅ GEN session running.${NC}"
    else
        echo -e "${RED}❌ GEN session NOT running.${NC}"
    fi
}

# ---------- Save login data ----------
save_login_data() {
    echo -e "${GREEN}========== STEP 6: SAVE LOGIN DATA ==========${NC}"
    src="$HOME/rl-swarm/modal-login/temp-data"
    dest="$HOME/rl-swarm/backup-login"
    if [[ -d "$src" ]]; then
        mkdir -p "$dest"
        cp -r "$src" "$dest/"
        echo -e "${GREEN}✅ temp-data backed up to $dest${NC}"
    else
        echo -e "${RED}❌ temp-data not found in $src${NC}"
    fi
}

# ---------- Restore login data ----------
restore_login_data() {
    echo -e "${GREEN}========== STEP 7: RESTORE LOGIN DATA ==========${NC}"
    src="$HOME/rl-swarm/backup-login/temp-data"
    dest="$HOME/rl-swarm/modal-login/"
    if [[ -d "$src" ]]; then
        mkdir -p "$dest"
        rm -rf "$dest/temp-data"
        cp -r "$src" "$dest/"
        echo -e "${GREEN}✅ temp-data restored to $dest${NC}"
    else
        echo -e "${RED}❌ Backup temp-data not found!${NC}"
    fi
}

# ---------- GENSYN FIXED RUN ----------
gensyn_fixed_run() {
    echo -e "${GREEN}========== STEP 8: GENSYN FIXED RUN ==========${NC}"
    if ! tmux has-session -t GEN 2>/dev/null; then
        tmux new-session -d -s GEN
    fi
    CORE_RUN="
        cd $HOME/rl-swarm
        python3 -m venv .venv
        source .venv/bin/activate
        pip install --force-reinstall transformers==4.51.3 trl==0.19.1
        bash run_rl_swarm.sh
        exec bash
    "
    for i in 1 2 3; do
        tmux send-keys -t GEN "$CORE_RUN" C-m
        sleep 5
    done
    tmux attach-session -t GEN
}

# ---------- Option 9: Download & Extract swarm.pem (venv + cached) ----------
download_extract_swarm() {
    echo -e "${GREEN}========== STEP 9: DOWNLOAD & EXTRACT SWARM.PEM ==========${NC}"

    DOWNLOAD_DIR="$HOME/pipe_downloads"
    mkdir -p "$DOWNLOAD_DIR"

    # Virtual environment path
    VENV_DIR="$HOME/rl-swarm/.venv"
    if [ ! -d "$VENV_DIR" ]; then
        echo -e "${CYAN}🔧 Creating Python virtual environment...${NC}"
        python3 -m venv "$VENV_DIR"
    fi

    source "$VENV_DIR/bin/activate"

    # Install gdown inside venv
    echo -e "${CYAN}📦 Installing gdown in venv...${NC}"
    pip install --upgrade gdown

    # Ask for Drive link only if temp.zip does not exist
    ZIP_FILE="$DOWNLOAD_DIR/temp.zip"
    if [ ! -f "$ZIP_FILE" ]; then
        read -p "🔗 Enter Google Drive zip link: " ZIP_LINK
        ZIP_ID=$(echo "$ZIP_LINK" | grep -oP '(?<=/d/)[^/]+')
        echo -e "⚙️ Downloading zip file..."
        python -m gdown "https://drive.google.com/uc?id=$ZIP_ID" -O "$ZIP_FILE"
    else
        echo -e "⚠️ Zip file already downloaded. Using cached copy: $ZIP_FILE"
    fi

    EXTRACT_DIR="$DOWNLOAD_DIR/extracted"
    mkdir -p "$EXTRACT_DIR"
    unzip -o "$ZIP_FILE" -d "$EXTRACT_DIR"

    # Show folders with emoji + bold yellow
    echo -e "${YELLOW}${BOLD}📂 Extracted folders:${NC}"
    folders=()
    i=1
    for f in "$EXTRACT_DIR"/*/; do
        [ -d "$f" ] || continue
        folders+=("$f")
        echo -e "${YELLOW}${BOLD}$i) 📁 $(basename "$f")${NC}"
        ((i++))
    done

    read -p "👉 Enter folder number to move swarm.pem from: " sel
    SEL_FOLDER="${folders[$((sel-1))]}"

    if [ -f "$SEL_FOLDER/swarm.pem" ]; then
        mkdir -p "$HOME/rl-swarm"
        mv -f "$SEL_FOLDER/swarm.pem" "$HOME/rl-swarm/"
        echo -e "${GREEN}✅ swarm.pem moved to $HOME/rl-swarm/${NC}"
    else
        echo -e "${RED}❌ swarm.pem not found in selected folder!${NC}"
    fi

    # copy temp-data if exists
    if [ -d "$SEL_FOLDER/temp-data" ]; then
        DEST="$HOME/rl-swarm/modal-login/"
        mkdir -p "$DEST"
        rm -rf "$DEST/temp-data"
        cp -r "$SEL_FOLDER/temp-data" "$DEST/"
        echo -e "${GREEN}✅ temp-data copied to $DEST${NC}"
    fi

    deactivate
}

# ---------- Option 10: Move existing temp-data ----------
move_temp_data() {
    SRC="$HOME/rl-swarm/modal-login/temp-data"
    DEST="$HOME/rl-swarm/modal-login/"
    if [ -d "$SRC" ]; then
        rm -rf "$DEST/temp-data"
        cp -r "$SRC" "$DEST/"
        echo -e "${GREEN}✅ temp-data moved to modal-login${NC}"
    else
        echo -e "${RED}❌ temp-data not found!${NC}"
    fi
}

# ---------- Main menu ----------
while true; do
    print_header
    echo -e "${YELLOW}${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${BOLD}║      🔵 BENGAL AIRDROP GENSYN MENU 🔵    ║${NC}"
    echo -e "${YELLOW}${BOLD}╠══════════════════════════════════════════════╣${NC}"
    echo -e "${YELLOW}${BOLD}║ [1] 📦 Install All Dependencies                 ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [2] 🚀 Start GEN Tmux Session (Gensyn Node)    ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [3] 🔐 Start LOC Tmux Session (Firewall+Tunnel) ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [4] 📂 Move swarm.pem to rl-swarm/             ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [5] 🔍 Check GEN Session Status               ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [6] 💾 Save Login Data (Backup)               ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [7] ♻️ Restore Login Data (Backup)             ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [8] 🛠️ GENSYN FIXED RUN (3 Times)            ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [9] 📥 Download, Extract & Move swarm.pem     ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [10] 📂 Move temp-data to modal-login          ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [0] 👋 Exit Script                             ║${NC}"
    echo -e "${YELLOW}${BOLD}╚══════════════════════════════════════════════╝${NC}"

    read -p "${PINK}👉 Enter your choice [0-10]: ${NC}" choice
    case $choice in
        1) install_dependencies ;;
        2) start_gen_session ;;
        3) start_loc_session ;;
        4) move_swarm_pem ;;
        5) check_gen_session_status ;;
        6) save_login_data ;;
        7) restore_login_data ;;
        8) gensyn_fixed_run ;;
        9) download_extract_swarm ;;
        10) move_temp_data ;;
        0) echo -e "${CYAN}🚪 Exiting... Bye!${NC}"; exit 0 ;;
        *) echo -e "${RED}❌ Invalid choice!${NC}" ;;
    esac
    read -p "${CYAN}Press Enter to continue...${NC}"
done
