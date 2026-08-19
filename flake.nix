{
  description = "A fuzzer for the Vox compiler, written in Vox";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # The compiler that builds — and at runtime, is fuzzed by — this tool.
    vox.url = "github:Vox-lang/vox";
  };

  outputs = { self, nixpkgs, flake-utils, vox }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        voxc = vox.packages.${system}.default;
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "vox-fuzz";
          version = "0.2.0";
          src = ./.;

          nativeBuildInputs = [ voxc pkgs.nasm pkgs.binutils pkgs.gnumake ];

          buildPhase = ''
            make build VOX=vox
          '';
          # test.sh refuses a missing VOX_CORE_PATH rather than silently
          # deriving a wrong one; point it at the compiler's own store copy.
          checkPhase = ''
            VOX=${voxc}/bin/vox VOX_CORE_PATH=${voxc}/share/vox/coreasm bash ./test.sh
          '';
          doCheck = true;
          installPhase = ''
            install -D -m 0755 build/vox-fuzz $out/bin/vox-fuzz
          '';

          meta = with pkgs.lib; {
            description = "A fuzzer for the Vox compiler, written in Vox";
            homepage = "https://github.com/Vox-lang/vox-fuzz";
            license = licenses.gpl3Plus;
            platforms = [ "x86_64-linux" ];
            mainProgram = "vox-fuzz";
          };
        };

        devShells.default = pkgs.mkShell {
          packages = [ voxc pkgs.nasm pkgs.binutils pkgs.gnumake ];
        };
      });
}
