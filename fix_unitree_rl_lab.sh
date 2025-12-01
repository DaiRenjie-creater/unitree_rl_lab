#!/bin/bash

# ====================================================
# Fix script for unitree_rl_lab environment issues
# - Creates missing conda activate.d/deactivate.d dirs
# - Adds setenv.sh placeholder
# - Installs argcomplete completion *inside* conda env
# ====================================================

echo ">>> Ensuring CONDA_PREFIX exists..."
if [[ -z "$CONDA_PREFIX" ]]; then
    echo "[ERROR] No conda environment active."
    echo "Please run: conda activate env_isaaclab"
    exit 1
fi

echo ">>> Using CONDA_PREFIX: $CONDA_PREFIX"

# -----------------------------
# 1. Create missing directories
# -----------------------------
echo ">>> Creating conda activate/deactivate directories..."
mkdir -p "$CONDA_PREFIX/etc/conda/activate.d"
mkdir -p "$CONDA_PREFIX/etc/conda/deactivate.d"

# -----------------------------
# 2. Create setenv.sh
# -----------------------------
SETENV_PATH="$CONDA_PREFIX/etc/conda/activate.d/setenv.sh"

echo ">>> Creating setenv.sh at: $SETENV_PATH"
cat <<EOF > "$SETENV_PATH"
#!/bin/bash
# This file sets environment variables for unitree_rl_lab
export UNITREE_RL_LAB_HOME="$PWD"
EOF

chmod +x "$SETENV_PATH"

# -----------------------------
# 3. Install argcomplete locally
# -----------------------------
echo ">>> Installing argcomplete completion inside conda env..."
activate-global-python-argcomplete \
  --dest "$CONDA_PREFIX/etc/conda/activate.d" \
  --no-sudo

# -----------------------------
# 4. Final message
# -----------------------------
echo ">>> Fix complete!"
echo "Please restart your terminal or run: exec bash"

