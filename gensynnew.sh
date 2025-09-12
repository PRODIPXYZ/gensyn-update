#!/bin/bash

# ================= COLOR CODES =================
YELLOW='\033[1;33m'
BOLD='\033[1m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
PINK='\033[38;5;198m'
RED='\033[1;31m'
MAGENTA='\033[1;35m'
NC='\033[0m'

# ================= HEADER =================
print_header() {
    clear
    echo -e "${YELLOW}${BOLD}=====================================================${NC}"
    echo -e "${YELLOW}${BOLD} # # # # # 🟡 BENGAL AIRDROP GENSYN 🟡 # # # # #${NC}"
    echo -e "${YELLOW}${BOLD} # # # # # #   MADE BY PRODIP   # # # # # #${NC}"
    echo -e "${YELLOW}${BOLD}=====================================================${NC}"
    echo -e "${CYAN}🌐 Follow on Twitter : https://x.com/prodipmandal10${NC}"
    echo -e "${CYAN}📩 DM on Telegram    : @prodipgo${NC}"
    echo ""
}

# ================= FUNCTIONS =================

install_dependencies() {
    echo -e "${GREEN}========== STEP 1: INSTALL ALL DEPENDENCIES ==========${NC}"
    echo -e "${CYAN}🔧 Installing dependencies...${NC}"
    sudo apt update && sudo apt install -y sudo tmux python3 python3-venv python3-pip curl wget screen git lsof ufw gnupg
    echo -e "${CYAN}📦 Installing Yarn...${NC}"
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/yarn.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list >/dev/null
    sudo apt update && sudo apt install -y yarn
    echo -e "${CYAN}🚀 Running Gensyn node setup script from ABHIEBA...${NC}"
    if curl -sSL https://raw.githubusercontent.com/ABHIEBA/Gensyn/main/node.sh | bash; then
        echo -e "${GREEN}✅ Gensyn node setup script completed.${NC}"
    else
        echo -e "${RED}❌ Gensyn node setup script failed. Please check the output above.${NC}"
        return 1
    fi
    echo -e "${GREEN}✅ All dependencies installed!${NC}"
    return 0
}

start_gen_session() {
    echo -e "${GREEN}========== STEP 2: START GEN TMUX SESSION ==========${NC}"
    if tmux has-session -t GEN 2>/dev/null; then
        echo -e "${YELLOW}⚠️ GEN session already exists. Attaching...${NC}"
    else
        echo -e "${CYAN}🚀 Creating GEN session...${NC}"
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
    sleep 1
    tmux attach-session -t GEN
    return 0
}

start_loc_session() {
    echo -e "${GREEN}========== STEP 3: START LOC TMUX SESSION ==========${NC}"
    if tmux has-session -t LOC 2>/dev/null; then
        echo -e "${YELLOW}⚠️ LOC session already exists. Attaching...${NC}"
    else
        echo -e "${CYAN}🔐 Starting LOC session (Firewall + Tunnel)...${NC}"
        tmux new-session -d -s LOC "bash -c '
            echo \"Configuring UFW firewall...\" &&
            sudo ufw allow 22 &&
            sudo ufw allow 3000/tcp &&
            echo y | sudo ufw enable &&
            echo \"Installing Cloudflared...\" &&
            wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb &&
            sudo dpkg -i cloudflared-linux-amd64.deb &&
            cloudflared tunnel --url http://localhost:3000;
            exec bash
        '"
        echo -e "${GREEN}✅ LOC session started!${NC}"
    fi
    sleep 1
    tmux attach-session -t LOC
    return 0
}

move_swarm_pem() {
    echo -e "${GREEN}========== STEP 4: MOVE SWARM.PEM ==========${NC}"
    if [ -f "swarm.pem" ]; then
        mkdir -p rl-swarm
        mv swarm.pem rl-swarm/ && echo -e "${GREEN}✅ swarm.pem moved to rl-swarm/${NC}" || echo -e "${RED}❌ Failed to move swarm.pem${NC}"
    else
        echo -e "${RED}❌ swarm.pem not found!${NC}"
    fi
}

check_gen_session_status() {
    echo -e "${GREEN}========== STEP 5: CHECK GEN SESSION STATUS ==========${NC}"
    if tmux has-session -t GEN 2>/dev/null; then
        echo -e "${GREEN}✅ GEN session is running.${NC}"
    else
        echo -e "${RED}❌ GEN session is NOT running.${NC}"
    fi
}

save_login_data() {
    echo -e "${GREEN}========== STEP 6: SAVE LOGIN DATA ==========${NC}"
    src="$HOME/rl-swarm/modal-login/temp-data"
    dest="$HOME/rl-swarm/backup-login"
    mkdir -p "$dest"
    cp "$src/userApiKey.json" "$dest/" 2>/dev/null
    cp "$src/userData.json" "$dest/" 2>/dev/null
    echo -e "${GREEN}✅ Login data backed up to $dest${NC}"
}

