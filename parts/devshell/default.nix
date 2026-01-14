{ ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      mkGitGhShell = import ./mkGitGhShell.nix;
    in
    {
      devShells."git-gh-isolated" = mkGitGhShell {
        inherit pkgs;
        project = "devshell";
      };
    };
}
