{
  pkgs ? import <nixpkgs> {
    overlays = [
      (import (builtins.fetchTarball "https://github.com/oxalica/rust-overlay/archive/master.tar.gz"))
    ];
  },
}:

pkgs.mkShell {
  packages = with pkgs; [
    (rust-bin.stable.latest.default.override
    {
      extensions = [
        "rust-src"
        "rust-analyzer"
        "clippy"
        "rustfmt"
      ];
    })
    flutter
    flutter_rust_bridge_codegen
    pkg-config
  ];
}
