# .dot-files

My Nix flake configurations for NixOS and Home Manager.

Features
- Custom Nix packages built from source; and

---


## Online Install (Home Manager)

Install a configuration without cloning this repository.

:warning: Symlinks will be created in your home directory.

1. If Home Manager is not installed and flakes are not enabled, run
```bash
nix develop --extra-experimental-features 'nix-command flakes' github:dxas90/home
```

2. Install the Home Manager configuration of your choice.
```bash
home-manager switch --flake github:dxas90/home#$USER@$HOST
```
where `$USER@$HOST` is the `homeConfigurations` string in `flake.nix`.


## Full Install (Home Manager + NixOS)

Configure your NixOS system based off this flake.

1. Clone this repository and enter the custom shell.
```bash
# If not already installed
nix-shell -p git

git clone https://github.com/dxas90/home ~/.dot-files

cd ~/.dot-files

nix-shell
```

2. Create a NixOS configuration. See [For The Impatient](#for-the-impatient).
```bash
mkdir ~/.dot-files/nixos/$HOST

cp /etc/nixos/hardware-configuration.nix ~/.dot-files/nixos/$HOST

# Refer to an existing `default.nix` under `nixos/` to get started
vim ~/.dot-files/nixos/$HOST/default.nix
```

3. Create a Home Manager configuration. See [For The Impatient](#for-the-impatient).
```bash
mkdir ~/.dot-files/home-manager/$USER

# Refer to an existing `default.nix` under `home-manager/` to get started
vim ~/.dot-files/home-manager/$USER/default.nix
```

4. Add the configurations to the flake and switch to it.
```bash
vim ~/.dot-files/flake.nix

cd ~/.dot-files; git add .

sudo nixos-rebuild switch --flake ~/.dot-files

home-manager switch --flake ~/.dot-files
```
Append `#$HOST` and `#$USER@$HOST` to the switch commands (no space) if the correct values are not set in the environment variables.

---
### For The Impatient

If you want a quick start to using my configurations,
replace the below references, `$USER` and `$HOST`, in each of the files.

**NixOS**

[`flake.nix`](flake.nix)
```nix
nixosConfigurations = {
  $HOST = nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs outputs; };
    modules = [ ./nixos/$HOST ];
  };
};
```
[`nixos/$HOST/default.nix`](nixos/ullr/default.nix)
```bash
networking.hostName = "$HOST";
...
users.users.$USER = {
  home = "/home/$USER";
};
```

**Home Manager**

[`flake.nix`](flake.nix)
```nix
homeConfigurations = {
  "$USER@$HOST" = home-manager.lib.homeManagerConfiguration {
    extraSpecialArgs = { inherit inputs outputs; };
    modules = [ ./home-manager/me ];
    pkgs = pkgsFor.x86_64-linux;
  };
};
```
[`home-manager/$USER/default.nix`](home-manager/me/default.nix)
```nix
home = {
  username = "$USER";
  homeDirectory = "/home/$USER";
};
```

:warning: Make sure to change personal settings such as Git username and imported NixOS hardware modules.

---
Special thanks to [Misterio77](https://github.com/misterio77) for creating the [nix-starter-configs](https://github.com/misterio77/nix-starter-configs)!
