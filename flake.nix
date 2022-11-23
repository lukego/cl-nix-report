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
      logs = sbclPackages.overrideScope' (self: super: {
        mcclim-bezier = super.mcclim-bezier.overrideAttrs(o: { meta = { broken = false; }; });
#flatPackages super
        #super
#mapAttrs (name: deriv: deriv.overrideAttrs(o: { meta = { broken = false; }; })) super
      });
#logs = mapAttrs (n: d: withBuildLog d) eligiblePkgs;

      logged = sbclPackages.overrideScope'
        (self: super: mapAttrs (name: deriv: withBuildLog deriv) super);
      logged' = filterAttrs (name: value: isAttrs value && name != "facts") logged;
      report = pkgs.runCommand "report" {} ''
        set -x
        mkdir $out
        echo "package,failed,aborted" >> $out/report.csv
        function pkg() {
          failed=0
          aborted=0
          [ -e $1/.LOG/failed ]  && failed=1
          [ -e $1/.LOG/aborted ] && aborted=1
          echo $2,failed,aborted >> $out/report.csv
        }
        ${pkgs.lib.concatMapStrings (d: ''
                                          pkg ${d} ${d.pname}
                                        '')
          (attrValues logged')}
        mkdir $out/nix-support
        echo "file report $out/report.csv" >> $out/nix-support/hydra-build-products
      '';
    in
      {
        hydraJobs = { _report = report; } // logged';
#        inherit logged;
#        inherit pkgs;
#        inherit logs;
#        inherit sbclPackages;
#        inherit withBuildLog;
#packages.${system}.default = report;
      };
}
