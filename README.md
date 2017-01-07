Takes a generic FreeBSD installation, and turns it into a workable
desktop.

Usage:

  edit manifests/default.pp to suit
  pkg install -y puppet
  puppet apply manifests/default.pp
