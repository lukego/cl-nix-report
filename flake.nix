{
  description = "A very basic flake";

  inputs.nixpkgs.url = "nixpkgs";
  inputs.nix-cl.url = "github:uthar/nix-cl";

  outputs = { self, nixpkgs, nix-cl }:
    let
      withBuildLog = pkgs.callPackage ./withBuildLog.nix pkgs;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (builtins) isAttrs hasAttr attrValues;
      inherit (pkgs.lib) filterAttrs mapAttrs mapAttrs';
      inherit (pkgs.lib.strings) hasPrefix;
      # from system.package
      # to   package
      #unpack = attrs:
      # from nested: x86_64-linux.foo
      # to flat:     log-x86_64-linux-foo
      flatPackages = mapAttrs' (name: deriv: deriv.overrideAttrs (o:
                                                rec { name = "log-${system}-${deriv.name}";
                                                   value = deriv.overrideAttrs (o:
                                                     {
                                                       inherit name;
                                                       value = withBuildLog deriv;
                                                       meta.broken = false;
                                                     });
                                                    }));
      # filter out packages whose dependencies don't build.
      #
      # Since recursive nix doesn't seem to work at scale [*] we have no
      # "try-catch" way to include them in the nix expression evaluation.
      #
      # [*] https://github.com/NixOS/nix/issues/7297
      # CRUDE:
      eligible = n: d: (isAttrs d) && (hasAttr "systems" d) && hasPrefix "g" n;
      eligiblePkgs = filterAttrs eligible (nix-cl.packages.${system}.sbcl.pkgs);
      sbclPackages = nix-cl.packages.${system}.sbcl.pkgs;
      logged = sbclPackages.overrideScope'
        (self: super: mapAttrs (name: deriv: withBuildLog deriv) super);
      logged' = filterAttrs (name: value: isAttrs value && name != "facts") logged;
      report-csv = pkgs.runCommand "report-csv" {} ''
        set -x
        mkdir $out
        echo "package,system,lisp,status" >> $out/report.csv
        function pkg() {
          status="ok"
          [ -e $1/.LOG/failed ]  && status="failed"
          [ -e $1/.LOG/aborted ] && aborted="aborted"
          echo $2,$3,sbcl,$status >> $out/report.csv
        }
        ${pkgs.lib.concatMapStrings (d: ''
                                          pkg ${d} ${d.pname} ${d.system}
                                        '')
          (attrValues logged')}
        mkdir $out/nix-support
        echo "file report $out/report.csv" >> $out/nix-support/hydra-build-products
      '';
    in
      {
        hydraJobs = { _000-report-csv = report-csv; } // logged';
      };
}
