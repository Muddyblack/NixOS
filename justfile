default:
    @just --list

fmt:
    alejandra .

check:
    nix flake check --show-trace

dead:
    deadnix .

deploy *args:
    ./deploy.sh switch {{args}}

update:
    nix flake update

gen:
    nh os list

clean keep="5":
    nh clean all --keep {{keep}}