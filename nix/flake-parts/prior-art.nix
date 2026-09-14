{
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      chapters.prior-art = {
        title = "Prior art";
        drv = pkgs.writeTextFile {
          name = "prior-art.md";
          text =
            # markdown
            ''
              - [Alyssa Ross' pr-tracker](https://nixpk.gs/pr-tracker.html) ([source](https://git.qyliss.net/pr-tracker))
                Server-side rendered web app. Computes landings for a given PR on the fly by invoking Git on the backend.
              - [ocfox's nixpkgs-tracker](https://nixpkgs-tracker.ocfox.me/) ([source](https://github.com/ocfox/nixpkgs-tracker))
                Client-side rendered web app. Computes landings for a given PR on the fly using GitHub api.
              - [Maralorn's nixpkgs-bot](https://blog.maralorn.de/projects#nixpkgs-bot) ([source](https://code.maralorn.de/maralorn/config/src/commit/b34d2e0d0adc62c30875edb475f1c09a752fe19e/packages/nixpkgs-bot))
                Matrix bot that provides notification of PR landings.
                Periodically computes new PR landings using Git and sends messages.

              All of the above are [Nixpkgs](https://github.com/nixos/nixpkgs/) specific, whereas this project is not.
              None of the above internally maintain a dataset of landings.
              None of the above currently provide an HTTP API.
            '';
        };
      };
    };
}
