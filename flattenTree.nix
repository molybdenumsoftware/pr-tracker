# TODO: consider contributing a recursive version of this upstream to
# flake-utils. See https://github.com/numtide/flake-utils/issues/112.
tree: let
  op = sum: path: val: let
    pathStr = builtins.concatStringsSep "/" path;
  in
    if (builtins.typeOf val) != "set"
    then
      # ignore that value
      # builtins.trace "${pathStr} is not of type set"
      sum
    else if val ? type && val.type == "derivation"
    then
      # builtins.trace "${pathStr} is a derivation"
      # we used to use the derivation outPath as the key, but that crashes Nix
      # so fallback on constructing a static key
      (sum
        // {
          "${pathStr}" = val;
        })
    else (recurse sum path val);

  recurse = sum: path: val:
    builtins.foldl'
    (sum: key: op sum (path ++ [key]) val.${key})
    sum
    (builtins.attrNames val);
in
  recurse {} [] tree
