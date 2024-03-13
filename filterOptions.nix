{
  concatMapAttrs,
  isOption,
  traceVal,
  ...
}: predicate: options: let
  inherit (builtins) isAttrs;

  recurse = path: options:
    concatMapAttrs
    (
      name: value: let
        newPath = path ++ [name];
      in
        if !(isAttrs value)
        then {${name} = value;}
        else if !(isOption value)
        then {${name} = recurse newPath value;}
        else if predicate newPath value
        then {${name} = value;}
        else {}
    )
    options;
in
  recurse [] options
