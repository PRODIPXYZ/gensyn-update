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
    echo -e "${CYAN}📩 DM on Telegram    : @prodipgo${NC}"
    echo -e ""
}

# --- Function: Install all dependencies ---
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

# --- Function: Start GEN tmux session ---
start_gen_session() {
    echo -e "${GREEN}========== STEP 2: START GEN TMUX SESSION ==========${NC}"
    if tmux has-session -t GEN 2>/dev/null; then
        echo -e "${YELLOW}⚠️ GEN session already exists. Attaching to existing session...${NC}"
    else
        echo -e "${CYAN}🚀 Creating GEN session and running Gensyn node...${NC}"
        tmux new-session -d -s GEN "bash -c '
            cd \$HOME &&
            rm -rf gensyn-testnet &&
            git clone https://github.com/zunxbt/gensyn-testnet.git &&
            chmod +x gensyn-testnet/gensyn.sh &&
            ./gensyn-testnet/gensyn.sh;
            exec bash
        '"
        echo -e "${GREEN}✅ GEN session started! Attaching...${NC}"
    fi
    sleep 1
    tmux attach-session -t GEN
    return 0
}

# --- Function: Start LOC tmux session ---
start_loc_session() {
    echo -e "${GREEN}========== STEP 3: START LOC TMUX SESSION ==========${NC}"
    if tmux has-session -t LOC 2>/dev/null; then
        echo -e "${YELLOW}⚠️ LOC session already exists. Attaching to existing session...${NC}"
    else
        echo -e "${CYAN}🔐 Starting LOC session (Firewall + Cloudflare Tunnel)...${NC}"
        tmux new-session -d -s LOC "bash -c '
            echo \"Configuring UFW firewall...\" &&
            sudo ufw allow 22 &&
            sudo ufw allow 3000/tcp &&
            echo y | sudo ufw enable &&
            echo \"Firewall configured.\" &&
            echo \"Installing Cloudflared...\" &&
            wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb &&
            sudo dpkg -i cloudflared-linux-amd64.deb &&
            echo \"Cloudflared installed.\" &&
            echo \"Starting Cloudflared tunnel...\" &&
            cloudflared tunnel --url http://localhost:3000;
            exec bash
        '"
        echo -e "${GREEN}✅ LOC session started! Attaching...${NC}"
    fi
    sleep 1
    tmux attach-session -t LOC
    return 0
}

# --- Function: Move local swarm.pem ---
move_swarm_pem_local() {
    echo -e "${GREEN}========== STEP 4: MOVE SWARM.PEM LOCALLY ==========${NC}"
    if [ -f "swarm.pem" ]; then
        mkdir -p rl-swarm
        if mv swarm.pem rl-swarm/; then
            echo -e "${GREEN}✅ swarm.pem moved successfully to rl-swarm/!${NC}"
        else
            echo -e "${RED}❌ Failed to move swarm.pem. Check permissions or path.${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ swarm.pem not found in the current directory!${NC}"
        return 1
    fi
    return 0
}

