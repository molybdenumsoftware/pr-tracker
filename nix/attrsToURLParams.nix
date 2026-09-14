{
  attrsToList,
  concatStringsSep,
  escapeURL,
  ...
}:
attrs:
let
  pairs = map (param: "${escapeURL param.name}=${escapeURL param.value}") (attrsToList attrs);
  params = concatStringsSep "&" pairs;
in
params
