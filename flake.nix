{
  description = "A very basic flake";

  inputs.nixpkgs.url = "nixpkgs";
  inputs.nix-cl.url = "github:lukego/nix-cl/more-log";

  outputs = { self, nixpkgs, nix-cl }:
    let
      # [{lisp=string(), system=string()}]
      variants = [
        { lisp = "sbcl";  system = "x86_64-linux";   }
        { lisp = "sbcl";  system = "x86_64-darwin";  }
        { lisp = "sbcl";  system = "aarch64-linux";  }
        { lisp = "sbcl";  system = "aarch64-darwin"; }

#        { lisp = "clasp"; system = "x86_64-linux";   }
#        { lisp = "clasp"; system = "x86_64-darwin";  }
#        { lisp = "clasp"; system = "aarch64-linux";  }
#        { lisp = "clasp"; system = "aarch64-darwin"; }
      ];
      # derivation() -> derivation()
      reportSystem = "x86_64-linux";
      # {string()->derivation()}
      pkgs = nixpkgs.legacyPackages.${reportSystem};
      inherit (builtins) isAttrs hasAttr attrValues;
      inherit (pkgs.lib) filterAttrs mapAttrs mapAttrs' concatMap concatMapAttrs foldr;
      inherit (pkgs.lib.strings) hasPrefix;
      # string() -> {string()->derivation()} -> {string()->derivation()}
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
      included = (name: true); # (name: hasPrefix "c" name);
      alsoJumbo = lisp-pkgs:
        concatMapAttrs (name: drv:
          let system = drv.system;
              jumbo-deps = pkgs.callPackage ./jumbo-deps.nix nixpkgs.legacyPackages.${system}; in
            { #"${name}-base"  = drv;
              "${name}-jumbo" = (drv.overrideLispAttrs (o: { #propagatedBuildInputs = o.propagatedBuildInputs ++ jumbo-deps.programs ++ jumbo-deps.libraries;
                                                             nativeBuildInputs = jumbo-deps.programs;
                                                             nativeLibs = jumbo-deps.libraries;
                                                             variant = "jumbo"; }));
          }) lisp-pkgs;
      lispPackages =
        alsoJumbo
          (filterAttrs (name: value: included name && ! hasAttr name excluded)
            (foldr (a: b: a // b) {} (map labelledPackagesFor variants)));
      #sbclPackages = nix-cl.packages.${system}.sbcl.pkgs;
      #
      # CSV table data from the build results.
      #
      report = pkgs.runCommand "report"
        { buildInputs = with pkgs.rPackages; [ pkgs.R tidyverse ]; }
        ''
          set -x
          mkdir -p $out/nix-support

          #
          # Aggregated logs tarball
          #
          mkdir lisp-build-logs
          ${pkgs.lib.concatMapStrings (d:
            ''
              #cp ${d}/.LOG/build.log lisp-build-logs/$(cat ${d}/pname).log
              [ -f ${d}/.LOG/build.log ] && cat ${d}/.LOG/build.log >> $out/lisp-build-logs.txt
            '')
            (attrValues lispPackages)}
          #tar czf $out/lisp-build-logs.tar.gz
          gzip $out/lisp-build-logs.txt
          echo "file logs $out/lisp-build-logs.txt.gz" >> $out/nix-support/hydra-build-products

          #
          # CSV
          #
          echo "package,version,system,lisp,lisp_version,status,failed_deps,variant,reason" >> report.csv
          function pkg() {
            status="ok"
            reason=""
            [ -e $1/.LOG/failed ]  && status="failed"
            if [ -e $1/.LOG/aborted ]; then
              status="aborted"
              failed_deps=$(cat $1/.LOG/aborted | sed -e 's/^FAILED-DEPENDENCIES: //')
            fi
            if [ -f $1/.LOG/build.log ]; then
              reason=$(awk '/^BUILD FAILED/ { print $3  }' < $1/.LOG/build.log)
            fi
            echo $2,$3,$4,$5,$6,$status,$failed_deps,$7,$reason >> report.csv
          }
          ${pkgs.lib.concatMapStrings (d: ''
                                            pkg ${d} ${d.pname} ${d.version} ${d.system} ${d.pkg.pname} ${d.pkg.version} ${if d?variant then d.variant else "base"}
                                          '')
            (attrValues lispPackages)}
          cp report.csv $out/
          echo "file report $out/report.csv" >> $out/nix-support/hydra-build-products

          #
          # Image
          #
          Rscript - <<EOF
          library(readr)
          library(dplyr)
          library(ggplot2)
          data <- read_csv("report.csv")
          ggplot(data, aes(x=lisp, fill=status)) + geom_bar() + facet_grid(~system)
          ggsave("summary.png")

          ggplot(filter(data, !is.na(reason)), aes(x=lisp, fill=system)) +
            geom_bar() +
            facet_wrap(~reason) +
            scale_x_discrete(guide = guide_axis(angle = 90)) +
            theme(strip.text = element_text(size = 3))
          ggsave("error-variant.png")
          EOF
          cp summary.png $out/
          echo "file summary $out/summary.png" >> $out/nix-support/hydra-build-products
          cp error-variant.png $out/
          echo "file errors $out/error-variant.png" >> $out/nix-support/hydra-build-products

        '';
    in
      {
        inherit labelledPackagesFor labelPackages lispPackages preprocess;
        hydraJobs = { _000-report = report; } // lispPackages;
        devShells.x86_64-linux.report = pkgs.mkShell {
          buildInputs = with pkgs.rPackages; [ pkgs.R tidyverse ];
        };
      };
}
