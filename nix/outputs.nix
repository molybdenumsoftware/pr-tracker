inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (import inputs.import-tree ./flake-parts)
