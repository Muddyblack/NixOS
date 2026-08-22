{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.features.kernel;
  cachy = cfg.cachyos;

  suffix =
    lib.optionalString cachy.lto "-lto"
    + lib.optionalString (cachy.march != "generic") "-${cachy.march}";
  kernelName = "cachyos-${cachy.variant}${suffix}";

  # The exact jobset upstream's Hydra builds and pushes to the lantian cache
  # (hydraJobs in xddxdd/nix-cachyos-kernel). Every other combination still
  # evaluates, but no substituter carries it, so a switch would compile a
  # kernel from source locally. x86_64-v2 is absent on purpose: upstream
  # documents it as never built.
  archVariants = ["latest" "lts" "bore"];
  plainVariants = ["bmq" "deckify" "eevdf" "hardened" "rc" "rt-bore" "server"];
  prebuilt =
    plainVariants
    ++ lib.concatMap (
      v:
        lib.concatMap (
          l:
            map (m: "${v}${l}${m}") ["" "-x86_64-v3" "-x86_64-v4" "-zen4"]
        ) ["" "-lto"]
    )
    archVariants;
in {
  options.features.kernel = {
    cachyos = {
      enable = lib.mkEnableOption "CachyOS kernel from xddxdd/nix-cachyos-kernel";

      variant = lib.mkOption {
        type = lib.types.enum (archVariants ++ plainVariants);
        default = "latest";
        description = "CachyOS kernel variant. `latest` tracks the newest mainline release, `lts` the newest longterm one.";
      };

      lto = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Build with Clang+ThinLTO. Only cached for the `latest`, `lts` and `bore` variants.";
      };

      march = lib.mkOption {
        type = lib.types.enum ["generic" "x86_64-v3" "x86_64-v4" "zen4"];
        default = "generic";
        description = ''
          Instruction set the kernel is compiled for. `generic` boots anywhere;
          the rest fail to boot on CPUs that lack the extensions. Check the
          machine first with `ld.so --help | grep -o "x86-64-v[0-9]"`.
        '';
      };
    };

    scx = {
      enable = lib.mkEnableOption "sched_ext userspace scheduler";

      scheduler = lib.mkOption {
        type = lib.types.str;
        default = "scx_lavd";
        description = ''
          sched_ext scheduler to load. `scx_lavd` is latency-aware and
          power-aware, `scx_bpfland` and `scx_flash` are the general-purpose
          interactive alternatives.
        '';
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cachy.enable {
      # The LTO variants are Clang-built, so every package in this set - including
      # out-of-tree modules - gets a clang stdenv with no `gcc` on PATH. kbuild
      # still defaults CC to gcc for external modules unless LLVM=1 is passed, so
      # such a build dies with "gcc: command not found" while being handed
      # clang-only flags (-fsplit-lto-unit, -mretpoline-external-thunk). vmware is
      # the only out-of-tree module this config pulls in; extend the set rather
      # than override boot.kernelPackages downstream, so this module stays the
      # single owner of the option.
      boot.kernelPackages = let
        base = pkgs.cachyosKernels."linuxPackages-${kernelName}";
      in
        if cachy.lto
        then
          base.extend (_final: prev: {
            vmware = prev.vmware.overrideAttrs (o: {
              makeFlags = (o.makeFlags or []) ++ ["LLVM=1"];
            });
          })
        else base;

      assertions = [
        {
          assertion = lib.elem "${cachy.variant}${suffix}" prebuilt;
          message = "features.kernel.cachyos: linux-${kernelName} has no Hydra job upstream, so it is not in attic.xuyh0120.win/lantian and rebuilding would compile the kernel locally. Prebuilt combinations: ${lib.concatStringsSep ", " prebuilt}.";
        }
      ];
    })

    # The CachyOS kernel ships CONFIG_SCHED_CLASS_EXT but no userspace
    # scheduler, so without this it runs plain EEVDF. rustscheds instead of
    # scx.full keeps the C example schedulers out of the closure. If the
    # scheduler cannot attach, systemd gives up after two tries and the kernel
    # stays on EEVDF - the desktop never hangs on it. Note security.nix sets
    # net.core.bpf_jit_harden = 2, which blinds constants in this scheduler's
    # own BPF program too.
    (lib.mkIf cfg.scx.enable {
      services.scx = {
        enable = true;
        package = pkgs.scx.rustscheds;
        inherit (cfg.scx) scheduler;
      };
    })
  ];
}
