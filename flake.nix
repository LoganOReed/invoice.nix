# Heavily based on:
# https://flyx.org/nix-flakes-latex/

{
  description = "Generates Invoices from Watson and LaTeX";
  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/nixos-unstable;
    flake-utils.url = github:numtide/flake-utils;
  };
  outputs = { self, nixpkgs, flake-utils }:
    let
      rootName = "document";
      outScriptName = "latex-demo-document";
    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        tex = pkgs.texlive.combine {
          inherit (pkgs.texlive) scheme-basic latex-bin latexmk
            metafont
            chktex
            latexindent
            tabularray
            ragged2e
            etoolbox
            advdate
            ehhline
            ;
        };
      # make variables more visible to defining them here
      vars = [ "client" "rate" "qty" ];
      # expands to definitions like \def\sender{$1}, i.e. each variable
      # will be set to the command line argument at the variable's position.
      texvars = toString
        (pkgs.lib.imap1 (i: n: ''\def\${n}{${"$" + (toString i)}}'') vars);
      in
      rec {
        packages = {
          document = pkgs.stdenvNoCC.mkDerivation rec {
            name = outScriptName;
            src = self;
            propagatedBuildInputs = [ pkgs.coreutils tex ];
            phases = [ "unpackPhase" "buildPhase" "installPhase" ];
            # the pretex omits luatex from using the generated id(512), which allows hash to be fixed
            SCRIPT = ''
              #!/usr/bin/env bash
              prefix=${builtins.placeholder "out"}
              export PATH="${pkgs.lib.makeBinPath propagatedBuildInputs}";
              DIR=$(mktemp -d)
              RES=$(pwd)/${rootName}.pdf
              cd $prefix/share
              mkdir -p "$DIR/.texcache/texmf-var"
              env TEXMFHOME="$DIR/.cache" \
                  TEXMFVAR="$DIR/.cache/texmf-var" \
                latexmk -interaction=nonstopmode -pdf -lualatex \
                -output-directory="$DIR" \
                -pretex="\pdfvariable suppressoptionalinfo 512\relax${texvars}" \
                -usepretex ${rootName}.tex
              mv "$DIR/${rootName}.pdf" $RES
              rm -rf "$DIR"
            '';
            buildPhase = ''
              printenv SCRIPT >${outScriptName}
            '';
            installPhase = ''
              mkdir -p $out/{bin,share}
              cp ${rootName}.tex $out/share/${rootName}.tex
              cp ${outScriptName} $out/bin/${outScriptName}
              chmod u+x $out/bin/${outScriptName}
            '';
          };
          default = packages.document;
        };

        devShells.default = pkgs.mkShellNoCC {
          buildInputs = [
            tex
          ];
        };
      });
}
