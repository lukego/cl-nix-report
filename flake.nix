{
  description = "A very basic flake";

  inputs.nixpkgs.url = "nixpkgs";
  inputs.nix-cl.url = "github:uthar/nix-cl";

  outputs = { self, nixpkgs, nix-cl }:
    let
      # [{lisp=string(), system=string()}]
      variants = [
        { lisp = "sbcl";  system = "x86_64-linux";  }
        { lisp = "clasp"; system = "x86_64-linux";  }
        { lisp = "ccl";   system = "x86_64-linux";  }
        { lisp = "abcl";  system = "x86_64-linux";  }
        { lisp = "ecl";   system = "x86_64-linux";  }
        { lisp = "sbcl";  system = "aarch64-linux";  }
        { lisp = "clasp"; system = "aarch64-linux";  }
        { lisp = "ccl";   system = "aarch64-linux";  }
        { lisp = "abcl";  system = "aarch64-linux";  }
        { lisp = "ecl";   system = "aarch64-linux";  }
      ];
      # derivation() -> derivation()
      reportSystem = "x86_64-linux";
      # {string()->derivation()}
      pkgs = nixpkgs.legacyPackages.${reportSystem};
      inherit (builtins) isAttrs hasAttr attrValues;
      inherit (pkgs.lib) filterAttrs mapAttrs mapAttrs' concatMap foldr;
      inherit (pkgs.lib.strings) hasPrefix;
      # {string()->derivation()} -> {string()->derivation()}
      preprocess = system: lisp-pkgs:
        # match derivation's system type
        let withBuildLog = pkgs.callPackage ./withBuildLog.nix nixpkgs.legacyPackages.${system}; in
        # exclude problematic derivations
        filterAttrs (_name: isAttrs)
          # instrument with build-logging
          (lisp-pkgs.overrideScope'
            (self: super: mapAttrs (name: deriv:
              withBuildLog deriv) super));
      # label packages uniquely by adding system and lisp to name
      # {lisp=string(),system=string()} -> derivation() -> derivation()
      labelPackages = {lisp, system}: attrs:
        mapAttrs' (name: deriv: { name = "${name}-${lisp}-${system}";
                                  value = deriv; }) attrs;
      # {lisp=string(), system=string()} -> {string()=>derivation()}
      labelledPackagesFor = {lisp, system}:
        labelPackages {inherit lisp system;}
          (preprocess system nix-cl.packages.${system}.${lisp}.pkgs);
      excluded = import ./excluded.nix;
      lispPackages = filterAttrs (name: value: ! hasAttr name excluded)
        (foldr (a: b: a // b) {} (map labelledPackagesFor variants));
      #sbclPackages = nix-cl.packages.${system}.sbcl.pkgs;
      report-csv = pkgs.runCommand "report-csv" {} ''
        set -x
        mkdir $out
        echo "package,version,system,lisp,lisp_version,status" >> $out/report.csv
        function pkg() {
          status="ok"
          [ -e $1/.LOG/failed ]  && status="failed"
          [ -e $1/.LOG/aborted ] && aborted="aborted"
          echo $2,$3,$4,$5,$6,$status >> $out/report.csv
        }
        ${pkgs.lib.concatMapStrings (d: ''
                                          pkg ${d} ${d.pname} ${d.version} ${d.system} ${d.pkg.pname} ${d.pkg.version}
                                        '')
          (attrValues lispPackages)}
        mkdir $out/nix-support
        echo "file report $out/report.csv" >> $out/nix-support/hydra-build-products
      '';
    in
      {
        inherit labelledPackagesFor labelPackages lispPackages;
        hydraJobs = { _000-report-csv = report-csv; } // lispPackages;
      };
}
