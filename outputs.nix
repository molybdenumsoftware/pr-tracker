inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (import inputs.import-tree ./modules)