restore_login_data() {
    echo -e "${GREEN}========== STEP 7: RESTORE LOGIN DATA ==========${NC}"
    src="$HOME/rl-swarm/backup-login"
    dest="$HOME/rl-swarm/modal-login/temp-data"
    mkdir -p "$dest"
    cp "$src/userApiKey.json" "$dest/" 2>/dev/null
    cp "$src/userData.json" "$dest/" 2>/dev/null
    echo -e "${GREEN}✅ Login data restored to $dest${NC}"
}

gensyn_fixed_run() {
    echo -e "${GREEN}========== STEP 8: GENSYN FIXED RUN (3 TIMES) ==========${NC}"
    if ! tmux has-session -t GEN 2>/dev/null; then
        tmux new-session -d -s GEN
    fi
    CORE_RUN="set -e && cd \$HOME/rl-swarm && python3 -m venv .venv && source .venv/bin/activate && pip install --force-reinstall transformers==4.51.3 trl==0.19.1 && bash run_rl_swarm.sh && exec bash"
    for i in 1 2 3; do
        echo -e "${CYAN}🔄 Run #$i${NC}"
        tmux send-keys -t GEN "$CORE_RUN" C-m
        [ $i -lt 3 ] && sleep 5
    done
    tmux attach-session -t GEN
}

# ================= STEP 9: DOWNLOAD + EXTRACT + MOVE =================
download_extract_move() {
    echo -e "${GREEN}========== STEP 9: DOWNLOAD & EXTRACT ZIP FILES ==========${NC}"
    if ! command -v gdown &> /dev/null; then
        echo -e "${CYAN}⚙️ Installing gdown...${NC}"
        python3 -m pip install --upgrade pip
        python3 -m pip install gdown
    fi

    BASE_DIR="$HOME/pipe_downloads"
    EXTRACT_DIR="$HOME/pipe_extracted"
    TARGET_DIR="$HOME/pipe_selected"
    mkdir -p "$BASE_DIR" "$EXTRACT_DIR" "$TARGET_DIR"

    declare -a links
    echo -e "${CYAN}🔢 Enter up to 5 Google Drive zip links. Press Enter to skip.${NC}"
    for i in {1..5}; do
        read -p "Link #$i: " link
        [ -z "$link" ] && break
        links+=("$link")
    done

    folder_index=1
    declare -A folder_map
    for link in "${links[@]}"; do
        zip_name="file_$folder_index.zip"
        gdown --fuzzy "$link" -O "$BASE_DIR/$zip_name"
        folder_name="$EXTRACT_DIR/$folder_index"
        mkdir -p "$folder_name"
        unzip -q "$BASE_DIR/$zip_name" -d "$folder_name"
        folder_map[$folder_index]="$folder_name"
        echo -e "${GREEN}✅ Extracted to folder $folder_index${NC}"
        ((folder_index++))
    done

    echo -e "${CYAN}📂 Available extracted folders:${NC}"
    for idx in "${!folder_map[@]}"; do
        echo "[$idx] ${folder_map[$idx]}"
    done

    read -p "Enter folder number to move to pipe_selected/: " sel
    if [[ -n "${folder_map[$sel]}" ]]; then
        mv "${folder_map[$sel]}" "$TARGET_DIR/"
        echo -e "${GREEN}✅ Folder moved to $TARGET_DIR/${NC}"
    else
        echo -e "${RED}❌ Invalid selection.${NC}"
    fi
}

# ================= MENU LOOP =================
while true; do
    print_header
    echo -e "${YELLOW}${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${BOLD}║ [1] ${PINK}📦 Install All Dependencies             ${YELLOW}${BOLD} ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [2] ${PINK}🚀 Start GEN Tmux Session               ${YELLOW}${BOLD} ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [3] ${PINK}🔐 Start LOC Tmux Session               ${YELLOW}${BOLD} ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [4] ${PINK}📂 Move swarm.pem                        ${YELLOW}${BOLD} ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [5] ${PINK}🔍 Check GEN Session Status             ${YELLOW}${BOLD} ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [6] ${PINK}💾 Save Login Data                       ${YELLOW}${BOLD} ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [7] ${PINK}♻️ Restore Login Data                    ${YELLOW}${BOLD} ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [8] ${PINK}🛠️ GENSYN FIXED RUN (3 Times)          ${YELLOW}${BOLD} ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [9] ${PINK}⬇️ Download & Extract Drive Zip          ${YELLOW}${BOLD} ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [0] ${PINK}👋 Exit Script                          ${YELLOW}${BOLD} ║${NC}"
    echo -e "${YELLOW}${BOLD}╚══════════════════════════════════════════════╝${NC}"

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
        9) download_extract_move ;;
        0) echo -e "${CYAN}🚪 Exiting... Goodbye!${NC}"; exit 0 ;;
        *) echo -e "${RED}❌ Invalid option!${NC}" ;;
    esac
    read -p "${CYAN}Press Enter to continue...${NC}"
done
