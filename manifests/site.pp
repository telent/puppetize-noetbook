Exec {
  logoutput=>on_failure
}
define fetch($url,$cwd) {
  exec{"fetch-$title": 
    command=>"/usr/bin/curl -L \"$url\" -o $name",
    cwd=>$cwd,
    require=>[File[$cwd],Package['curl']],
    creates=>"$cwd/$name"
  }
}

define gitrepo($repo, $parentdirectory, $username='root', $branch='master') {
  exec {"gitrepo/$title/clone":
    require=>[Package['git']],
    cwd=>$parentdirectory,
    creates=>"$parentdirectory/$title/.git",
    command=>"/usr/bin/git clone --branch=$branch $repo $parentdirectory/$title",
    user=>$username,
  }
  exec {"gitrepo/$title/pull":
    user=>$username,
    require=>Exec["gitrepo/$title/clone"],
    cwd=>"$parentdirectory/$title",
    command=>"/bin/su -l -c \"cd $parentdirectory/$title ; /usr/bin/git pull \" $username ",
    onlyif=>"/bin/su -l -c \"cd $parentdirectory/$title ; ( git remote update ; git status -uno ) |grep behind \" $username ",
  }
}

file {'/usr/local/tarballs':
  ensure=>directory
}
class wlan0 {
  file {'/etc/network/interfaces':
    source=>'puppet:///files/etc/network/interfaces.wlan0',
    group=>root,
    owner=>root,
    mode=>0644
  }
  file {'/etc/wpa_supplicant.conf':
    source=>'puppet:///files/etc/wpa_supplicant.conf',
    owner=>root,
    replace=>false
  }
}
class eth0 {
  file {'/etc/network/interfaces':
    source=>'puppet:///files/etc/network/interfaces.eth0',
    group=>root,
    owner=>root,
    mode=>0644
  }
}


package {'sudo': }

class emacs {
  fetch { 'emacs.tar.xz':
    url=> 'http://ftpmirror.gnu.org/emacs/emacs-24.3.tar.xz',
    cwd=>'/usr/local/tarballs'
  }
  file { '/usr/local/src/emacs': ensure=>directory }
  exec { 'emacs:build':
    cwd=>'/usr/local/src/emacs',
    command=>'/bin/tar xf /usr/local/tarballs/emacs.tar.xz && cd emacs-24.3 && ./configure && make && make install',
    creates=>'/usr/local/bin/emacs',
    require=>[Package['xorg-dev'] , File['/usr/local/src/emacs'], Fetch['emacs.tar.xz']],
  }
  package {['libgif-dev', 'libncurses5-dev', 'libjpeg8-dev', 
            'libpng12-dev', 'libtiff5-dev']:
              before=>Exec['emacs:build']
  }
}

class xorglibs {
  package {['xorg', 'xorg-dev']: }
}

class xorg {
  include xorglibs
  package {['xserver-xorg-video-intel', 'xfce4-session', 'sawfish', 'sawfish-lisp-source', 'lightdm','menu', 'xfce4-power-manager']:}
  service {'lightdm':
    enable=>true
  }
  file {'/etc/X11/xorg.conf.d':
    ensure=>directory,
    recurse=>true,
    owner=>root,
    source=>'puppet:///files/etc/X11/xorg.conf.d'
  }
}

class diagnostic {
  package {['lshw', 'sysstat', 'powertop', 'mbr',
            'nmap', 'wireshark',
  	    'iputils-ping', 'xdiskusage', 'iftop']: }
}

class laptop {
  package {['pm-utils']:
  }
}

class ssd {
  package {['smartmontools']: }
  file {'/etc/udev/rules.d/60-io-scheduler.rules':
    # from pixelchaos.net
    content=>'# puppet
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0",
ATTR{queue/scheduler}="noop"
'
  }
}

class dev {
  package {['strace', 'git','gcc','build-essential','make', 'kernel-package',
            'bc' # strange but true: kernel compilation needs this
            ]:
  }
}

class ssh {
  package {['openssh-server','mosh']: }
  service {'ssh':
    enable=>true, ensure=>running
  }
}

class lxc {
  package {['lxc','bridge-utils', 'libvirt-bin', 'debootstrap']:}
}