# --- Function: Setup & Download swarm.pem from Google Drive ---
move_swarm_pem_gdrive() {
    echo -e "${GREEN}========== STEP 5: GOOGLE DRIVE SETUP + DOWNLOAD ==========${NC}"

    # Step 1: Install gdrive if not installed
    if ! command -v gdrive &>/dev/null; then
        echo -e "${CYAN}⬇️ Installing gdrive CLI...${NC}"
        sudo wget -O /usr/local/bin/gdrive https://github.com/prasmussen/gdrive/releases/download/2.1.1/gdrive-linux-x64
        sudo chmod +x /usr/local/bin/gdrive
        echo -e "${GREEN}✅ gdrive installed.${NC}"
    else
        echo -e "${GREEN}✅ gdrive already installed.${NC}"
    fi

    # Step 2: Authenticate gdrive if first time
    if ! gdrive list &>/dev/null; then
        echo -e "${CYAN}🔑 First-time gdrive authentication required...${NC}"
        gdrive list
        echo -e "${GREEN}✅ Authentication complete.${NC}"
    fi

    # Step 3: Ask for MY GENSYN folder ID
    read -p "${PINK}👉 Enter Google Drive MY GENSYN Folder ID: ${NC}" FOLDER_ID
    if [ -z "$FOLDER_ID" ]; then
        echo -e "${RED}❌ Folder ID cannot be empty!${NC}"
        return 1
    fi

    # Step 4: List subfolders
    mapfile -t folders < <(gdrive list --query "'$FOLDER_ID' in parents and mimeType='application/vnd.google-apps.folder'" --no-header | awk '{print $2}')
    if [ ${#folders[@]} -eq 0 ]; then
        echo -e "${RED}❌ No folders found in MY GENSYN folder!${NC}"
        return 1
    fi

    echo -e "${YELLOW}Available folders:${NC}"
    for i in "${!folders[@]}"; do
        echo -e "${CYAN}$((i+1))) ${folders[$i]}${NC}"
    done

    read -p "${PINK}👉 Enter folder number to download swarm.pem from: ${NC}" choice
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#folders[@]}" ]; then
        echo -e "${RED}❌ Invalid choice!${NC}"
        return 1
    fi

    CHOSEN_FOLDER="${folders[$((choice-1))]}"
    FILE_ID=$(gdrive list --query "'$CHOSEN_FOLDER' in parents" --no-header | grep -i swarm.pem | awk '{print $1}')
    if [ -z "$FILE_ID" ]; then
        echo -e "${RED}❌ swarm.pem not found in selected folder!${NC}"
        return 1
    fi

    mkdir -p "$HOME/rl-swarm"
    echo -e "${CYAN}⬇️ Downloading swarm.pem to rl-swarm...${NC}"
    if gdrive download "$FILE_ID" --path "$HOME/rl-swarm/" &>/dev/null; then
        echo -e "${GREEN}✅ swarm.pem downloaded successfully to ${BOLD}$HOME/rl-swarm/${NC}"
    else
        echo -e "${RED}❌ Failed to download swarm.pem.${NC}"
        return 1
    fi
}

# --- Placeholder for other functions (check_gen_session_status, save_login_data, restore_login_data, gensyn_fixed_run) ---
# Copy the previous implementations here

# --- Main Menu Loop ---
while true; do
    print_header
    echo -e "${YELLOW}${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${BOLD}║      🔵 BENGAL AIRDROP GENSYN MENU 🔵    ║${NC}"
    echo -e "${YELLOW}${BOLD}╠══════════════════════════════════════════════╣${NC}"
    echo -e "${YELLOW}${BOLD}║ [${YELLOW}1${NC}${BOLD}] 📦 Install All Dependencies             ${YELLOW}${BOLD}  ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [${YELLOW}2${NC}${BOLD}] 🚀 Start GEN Tmux Session               ${YELLOW}${BOLD}  ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [${YELLOW}3${NC}${BOLD}] 🔐 Start LOC Tmux Session               ${YELLOW}${BOLD}  ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [${YELLOW}4${NC}${BOLD}] 📂 Move swarm.pem locally                ${YELLOW}${BOLD}  ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [${YELLOW}5${NC}${BOLD}] ⬇️ Download swarm.pem from Google Drive ${YELLOW}${BOLD}  ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [${YELLOW}6${NC}${BOLD}] 🔍 Check GEN Session Status             ${YELLOW}${BOLD}  ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [${YELLOW}7${NC}${BOLD}] 💾 Save Login Data (Backup)             ${YELLOW}${BOLD}  ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [${YELLOW}8${NC}${BOLD}] ♻️ Restore Login Data (Backup)           ${YELLOW}${BOLD}  ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [${YELLOW}9${NC}${BOLD}] 🛠️ GENSYN FIXED RUN (3 Times)          ${YELLOW}${BOLD}  ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [${YELLOW}0${NC}${BOLD}] 👋 Exit Script                           ${YELLOW}${BOLD}  ║${NC}"
    echo -e "${YELLOW}${BOLD}╚══════════════════════════════════════════════╝${NC}"
    echo -e ""

    read -p "${PINK}👉 Enter your choice [0-9]: ${NC}" choice
    case $choice in
        1) install_dependencies ;;
        2) start_gen_session ;;
        3) start_loc_session ;;
        4) move_swarm_pem_local ;;
        5) move_swarm_pem_gdrive ;;
        6) check_gen_session_status ;;
        7) save_login_data ;;
        8) restore_login_data ;;
        9) gensyn_fixed_run ;;
        0) echo -e "${CYAN}🚪 Exiting... Goodbye! 👋${NC}"; exit 0 ;;
        *) echo -e "${RED}❌ Invalid option! Please enter a number between 0-9.${NC}" ;;
    esac
    echo -e ""
    read -p "${CYAN}Press Enter to continue...${NC}"
done
