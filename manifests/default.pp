### GLOBAL VARIABLES
#
$user = 'mark'
$setxkbmap = 'dvorak'
$desktop_environment = 'kde5'
$login_manager = 'sddm'
$text_editor = 'vim'
$ide = 'eclipse'

# The office suite to use
$office_suite = 'libreoffice'

# Checkout the HEAD of the src and ports trees
# *WARNING* takes a lot of space
$source_code = true

# Load the Nvidia driver (only enable this if you have a Nvidia card)
$nvidia_driver = true

# Set the default sound card device. Run "cat /dev/sndstat" to list them
$default_sound_device=5

# Install remote access utilities (tmux, etc.)
$remote_access = true

#
####################

define rc_conf($content) {
  augeas { "rc_conf/${title}":
     context => "/files/etc/rc.conf",
     onlyif  => "get ${title} != '${content}'",
     changes => "set ${title} '\"${content}\"'",
   }
}

# FIXME: broken because it puts spaces between vars
# tiem for 'puppet module install' ?
define sysctl($content) {
  augeas { "sysctl/${title}":
     incl    => "/etc/sysctl.conf",
     lens    => "Sysctl.lns",
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

define svn_repo($uri, $target) {
  exec { "svn_repo_${title}":
    command => "svn checkout ${uri} ${target}",
    creates => "${target}/.svn",
    path    => '/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin',
    timeout => 1800,
    require => Package['subversion'],
  }
}

class fluxbox_window_manager {
  package { 'fluxbox': ensure => present }
}

class dvorak_keymap {
  rc_conf { 'kbdmap': content => 'us.dvorak.kbd' }
}

class desktop_environment($use = $::desktop_environment) {
  case $use {
    'kde': {
      package { 'kde': ensure => present }
    }
    'kde5': {
      # TODO: Big complicated build process
    }
    default: { fail('Unknown DE') }
  }
}

# X11 login manager
class login_manager($use = $::login_manager) {
  case $use {
    'kdm': { rc_conf { 'kdm4_enable': content => 'YES' } }
    'sddm': { warning('TODO: enable SDDM') }
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

class office_suite($use = $::office_suite) {
  package { 'libreoffice': ensure => present }
}

class firefox_web_browser {
  package { 'firefox': ensure => present }
}

class chromium_web_browser {
  package { 'chromium': ensure => present }
  sysctl { 'kern.ipc.shm_allow_removed': content => '1' }
}

class remote_access($enable = $::remote_access) {
  package { 'tmux': ensure => present }
  # TODO: install and enable sshd
}

# Things required to run an X11 server
class x_server {
  # A backup WM, in case KDE is messed up
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
class sound($device = $::default_sound_device) {
  package { 'pulseaudio': ensure => present }
  rc_conf { 'mixer_enable': content => 'YES' }

  # Set the default soundcard
  sysctl { 'hw.snd.default_unit': content => $device }

  # FIXME: the grep & echo does not account for changing $device multiple times
  # This also seems to be unnecessary if the sysctl points to the right device
  #exec { "/bin/sh -c 'echo \"set-default-sink ${device} # Puppet-default-sink\" >> /usr/local/etc/pulse/default.pa'":
  #  unless => "/usr/bin/grep -q Puppet-default-sink /usr/local/etc/pulse/default.pa",
  #}
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

class file_manager {
  package { 'Thunar': ensure => present }
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

# FreeBSD source code
class source_code($enable = $::source_code) {
  svn_repo { "ports":
    uri => "https://svn.FreeBSD.org/ports/head",
    target => "/usr/ports",
  }
  ->
  svn_repo { "base":
    uri => "https://svn.FreeBSD.org/base/stable/11",
    target => "/usr/src",
  }
  ->
  svn_repo { "doc":
    uri => "https://svn.FreeBSD.org/doc/head",
    target => "/usr/doc",
  }
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

class nvidia_driver($enable = $::nvidia_driver) {
  if ($enable) {
    package { 'nvidia-driver': ensure => present }
    package { 'nvidia-settings': ensure => present }

    package { 'nvidia-xconfig': ensure => present }
    ->
    exec { 'nvidia-xconfig': 
      path   => '/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin',
      creates => '/etc/X11/xorg.conf',
    }
    
    rc_conf { 'kld_list': content => 'nvidia nvidia-modeset' }
  }
}

class zfs {
  rc_conf { 'zfs_enable': content => 'YES' }
}

include automatic_updates
include development_tools
include desktop_environment
include file_manager
include network_attached_storage
include nvidia_driver
include office_suite
include printing
include remote_access
include removable_media
include sound
include source_code
include sudo
include zeroconf_networking
include web_browser
include linux_emulation
include login_manager
include mail_transport_agent
include firewall
include movie_player
include image_software
include wireless_networking
include x_server
include zfs

include dvorak_keymap
class { 'text_editor': use => $::text_editor }
class { 'ide': use => $::ide }