class firefox {
  fetch { 'firefox.tar.bz2':
    url=> 'http://ftp.mozilla.org/pub/mozilla.org/firefox/releases/26.0/linux-x86_64/en-GB/firefox-26.0.tar.bz2',
    cwd=>'/usr/local/tarballs'
  }
  exec { 'firefox:install':
    subscribe => Fetch['firefox.tar.bz2'],                     
    cwd=>'/usr/local/lib/',
    command=>'/bin/tar xf /usr/local/tarballs/firefox.tar.bz2',
    creates=>'/usr/local/lib/firefox/firefox',
  }
  file {'/usr/local/bin/firefox':
    ensure=>link, 
    target => '/usr/local/lib/firefox/firefox',
  }
}

class ruby {
  fetch {'chruby.tar.gz':
   url => 'https://github.com/postmodern/chruby/archive/v0.3.7.tar.gz',
   cwd => '/usr/local/tarballs',
  }
  exec { 'chruby:install':
    subscribe => Fetch['chruby.tar.gz'],
    cwd=>'/usr/local/src/',
    command=>'/bin/tar xzf ../tarballs/chruby.tar.gz && make -C chruby-0.3.7 install',
    creates=>'/usr/local/share/chruby/chruby.sh',
  }
  file { '/etc/profile.d/chruby.sh':
    mode=>0755,
    content=>"# the script this sources doesn't work in plain bourne shell\ntype help >/dev/null 2>&1 && . /usr/local/share/chruby/chruby.sh\n"
  }
  fetch {'ruby-install.tar.gz':
   url => 'https://github.com/postmodern/ruby-install/archive/v0.3.4.tar.gz',
   cwd => '/usr/local/tarballs',
  }
  exec { 'ruby-install:install':
    subscribe => Fetch['ruby-install.tar.gz'],      
    cwd=>'/usr/local/src/',
    command=>'/bin/tar xzf ../tarballs/ruby-install.tar.gz && make -C ruby-install-0.3.4 install',
    refreshonly=>true,
#    creates=>'/usr/local/bin/ruby-install',
  }
}

class media {
  package {'mplayer': }
}

class android {
  fetch {'android-sdk.tgz':
    url=>'http://dl.google.com/android/android-sdk_r22.0.5-linux.tgz',
    cwd=>'/usr/local/tarballs'
  }
  exec { 'android:install':
    require=>Fetch['android-sdk.tgz'],
    cwd=>'/usr/local/lib/',
    command=>'/bin/tar xf /usr/local/tarballs/android-sdk.tgz && /bin/chmod -R go+rwX /usr/local/lib/android-sdk-linux/',
    creates=>'/usr/local/lib/android-sdk-linux/tools/android',
  }
  file {'/etc/profile.d/android.sh':
    mode=>0755,
    content=>"#!/bin/sh\nPATH=/usr/local/lib/android-sdk-linux/tools/:/usr/local/lib/android-sdk-linux/platform-tools/:\$PATH\n"
  }
}

class dan {
  user {'dan':
    require=>Package['sudo'],
    groups=>['sudo'],
    managehome=>true,
    shell=>'/bin/bash',
    ensure=>present
  }
  gitrepo { 'dotfiles':
    require => User['dan'],
    repo=> 'https://github.com/telent/dotfiles',
    parentdirectory=>'/home/dan/',
    username=>'dan'
  }
  exec { 'install-dotfiles':
    subscribe=>Gitrepo['dotfiles'],
    command=>'/bin/su -l dan -c "/usr/bin/make -C /home/dan/dotfiles"',
    creates=>'/home/dan/.dotfiles-installed'
  }
}

file {'/usr/local/bin':
  ensure=>directory
}
class clojure {
  package {'openjdk-7-jdk': }
  fetch {'lein':
    url=>'https://raw.github.com/technomancy/leiningen/stable/bin/lein',
    cwd=>'/usr/local/bin'
  }
  package {'unzip': } # to unzip JAR file scontaining source code
  file {'/usr/local/bin/lein':
    require=>[Fetch['lein']],
    mode=>0755
  }
}

