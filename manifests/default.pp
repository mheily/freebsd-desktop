### GLOBAL VARIABLES
$user = 'vagrant'
$setxkbmap = 'dvorak'
$xsession_manager = 'startlxde'
$login_manager = 'slim'
$text_editor = 'vim'
$ide = 'eclipse'
$source_code = true	# checkout the FreeBSD source code
####################

define rc_conf($content) {
  augeas { "rc_conf/${title}":
     context => "/files/etc/rc.conf",
     onlyif  => "get ${title} != '${content}'",
     changes => "set ${title} '\"${content}\"'",
   }
}

define sysctl($content) {
  augeas { "sysctl/${title}":
     context => "/files/etc/sysctl.conf",
     onlyif  => "get ${title} != '${content}'",
     changes => "set ${title} '${content}'",
   }
}

define loader_conf($content) {
  # FIXME: puts an unsupported space between the key and value
  #augeas { "loader_conf/${title}":
  #   incl    => "/boot/loader.conf",
  #   lens    => "Simplevars.lns",
  #   onlyif  => "get ${title} != '${content}'",
  #   changes => "set ${title} ${content}",
  # }
  exec { "loader_conf/${title}":
    command => "sh -c 'echo ${title}=${content}' >> /boot/loader.conf",
    unless => "grep -q '^${title}=' /boot/loader.conf",
    path   => '/bin:/usr/bin',
  }
}

class xdm_display_manager {
  package { 'xdm': ensure => present }
  # FIXME: enable xdm in /etc/ttys
}

class fluxbox_window_manager {
  package { 'fluxbox': ensure => present }
}

class dvorak_keymap {
  rc_conf { 'kbdmap': content => 'us.dvorak.kbd' }
}

# X11 login manager: SLiM
class slim_login_manager {
  package { 'slim': ensure => present }
  rc_conf { 'slim_enable': content => 'YES' }
}

# X11 login manager
class login_manager($use) {
  case $use {
    'slim': { include slim_login_manager }
    default: { fail('Unknown login manager') }
  }
}

# Text editor
class text_editor($use) {
  case $use {
    'vim': { package { 'vim': ensure => present } }
    default: { fail('Unknown text editor') }
  }
}

# IDE
class ide($use) {
  case $use {
    'eclipse': { package { 'eclipse': ensure => present } }
    default: { fail('Unknown IDE') }
  }
}

class xinitrc {
  file { '/usr/local/etc/X11/xinit/xinitrc':
    content => "#!/bin/sh

# Chromium
xset fp+ /usr/local/share/fonts/Droid
xset fp rehash

setxkbmap ${::setxkbmap}
exec ${::xsession_manager}
",
    require => Package['xorg'],
  }
}

class firefox_web_browser {
  package { 'firefox': ensure => present }
}

class chromium_web_browser {
  package { 'chromium': ensure => present }
  sysctl { 'kern.ipc.shm_allow_removed': content => '1' }
}

class lxde_desktop {
  package { 'lxde-meta': ensure => present }
}

# Things required to run an X11 server
class x_server {
  include xdm_display_manager
  include xinitrc
  include fluxbox_window_manager

  # Enable Kernel Mode Setting (KMS)
  loader_conf { 'kern.vty': content => 'vt' }

  # TODO: add user to groups; see https://www.freebsd.org/doc/handbook/x-config.html

  package { 'xorg': ensure => present }
  package { 'urwfonts': ensure => present }

  package { 'dbus': ensure => present }
  rc_conf { 'dbus_enable': content => 'YES' }

  package { 'hal': ensure => present }
  rc_conf { 'hald_enable': content => 'YES' }
}

# Print documents to a printer
class printing {
  package { 'cups': ensure => present }
  rc_conf { 'lpd_enable': content => 'NO' }
  rc_conf { 'cupsd_enable': content => 'YES' }
}

# Use a sound card to make noise
class sound {
  package { 'pulseaudio': ensure => present }
  rc_conf { 'mixer_enable': content => 'YES' }
}

# Allow the user to mount removable media like USB drives
class removable_media {
  package { 'volman': ensure => present }
  rc_conf { 'volmand_enable': content => 'YES' }
  rc_conf { 'devd_enable': content => 'YES' }
}

