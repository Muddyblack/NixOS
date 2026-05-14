{
  config,
  lib,
  inputs,
  username,
  ...
}: {
  imports = [inputs.sops-nix.nixosModules.sops];

  options.features.sops.enable = lib.mkEnableOption "SOPS-encrypted secrets";

  config = lib.mkIf config.features.sops.enable {
    sops = {
      defaultSopsFile = ../../../secrets/secrets.yaml;
      age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      age.keyFile = "/persist/sops-age-keys.txt";
      age.generateKey = true;

      secrets.espanso-email = {
        owner = username;
        mode = "0400";
      };
    };
  };
}
