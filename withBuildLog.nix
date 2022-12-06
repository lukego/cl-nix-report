{ pkgs, writeScript, stdenv, coreutils, strace, gzip, ... }:

let
  # Custom builder that allows builds to safely fail and collects logs from the
  # build process.
  #
  # The output directly always includes a .LOG subdirectory containing
  # information about the build. If the build succeeded then it also includes
  # the normal outputs of the build.
  #
  # This expression is ever-so-slightly specialized for Lisp packages because it
  # inspects $lispModules to detect if the build should be skipped due to a
  # dependency that failed (but was logged.)
  #
  # Usage: mkDerivation { ... } // { builder = <logging-builder>; }
  logging-builder = writeScript "logging-builder.sh"
    ''
      #!${stdenv.shell}
      PATH=$PATH:${coreutils}/bin:${gzip}/bin
      # Always add logs to derivation output
      function finish {
        [ -d $out ] || mkdir $out
        cp -r .LOG $out/
        [ -d $out/nix-support ] || mkdir -p $out/nix-support
        echo "file log $out/.LOG/build.log" >> $out/nix-support/hydra-build-products
        [ -f $out/.LOG/strace.log ] && gzip $out/.LOG/strace.log
        echo "file strace $out/.LOG/strace.log.gz" >> $out/nix-support/hydra-build-products
      }
      trap finish EXIT

      # Directory to accumulate logging state.
      mkdir .LOG
      echo $pname > .LOG/pname

      # Print the name of all failing dependencies and, if there are any, abort
      # the build.
      echo "checking libs"
      for mod in $lispLibs; do
        echo "mod = $mod"
        [ -e $mod/.LOG ] && ls $mod/.LOG
        [ -e $mod/.LOG/failed ] || [ -e $mod/.LOG/aborted ] && failed="$(cat $mod/.LOG/pname) $failed"
      done
      if [ -n "$failed" ]; then
        echo "FAILED-DEPENDENCIES: $failed" | tee .LOG/aborted
        exit 0;
      fi

      # Run the real builder as mkDerivation normally would
      echo "START: building $out" | tee .LOG/build.log
      set +e
      set -o pipefail
      #strace -f -o .LOG/strace.log \
        ${stdenv.shell} -c 'set -e; source $stdenv/setup; genericBuild' 2>&1 \
        | tee -a .LOG/build.log
      status=$?
      echo "FINISH: exit status $status for $out" >> .LOG/build.log
      [ "$status" -ne 0 ] && touch .LOG/failed
      exit 0
    '';
  # loggedBuildOf :: derivation -> derivation
  #
  # Update a derivation to produce the logs from the build process instead of
  # its normal output.
  withBuildLog = derivation:
    derivation.overrideLispAttrs (o: { builder = logging-builder;
                                       meta.logged = true;
                                       meta.broken = false;
                                       src = o.src.overrideAttrs (o': { configurePhase = "echo succeed on failure $successOnFailure";
                                                                        failureHook = "touch $out; echo THIS IS FINE; exit 0";
                                                                        succeedOnFailure = true; });
                                     });
in withBuildLog
