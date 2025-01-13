{
  sops = {
    age.keyFile = "${_module.args.homeDirectory}/.config/sops/age/keys.txt"; # must have no password!
    # It's also possible to use a ssh key, but only when it has no password:
    age.sshKeyPaths = [ "${_module.args.homeDirectory}/.ssh/automation.pub" ];
    defaultSopsFile = ./example.sops.yaml;
    secrets."myservice/my_subdir/my_secret" = {
      mode = "0440";
      # owner = config.users.users.daniel.name;
      # group = config.users.users.daniel.group;
      path = "%r/my_secret.txt"; 
    };
  };
}