package {['cups',
          'man-db', 'manpages',
	  'tmux',	 
	  'xtightvncviewer',
          'units',
          #~'xpdf',
          'curl',
          'whois',
	  'irssi',
	  'nvi',
          'ifupdown',
	  'less',
          'rsync',]:
            ensure=>installed
}

class githost {
  file {'/home/git': ensure=>directory}
}

class mediaserver {
  package {'mediatomb': }
}

class telent {
  include emacs
  include diagnostic
  include dev
  include ssh
  include lxc
  include ruby
  include media
  include android
  include dan
  include clojure
  group {'media': 
    system=>true,
    ensure=>present
  }
}

node 'noetbook' {
  include telent
  include xorg
  include laptop
  include ssd
  include firefox
  include wlan0
}

class kernel($version) {
  package {"linux-image-$version": }
  package {'extlinux': }
  
  file {'/etc/default/extlinux': 
    content=>'EXTLINUX_UPDATE="false"
'
  }
  file {'/boot/syslinux.cfg':
    require=>Mount['/boot'],
    content=>"# PVPPET ME FACIT
DEFAULT l0

label l0
        menu label Debian GNU/Linux, kernel $version
        linux vmlinuz-$version
        append initrd=initrd.img-$version ro root=LABEL=ROOT

label l0r
        menu label Debian GNU/Linux, kernel $version (recovery mode)
        linux vmlinuz-$version
        append initrd=initrd.img-$version ro single root=LABEL=ROOT
        text help
   This option boots the system into recovery mode (single-user)
        endtext
 "
  }
}  

class iplayer($group='media', $directory="/srv/media/video/") {
  package {['get-iplayer', 'libav-tools']: }
  user {'iplayer':
    require=>Group[$group],
    system=>true,
    groups=>$group,
    home=>$directory
  }
  cron { iplayer:
    command=>"get_iplayer --output=$directory --subdir --versions=default --pvr --quiet",
    user => 'iplayer',
    minute=>10, hour=>6
  }
}

class dumbmail($smarthost, $maildomain="telent.net") {
  package { ['msmtp', 'msmtp-mta']: }
  file {'/etc/msmtprc':
    mode=>0644,
    content=>"# ex puppet
account default
host $smarthost
maildomain $maildomain
auto_from on
syslog LOG_MAIL
"    
  }
}


node 'loaclhost' {
  include telent
  include xorglibs
  include githost
  include mediaserver
  include eth0
  include iplayer
  package {'udev':}
  package {'apt-cacher': }
  file {'/etc/apt-cacher/conf.d/allow_local_net.conf':
    content=>"# ex puppet\nallowed_hosts = 192.168.0.0/24\n"
  }
  class {'dumbmail':
    smarthost => 'btyemark.telent.net'
  }
  
  mount {'/':
    atboot=>true,
    device=>'/dev/disk/by-label/ROOT',
    fstype=>'ext4',
    options=>'defaults',
    ensure=>present
  }
  package {'mdadm': }
  file {'/raid': ensure=>directory }
  mount {'/raid':
    require=>File['/raid'],
    ensure=>mounted,
    atboot=>true,
    options=>'defaults',
    device=>'/dev/disk/by-label/RAID',
    fstype=>'ext4'
  }

  class { 'kernel':
    require => Mount['/boot'],
    version => '3.12-1-amd64'
  }

  file {'/boot': ensure=>directory }
  mount {'/boot':
    ensure=>mounted,
    atboot=>true,
    device=>'/dev/disk/by-label/BOOT',
    fstype=>'ext4',
    options=>'defaults',
  } 
   
  mount {'/home/':
    require=>Mount['/raid'],
    ensure=>mounted,
    atboot=>true,
    device=>'/raid/loaclhost/home/',
    fstype=>'none',
    options=>'bind',
    before=>User['dan']
  }

  mount {'/srv/':
    require=>Mount['/raid'],
    ensure=>mounted,
    atboot=>true,
    device=>'/raid/big/',
    fstype=>'none',
    options=>'bind',
  }

  file {'/srv/media':
    mode=>'g+s',
    group=>'media'
  }

  package {'watchdog': }
  service {'watchdog':
    enable=>true, ensure=>running
  }
    
}
