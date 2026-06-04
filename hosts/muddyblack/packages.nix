{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    tree

    gnupg
    pinentry-qt

    bandwhich
    firejail

    podman
    slirp4netns

    exfatprogs
    dosfstools
  ];
}
