{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    tree

    gnupg
    pinentry-qt

    sniffnet
    bandwhich
    firejail

    podman
    slirp4netns

    exfatprogs
    dosfstools
  ];
}
