#!/bin/bash

# Color codes (Re-using the successful palette from previous scripts)
YELLOW='\033[1;33m'     # Bold Yellow
BOLD='\033[1m'          # General Bold
CYAN='\033[1;36m'       # Bold Cyan
GREEN='\033[1;32m'      # Bold Green
PINK='\033[38;5;198m'   # Deep Pink (Using 256-color code for specific shade)
RED='\033[1;31m'        # Bold Red
MAGENTA='\033[1;35m'    # Bold Magenta (For helper messages/special info)
NC='\033[0m'            # No Color

# --- Function to print the main header ---
print_header() {
    clear # Clear screen to ensure header is always at the top
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

# --- Function: Start GEN tmux session (Gensyn Node) ---
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

# --- Function: Start LOC tmux session (Firewall + Tunnel) ---
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

# --- Function: Move swarm.pem to rl-swarm/ ---
move_swarm_pem() {
    echo -e "${GREEN}========== STEP 4: MOVE SWARM.PEM ==========${NC}"
    echo -e "${CYAN}📂 Moving swarm.pem to rl-swarm/ directory...${NC}"
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

# --- Function: Check if GEN session is running ---
check_gen_session_status() {
    echo -e "${GREEN}========== STEP 5: CHECK GEN SESSION STATUS ==========${NC}"
    echo -e "${CYAN}🔍 Checking GEN tmux session status...${NC}"
    if tmux has-session -t GEN 2>/dev/null; then
        echo -e "${GREEN}✅ GEN session is running.${NC}"
    else
        echo -e "${RED}❌ GEN session is NOT running.${NC}"
    fi
    return 0
}

# --- Function: Save login data (Backup userApiKey.json & userData.json) ---
save_login_data() {
    echo -e "${GREEN}========== STEP 6: SAVE LOGIN DATA (BACKUP) ==========${NC}"
    echo -e "${CYAN}📦 Saving login data...${NC}"
    src_path="${HOME}/rl-swarm/modal-login/temp-data"
    dest_path="${HOME}/rl-swarm/backup-login"

    if [[ -f "$src_path/userApiKey.json" && -f "$src_path/userData.json" ]]; then
        mkdir -p "$dest_path"
        if cp "$src_path/userApiKey.json" "$dest_path/" && cp "$src_path/userData.json" "$dest_path/"; then
            echo -e "${GREEN}✅ Login data backed up to: ${BOLD}${dest_path}${NC}${GREEN}!${NC}"
        else
            echo -e "${RED}❌ Failed to copy login data. Check permissions or paths.${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Login data files not found in ${BOLD}${src_path}${NC}${RED}!${NC}"
        return 1
    fi
    return 0
}

# --- Function: Restore login data (Bring back userApiKey.json & userData.json) ---
restore_login_data() {
    echo -e "${GREEN}========== STEP 7: RESTORE LOGIN DATA (BACKUP) ==========${NC}"
    echo -e "${CYAN}♻️ Restoring login data...${NC}"
    src_path="${HOME}/rl-swarm/backup-login"
    dest_path="${HOME}/rl-swarm/modal-login/temp-data"

    if [[ -f "$src_path/userApiKey.json" && -f "$src_path/userData.json" ]]; then
        mkdir -p "$dest_path"
        if cp "$src_path/userApiKey.json" "$dest_path/" && cp "$src_path/userData.json" "$dest_path/"; then
            echo -e "${GREEN}✅ Login data restored to: ${BOLD}${dest_path}${NC}${GREEN}!${NC}"
        else
            echo -e "${RED}❌ Failed to copy backup files. Check permissions or paths.${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Backup files not found in ${BOLD}${src_path}${NC}${RED}!${NC}"
        echo -e "${YELLOW}Please ensure you have previously saved login data using Option 6.${NC}"
        return 1
    fi
    return 0
}

# --- Function: GENSYN FIXED RUN ---
gensyn_fixed_run() {
    echo -e "${GREEN}========== STEP 8: GENSYN FIXED RUN (3 TIMES) ==========${NC}"
    echo -e "${CYAN}🚀 GENSYN FIXED RUN started in GEN tmux session, running 3 times...${NC}"

    if ! tmux has-session -t GEN 2>/dev/null; then
        echo -e "${MAGENTA}🛠️ GEN session not found. Creating a new one...${NC}"
        tmux new-session -d -s GEN || { echo -e "${RED}❌ Failed to create GEN session.${NC}"; return 1; }
    else
        echo -e "${YELLOW}⚠️ GEN session already exists. Using existing session...${NC}"
    fi

    for i in 1 2 3; do
        echo -e "${CYAN}🔄 Run #${BOLD}${i}${NC}${CYAN} of 3...${NC}"
        tmux send-keys -t GEN "cd ${HOME}/rl-swarm" C-m
        
        tmux send-keys -t GEN "python3 -m venv .venv" C-m
        tmux send-keys -t GEN "source .venv/bin/activate" C-m
        tmux send-keys -t GEN "pip install --force-reinstall transformers==4.51.3 trl==0.19.1" C-m
        tmux send-keys -t GEN "pip freeze" C-m
        tmux send-keys -t GEN "bash run_rl_swarm.sh" C-m
        
        if [ "$i" -lt 3 ]; then
            echo -e "${CYAN}Waiting for 5 seconds before next run...${NC}"
            sleep 5
        fi
    done

    echo -e "${GREEN}✅ All 3 GENSYN FIXED RUN iterations initiated.${NC}"
    echo -e "${CYAN}Attaching to GEN session to monitor output. Press Ctrl+b then d to detach.${NC}"
    sleep 1 # Give tmux a moment
    tmux attach-session -t GEN
    return 0
}


# --- Main Menu Loop ---
while true; do
    print_header # Display the main header
    echo -e "${YELLOW}${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${BOLD}║      🔵 BENGAL AIRDROP GENSYN MENU 🔵    ║${NC}" # Updated Menu Title
    echo -e "${YELLOW}${BOLD}╠══════════════════════════════════════════════╣${NC}"
    echo -e "${YELLOW}${BOLD}║ [${YELLOW}1${NC}${BOLD}] ${PINK}📦 Install All Dependencies               ${YELLOW}${BOLD}  ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [${YELLOW}2${NC}${BOLD}] ${PINK}🚀 Start GEN Tmux Session (Gensyn Node)  ${YELLOW}${BOLD}  ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [${YELLOW}3${NC}${BOLD}] ${PINK}🔐 Start LOC Tmux Session (Firewall+Tunnel) ${YELLOW}${BOLD}  ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [${YELLOW}4${NC}${BOLD}] ${PINK}📂 Move swarm.pem to rl-swarm/           ${YELLOW}${BOLD}  ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [${YELLOW}5${NC}${BOLD}] ${PINK}🔍 Check GEN Session Status             ${YELLOW}${BOLD}  ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [${YELLOW}6${NC}${BOLD}] ${PINK}💾 Save Login Data (Backup)             ${YELLOW}${BOLD}  ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [${YELLOW}7${NC}${BOLD}] ${PINK}♻️ Restore Login Data (Backup)           ${YELLOW}${BOLD}  ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [${YELLOW}8${NC}${BOLD}] ${PINK}🛠️ GENSYN FIXED RUN (3 Times)          ${YELLOW}${BOLD}  ║${NC}"
    echo -e "${YELLOW}${BOLD}║ [${YELLOW}0${NC}${BOLD}] ${PINK}👋 Exit Script                           ${YELLOW}${BOLD}  ║${NC}"
    echo -e "${YELLOW}${BOLD}╚══════════════════════════════════════════════╝${NC}"
    echo -e "" # Add a new line for better spacing

    read -p "${PINK}👉 Enter your choice [0-8]: ${NC}" choice
    case $choice in
        1) install_dependencies ;;
        2) start_gen_session ;;
        3) start_loc_session ;;
        4) move_swarm_pem ;;
        5) check_gen_session_status ;;
        6) save_login_data ;;
        7) restore_login_data ;;
        8) gensyn_fixed_run ;;
        0) echo -e "${CYAN}🚪 Exiting... Goodbye! 👋${NC}"; exit 0 ;;
        *) echo -e "${RED}❌ Invalid option! Please enter a number between 0-8.${NC}";;
    esac
    echo -e "" # Add extra space before next menu refresh
    read -p "${CYAN}Press Enter to continue...${NC}" # Consistent pause
done
