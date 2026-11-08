{pkgs, ...}: {
  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-qt;
  };

  environment.systemPackages = with pkgs; [
    tree
    at

    gnupg
    pinentry-qt
    kdePackages.kleopatra

    rustnet
    netscanner
    quickemu

    exfatprogs
    dosfstools
  ];
}
