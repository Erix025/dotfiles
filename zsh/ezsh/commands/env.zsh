# ezsh env
# Show concise research environment snapshot

ezsh_desc_env="Show concise research environment (python, torch, cuda, paths)"

ezsh_cmd_env() {
  emulate -L zsh
  setopt localoptions no_unset

  print -r -- "=== Environment Snapshot ==="
  print -r -- ""

  # Basic context
  print -r -- "Host      : $(hostname -s 2>/dev/null || hostname)"
  print -r -- "User      : $USER"
  print -r -- "PWD       : $PWD"
  print -r -- ""

  # Shell / PATH
  print -r -- "Shell     : $SHELL"
  print -r -- "PATH (top):"
  local p
  for p in $path[1,8]; do
    print -r -- "  - $p"
  done
  print -r -- ""

  # Python
  if command -v python &>/dev/null; then
    print -r -- "Python    : $(python -V 2>&1)"
    print -r -- "  which   : $(command -v python)"
  else
    print -r -- "Python    : not found"
  fi

  if command -v pip &>/dev/null; then
    print -r -- "Pip       : $(pip -V 2>/dev/null)"
  fi
  print -r -- ""

  # Virtual env / Conda / Pixi
  if [[ -n "${VIRTUAL_ENV:-}" ]]; then
    print -r -- "VENV      : ${VIRTUAL_ENV:t}"
  fi

  if [[ -n "${CONDA_DEFAULT_ENV:-}" ]]; then
    print -r -- "Conda env : $CONDA_DEFAULT_ENV"
  fi

  if command -v pixi &>/dev/null; then
    print -r -- "Pixi      : $(pixi --version 2>/dev/null)"
    if [[ -n "${PIXI_ENV_NAME:-}" ]]; then
      print -r -- "  env     : $PIXI_ENV_NAME"
    fi
  fi
  print -r -- ""

  # Torch / CUDA (lazy, safe)
  if command -v python &>/dev/null; then
    python - <<'EOF'
try:
    import torch
    print(f"Torch     : {torch.__version__}")
    print(f"CUDA avail: {torch.cuda.is_available()}")
    if torch.cuda.is_available():
        print(f"CUDA ver  : {torch.version.cuda}")
        print(f"GPU count: {torch.cuda.device_count()}")
        print(f"GPU[0]   : {torch.cuda.get_device_name(0)}")
except Exception:
    print("Torch     : not usable")
EOF
  fi
  print -r -- ""

  # System CUDA tools
  if command -v nvcc &>/dev/null; then
    print -r -- "nvcc      : $(nvcc --version | sed -n 's/.*release //p' | head -n1)"
  fi

  if command -v nvidia-smi &>/dev/null; then
    print -r -- "nvidia-smi: available"
  fi

  print -r -- ""
  print -r -- "============================"
}
