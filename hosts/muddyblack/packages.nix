{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    tree

    gnupg
    pinentry-qt

    bandwhich

    exfatprogs
    dosfstools
  ];
}
