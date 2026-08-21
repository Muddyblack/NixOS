{
  config,
  lib,
  inputs,
  username,
  ...
}: let
  cfg = config.features.sops;
in {
  imports = [inputs.sops-nix.nixosModules.sops];

  options.features.sops = {
    enable = lib.mkEnableOption "SOPS-encrypted secrets";

    # Opt-in and off by default on purpose: sops-nix fails activation if a
    # declared secret is missing from secrets.yaml, so flipping this before the
    # key exists would break the rebuild. Add the key first:
    #
    #   mkpasswd -m yescrypt          # paste the hash as user-password-hash
    #   secrets secrets/secrets.yaml  # `secrets` = the sops alias
    #
    # NOTE ON SEMANTICS: hashedPasswordFile is reapplied on every activation,
    # unlike initialPassword which only ever applies at user creation. So this
    # makes the sops value authoritative — changing the password with `passwd`
    # works until the next `upnix`, which resets it to the hash in git. To
    # change it for real, change the secret and rebuild.
    userPassword.enable =
      lib.mkEnableOption "sourcing the login password from sops instead of initialPassword";
  };

  config = lib.mkIf cfg.enable {
    sops = {
      defaultSopsFile = ../../../secrets/secrets.yaml;
      age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      age.keyFile = "/persist/sops-age-keys.txt";
      age.generateKey = true;

      secrets =
        {
          espanso-email = {
            owner = username;
            mode = "0400";
          };

          # Weather widget location (kept out of git plaintext)
          weather-latitude = {
            owner = username;
            mode = "0400";
          };
          weather-longitude = {
            owner = username;
            mode = "0400";
          };

          # Firefly III APP_KEY (encrypts stored secrets); read by the firefly user.
          firefly-app-key = {
            owner = "firefly-iii";
            mode = "0400";
          };
        }
        // lib.optionalAttrs cfg.userPassword.enable {
          # neededForUsers puts this in /run/secrets-for-users, which is
          # decrypted before users are created. owner/mode are not settable on
          # such secrets — sops-nix owns them.
          user-password-hash.neededForUsers = true;
        };
    };

    users.users.${username}.hashedPasswordFile =
      lib.mkIf cfg.userPassword.enable
      config.sops.secrets.user-password-hash.path;
  };
}