# Zero-configuration networking
# https://en.wikipedia.org/wiki/Zero-configuration_networking
class zeroconf_networking {
  package { 'avahi': ensure => present }
  rc_conf { 'avahi_daemon_enable': content => 'YES' }
}

# Browse the web
class web_browser {
  include firefox_web_browser
  include chromium_web_browser
}

# Access files on the LAN
class network_attached_storage {
  # NFS RPC services
  rc_conf { 'rpc_lockd_enable': content => 'YES' }
  rc_conf { 'rpc_statd_enable': content => 'YES' }
  # NFS automounter
  package { 'automount': ensure => present }
  rc_conf { 'autofs_enable': content => 'YES' }
  # iSCSI
  rc_conf { 'iscsid_enable': content => 'YES' }
  # SMB
  package { 'samba42': ensure => present }
}

# Linux emulation
# https://www.freebsd.org/doc/handbook/linuxemu.html
class linux_emulation {
  exec { 'kldload linux64': 
    path   => '/bin:/usr/bin:/sbin:/usr/sbin',
    unless => 'kldstat | egrep -q linux64',
  }
  ->
  package { 'linux_base-c6': ensure => present }

  rc_conf { 'linux_enable': content => 'YES' }

# TODO: mount these:
#linprocfs   /compat/linux/proc	linprocfs	rw	0	0
#tmpfs    /compat/linux/dev/shm	tmpfs	rw,mode=1777	0	0
}

# Configure a MTA
# Desktops should keep mail locally, unless the administrator
# configures a relayhost.
class mail_transport_agent($enable = false) {
  if $enable {
    fail('Not implemented yet')
  } else {
    rc_conf { 'sendmail_enable': content => 'NO' }
    rc_conf { 'sendmail_submit_enable': content => 'NO' }
    rc_conf { 'sendmail_outbound_enable': content => 'NO' }
    rc_conf { 'sendmail_msp_queue_enable': content => 'NO' }
  }
}

class firewall($enable = false) {
  if $enable {
    fail('Not implemented yet')
    # TODO: need a simple default-deny ruleset
  } else {
    rc_conf { 'pf_enable': content => 'NO' }
    rc_conf { 'pflog_enable': content => 'NO' }
  }
  rc_conf { 'pf_flags': content => '' }
  rc_conf { 'pf_rules': content => '/etc/pf.conf' }
}

class movie_player {
  package { 'mplayer': ensure => present }
}

# Programs to deal with images and photos
class image_software {
  package { 'geeqie': ensure => present }
  package { 'gimp': ensure => present }
}

class sudo {
  package { 'sudo': ensure => present }
  # TODO: probably need to add a rule
}

class wireless_networking {
  # TODO: wpa_supplicant and kernel modules
}

# The source code for the base OS and the ports tree
class source_code {
  exec { "checkout_ports_tree":
    command => 'svn co https://svn.FreeBSD.org/ports/head /usr/ports',
    creates => '/usr/ports',
    path    => '/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin',
    require => Package['subversion'],
  }

  exec { "checkout_base_tree":
    command => 'svn co https://svn.FreeBSD.org/base/head /usr/src',
    creates => '/usr/src/.svn',
    path    => '/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin',
    require => Package['subversion'],
  }

  # TODO: could also checkout doc tree in /usr/doc
}

# Various tools needed for software development
class development_tools {
  package { 
    [
	'git',
	'subversion',
    ]:
	ensure => present
  }
}

# Run FreeBSD-update and 'pkg update' automatically
class automatic_updates {
  # TODO
}

include automatic_updates
include development_tools
include printing
include removable_media
include sound
if $::source_code { include source_code }
include sudo
include network_attached_storage
include zeroconf_networking
include web_browser
include linux_emulation
include mail_transport_agent
include firewall
include movie_player
include image_software
include wireless_networking
include x_server

include dvorak_keymap
include lxde_desktop
class { 'login_manager': use => $::login_manager }
class { 'text_editor': use => $::text_editor }
class { 'ide': use => $::ide }
