{ pkgs, ... }:

with pkgs; [
  # programs
  coreutils
  gcc
  gnumake
  makeBinaryWrapper
  openmpi
  pkg-config

  # shared libraries
  alsa-lib
  fcgi
  flac
  freeimage
  geoip
  geos
  glpk
  graphviz
  gsl
  leveldb
  libGL
  openblas # compatible with mgl-mat?
  #libblas
  libcerf
  libdrm
  libev
  libevent
  libfann
  #libfarmhash
  libgcrypt
  libiio
  libinput
  liblinear
  libnet
  libpcap
  libsvm
  libtcod
  libxkbcommon
  zstd
  lmdb
  lzlib
  mesa
  mpg123
  ncurses
  nlopt
  #nvidia-x11 # or opengl-drivers
  openal
  openslp
  openssl
  pixman
  plplot
  portaudio
  #rocm-opencl-runtime
  rrdtool
  sane-backends
  secp256k1
  snappy
  termbox
  tesseract3
  tokyocabinet
  unixODBC
  xorg.libX11
  #zyre
] ++ (if renderdoc.system != "aarch64-linux" then [ renderdoc ] else [])
