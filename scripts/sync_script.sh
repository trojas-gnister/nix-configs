#!/usr/bin/env bash
set -e

if [ ! -d "$HOME/nix-configs" ]; then
  echo "nix-configs doesn't exist. Cloning repo...."
  cd
  git clone https://github.com/trojas-gnister/nix-configs.git
fi

cd "$HOME/nix-configs"
git pull

sudo rm -rf /etc/nixos/flake.nix /etc/nixos/hosts /etc/nixos/iso /etc/nixos/lib /etc/nixos/modules
sudo cp -r ~/nix-configs/flake.nix ~/nix-configs/hosts ~/nix-configs/iso ~/nix-configs/lib ~/nix-configs/modules /etc/nixos
