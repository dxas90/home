{ pkgs, config, ... }:
let
  ageKeyFile = "${config.users.users.daniel.home}/.config/sops/age/keys.txt";
in
{
  config = {
    sops = {
      age.generateKey = true;
      age.keyFile = ageKeyFile;
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      defaultSopsFile = ./example.sops.yaml;
      secrets."myservice/my_subdir/my_secret" = {
        mode = "0440";
        owner = config.users.users.daniel.name;
        group = config.users.users.daniel.group;
      };
    };
  };
}