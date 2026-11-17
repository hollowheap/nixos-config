{lib, ...}: let
  inherit (lib) mkOption;
  inherit (lib.types) attrsOf nullOr str submodule;
in {
  options.ai.harnesses = mkOption {
    type = attrsOf (submodule {
      options.agents = mkOption {
        type = attrsOf (submodule {
          options = {
            model = mkOption {
              type = str;
              description = "Model slug exactly as the harness expects it, including any provider prefix.";
            };
            effort = mkOption {
              type = nullOr str;
              default = null;
              description = "Harness-native reasoning effort. Null leaves the harness default.";
            };
          };
        });
        default = {};
        description = "Model and effort per ai.agents name.";
      };
    });
    default = {};
    description = "Per-harness model routing, declared by each harness module. Providers and slug syntax belong to the harness, not to the shared agent definitions.";
  };
}
