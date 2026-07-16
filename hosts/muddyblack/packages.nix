{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    tree
    at

    gnupg
    pinentry-qt

    bandwhich

    exfatprogs
    dosfstools
  ];
}
