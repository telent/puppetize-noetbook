Exec {
  logoutput=>on_failure
}
define fetch($url,$cwd) {
  exec{"fetch-$title": 
    command=>"/usr/bin/curl -L \"$url\" -o $name",
    cwd=>$cwd,
    require=>Package['curl'],
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


file {'/etc/network/interfaces':
  source=>'puppet:///files/etc/network/interfaces',
  group=>root,
  owner=>root,
  mode=>0644
}
file {'/etc/wpa_supplicant.conf':
  source=>'puppet:///files/etc/wpa_supplicant.conf',
  owner=>root,
  replace=>false
}

package {'curl':}
class sudo {
  package {'sudo': }
  user {'dan': groups=>['sudo'] }
}
include sudo

class emacs {
  fetch { 'emacs.tar.xz':
    url=> 'http://ftpmirror.gnu.org/emacs/emacs-24.3.tar.xz',
    cwd=>'/tmp'
  }
  file { '/usr/local/src/emacs': ensure=>directory }
  exec { 'emacs:build':
    cwd=>'/usr/local/src/emacs',
    command=>'/bin/tar xf /tmp/emacs.tar.xz && cd emacs-24.3 && ./configure && make && make install',
    creates=>'/usr/local/bin/emacs',
    require=>[Package['xorg-dev'] , File['/usr/local/src/emacs'], Fetch['emacs.tar.xz']],
  }
  package {['libgif-dev', 'libncurses5-dev', 'libjpeg8-dev', 
            'libpng12-dev', 'libtiff5-dev']: }
}
include emacs

class xorg {
  package {['xorg', 'xorg-dev', 'xserver-xorg-video-intel', 'xfce4-session', 'sawfish', 'sawfish-lisp-source', 'lightdm','menu', 'xfce4-power-manager']:}
  service {'lightdm':
    enable=>true
  }
  file {'/etc/X11/xorg.conf.d':
    ensure=>directory,
    recurse=>true,
    owner=>root,
    source=>'puppet:///files/etc/X11/xorg.conf.d'
  }

# http://software.clapper.org/cheat-sheets/xfce.html
  file {'/home/dan/.config/autostart/caps-lock-is-ctrl.desktop':
    owner=>'dan',
    content=>"[Desktop Entry]
Encoding=UTF-8
Version=0.9.4
Type=Application
Name=Caps Lock -> Control
Comment=Make Caps Lock a second Ctrl key
Exec=/usr/bin/setxkbmap -option 'ctrl:nocaps'
StartupNotify=false
Terminal=false
Hidden=false

"
  }
  file {'/home/dan/.config/autostart/xrdb.desktop':
    owner=>'dan',
    content=>"[Desktop Entry]
Encoding=UTF-8
Version=0.9.4
Type=Application
Name=xrdb
Comment=Load Xrdb defaults
Exec=/usr/bin/xrdb .Xdefaults
StartupNotify=false
Terminal=false
Hidden=false

"
  }
}
include xorg

class diagnostic {
  package {['lshw','sysstat','powertop','mbr','nmap','wireshark', 'iftop']: }
}
include diagnostic

class laptop {
  package {['pm-utils']:
  }
}
include laptop

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
include ssd


class dev {
  package {['strace', 'git','gcc','build-essential','make', 'kernel-package',
            'bc' # strange but true: kernel compilation needs this
            ]:
  }
}
include dev

class ssh {
  package {['openssh-server']: }
  service {'ssh':
    enable=>true, ensure=>running
  }
}
include ssh

class lxc {
  package {['lxc','bridge-utils', 'libvirt-bin', 'debootstrap']:}
}
include lxc

package {['units','xpdf','midori']: ensure=>installed }

class firefox {
  fetch { 'firefox.tar.bz2':
    url=> 'http://ftp.mozilla.org/pub/mozilla.org/firefox/releases/latest/linux-x86_64/en-GB/firefox-24.0.tar.bz2',
    cwd=>'/tmp'
  }
  exec { 'firefox:install':
    subscribe => Fetch['firefox.tar.bz2'],                     
    cwd=>'/usr/local/lib/',
    command=>'/bin/tar xf /tmp/firefox.tar.bz2',
    creates=>'/usr/local/lib/firefox/firefox',
  }
  file {'/usr/local/bin/firefox':
    ensure=>link, 
    target => '/usr/local/lib/firefox/firefox',
  }
}
include firefox

class media {
  package {'mplayer': }
}
include media

class android {
  fetch {'android-sdk.tgz':
    url=>'http://dl.google.com/android/android-sdk_r22.0.5-linux.tgz',
    cwd=>'/tmp'
  }
  exec { 'android:install':
    require=>Fetch['android-sdk.tgz'],
    cwd=>'/usr/local/lib/',
    command=>'/bin/tar xf /tmp/android-sdk.tgz && /bin/chmod -R go+rwX /usr/local/lib/android-sdk-linux/',
    creates=>'/usr/local/lib/android-sdk-linux/tools/android',
  }
  file {'/etc/profile.d/android.sh':
    mode=>0755,
    content=>"#!/bin/sh\nPATH=/usr/local/lib/android-sdk-linux/tools/:/usr/local/lib/android-sdk-linux/platform-tools/:\$PATH\n"
  }
}

gitrepo { 'dotfiles':
  repo=> 'https://github.com/telent/dotfiles',
  parentdirectory=>'/home/dan/',
  username=>'dan'
}
exec { 'install-dotfiles':
  subscribe=>Gitrepo['dotfiles'],
  command=>'/usr/bin/make -C /home/dan/dotfiles',
  creates=>'/home/dan/.dotfiles-installed'
}
include android

file {['/home/dan/bin', '/home/dan/src']: 
  ensure=>directory,
  owner=>'dan' 
}

class clojure {
  fetch {'lein':
    require=>[File['/home/dan/bin']],
    url=>'https://raw.github.com/technomancy/leiningen/stable/bin/lein',
    cwd=>'/home/dan/bin'
  }
  package {'unzip': } # to unzip JAR file scontaining source code
  file {'/home/dan/bin/lein':
    require=>[File['/home/dan/bin'],Fetch['lein']],
    owner=>dan,
    mode=>0755
  }
  package {'default-jdk': }
}
include clojure


package {'xtightvncviewer':}
