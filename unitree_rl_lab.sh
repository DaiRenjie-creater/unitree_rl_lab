#!/usr/bin/env bash
#
# ============================================================
#  Final Combined Unitree RL Lab Setup Script
#  - Original unitree_rl_lab.sh logic
#  - Environment auto repair (activate.d, setenv.sh, argcomplete)
#  - Safer, clearer, idempotent, colored
# ============================================================

# ---------- Color ----------
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
NC="\033[0m"

# ---------- Path ----------
export UNITREE_RL_LAB_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# ---------- Python in conda ----------
if [[ -n "${CONDA_PREFIX}" ]]; then
    python_exe="${CONDA_PREFIX}/bin/python"
else
    echo -e "${RED}[ERROR] No conda environment active.${NC}"
    echo "Please run: conda activate env_isaaclab"
    exit 1
fi

# ============================================================
#                   Auto-completion handler
# ============================================================
_ut_rl_lab_python_argcomplete_wrapper() {
    local IFS=$'\013'
    local SUPPRESS_SPACE=0
    compopt +o nospace 2>/dev/null && SUPPRESS_SPACE=1

    COMPREPLY=( $(IFS="$IFS" \
        COMP_LINE="$COMP_LINE" \
        COMP_POINT="$COMP_POINT" \
        COMP_TYPE="$COMP_TYPE" \
        _ARGCOMPLETE=1 \
        _ARGCOMPLETE_SUPPRESS_SPACE=$SUPPRESS_SPACE \
        ${python_exe} ${UNITREE_RL_LAB_PATH}/scripts/rsl_rl/train.py \
        8>&1 9>&2 1>/dev/null 2>/dev/null) )
}
complete -o nospace -F _ut_rl_lab_python_argcomplete_wrapper "./unitree_rl_lab.sh"


# ============================================================
#       Setup conda activation for Isaac Lab + RL Lab
# ============================================================
_ut_setup_conda_env() {
    mkdir -p "${CONDA_PREFIX}/etc/conda/activate.d"

    local TARGET="${CONDA_PREFIX}/etc/conda/activate.d/setenv.sh"
    echo -e "${BLUE}>>> Writing ${TARGET}${NC}"

    cat <<EOF > "${TARGET}"
#!/usr/bin/env bash
# auto-generated env config

# Isaac Lab
export ISAACLAB_PATH=${ISAACLAB_PATH}
alias isaaclab=${ISAACLAB_PATH}/isaaclab.sh

# Unitree RL Lab
export UNITREE_RL_LAB_PATH=${UNITREE_RL_LAB_PATH}
source ${UNITREE_RL_LAB_PATH}/unitree_rl_lab.sh

export RESOURCE_NAME="IsaacSim"
EOF

    chmod +x "${TARGET}"

    # If isaac sim binaries exist, add
    local isaacsim_setup_conda_env_script=${ISAACLAB_PATH}/_isaac_sim/setup_conda_env.sh
    if [[ -f "${isaacsim_setup_conda_env_script}" ]]; then
        echo "source ${isaacsim_setup_conda_env_script}" >> "${TARGET}"
    fi
}


# ============================================================
#              Extra environment repair function
# ============================================================
_fix_conda_env() {

    echo -e "${BLUE}>>> Repairing conda environment...${NC}"
    echo "CONDA_PREFIX = ${CONDA_PREFIX}"

    mkdir -p "$CONDA_PREFIX/etc/conda/activate.d"
    mkdir -p "$CONDA_PREFIX/etc/conda/deactivate.d"

    # --- create RL Lab env file ---
    local RL_ENV_PATH="$CONDA_PREFIX/etc/conda/activate.d/unitree_rl_lab_setenv.sh"
    echo -e "${BLUE}>>> Creating ${RL_ENV_PATH}${NC}"

    cat <<EOF > "$RL_ENV_PATH"
#!/bin/bash
# Unitree RL Lab environment variables
export UNITREE_RL_LAB_HOME="${UNITREE_RL_LAB_PATH}"
EOF
    chmod +x "$RL_ENV_PATH"

    # --- argcomplete ---
    echo -e "${BLUE}>>> Installing argcomplete (no sudo needed)...${NC}"
    activate-global-python-argcomplete --dest "$CONDA_PREFIX/etc/conda/activate.d" 2>/dev/null || true

    echo -e "${GREEN}>>> Conda environment repaired successfully!${NC}"
}


# ============================================================
#                    Command Dispatcher
# ============================================================
case "$1" in
    -i|--install)
        echo -e "${GREEN}>>> Installing Unitree RL Lab...${NC}"

        git lfs install
        pip install -e "${UNITREE_RL_LAB_PATH}/source/unitree_rl_lab/"

        echo -e "${YELLOW}>>> Writing conda activation scripts...${NC}"
        _ut_setup_conda_env

        echo -e "${YELLOW}>>> Repair environment...${NC}"
        _fix_conda_env

        echo -e "${GREEN}✔ Install complete!"
        echo -e "Please restart terminal or run: ${BLUE}exec bash${NC}"
        ;;

    -l|--list)
        shift
        ${python_exe} ${UNITREE_RL_LAB_PATH}/scripts/list_envs.py "$@"
        ;;

    -p|--play)
        shift
        ${python_exe} ${UNITREE_RL_LAB_PATH}/scripts/rsl_rl/play.py "$@"
        ;;

    -t|--train)
        shift
        ${python_exe} ${UNITREE_RL_LAB_PATH}/scripts/rsl_rl/train.py --headless "$@"
        ;;

    *)
        echo -e "${YELLOW}Unitree RL Lab helper script${NC}"
        echo "Usage:"
        echo "  ./unitree_rl_lab.sh --install      Install & fix environment"
        echo "  ./unitree_rl_lab.sh --list         List environments"
        echo "  ./unitree_rl_lab.sh --play args    Play policy"
        echo "  ./unitree_rl_lab.sh --train args   Train policy"
        ;;
esac
