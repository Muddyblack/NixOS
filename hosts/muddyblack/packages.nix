{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    tree
    at

    gnupg
    pinentry-qt

    rustnet
    netscanner

    exfatprogs
    dosfstools
  ];
}
