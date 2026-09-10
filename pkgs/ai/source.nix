{
  lib,
  fetchurl,
}: name: let
  entry = (lib.importJSON ./_sources/generated.json).${name};
in {
  inherit (entry) version;
  src = fetchurl ({inherit (entry.src) url sha256;} // lib.optionalAttrs (entry.src.name != null) {inherit (entry.src) name;});
}
