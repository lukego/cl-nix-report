{ pkgs, logs }:

pkgs.runCommand "report" { inherit logs; }
  ''
    for log in $logs; do
      x
    done
  ''
