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
