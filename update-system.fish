#!/usr/bin/env fish

set -l nixos_dir "/etc/nixos"

echo "==> Updating Nix flake inputs..."
sudo nix flake update --flake $nixos_dir; or exit 1

echo "==> Staging changes in Git..."
git -C $nixos_dir add flake.lock configuration.nix update-system.fish

echo "==> Committing changes..."
git -C $nixos_dir commit -m "chore: auto-update flake inputs and system config"

echo "==> Pushing to GitHub..."
git -C $nixos_dir push; or exit 1

echo "==> Rebuilding NixOS configuration with NH..."
nh os switch $nixos_dir; or exit 1

echo "==> System update complete and active!"
