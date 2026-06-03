#!/usr/bin/env bash
# Quick environment setup for NixOS Live USB
# Run this to get your tools ready for debugging/recovery

set -e

echo "=== Setting up Live USB Environment ==="

# Allow unfree packages (for claude-code, etc.)
export NIXPKGS_ALLOW_UNFREE=1

echo ""
echo "Starting nix-shell with tools..."
echo "This will give you: git, claude-code, antigravity"
echo ""

# Enter shell with useful tools
nix-shell -p \
    git \
    claude-code \
    antigravity \
    btop \
    ripgrep \
    fd \
    eza \
    --run bash

# Alternative: one-liner to copy/paste
# NIXPKGS_ALLOW_UNFREE=1 nix-shell -p git claude-code antigravity btop ripgrep fd eza
