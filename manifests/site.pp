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
file {'/etc/network/interfaces':
  source=>'puppet:///files/etc/network/interfaces'
}
file {'/etc/X11/xorg.conf.d':
  ensure=>directory,
  recurse=>true,
  source=>'puppet:///files/etc/X11/xorg.conf.d'
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
  package {['xorg', 'xorg-dev', 'xserver-xorg-video-intel', 'xfce4-session', 'sawfish', 'lightdm','menu', 'xfce4-power-manager']:}
  service {'lightdm':
    enable=>true
  }
}
include xorg

class diagnostic {
  package {['lshw','sysstat','powertop']: }
}
include diagnostic

class laptop {
  package {['pm-utils']: }
}
include laptop

class dev {
  package {['strace', 'git','gcc','build-essential','make']:
  }
}
include dev

package {'midori': ensure=>installed }

class firefox {
  fetch { 'firefox.tar.bz2':
    url=> 'http://releases.mozilla.org/pub/mozilla.org/firefox/releases/latest/linux-x86_64/en-GB/firefox-22.0.tar.bz2',
    cwd=>'/tmp'
  }
  exec { 'firefox:install':
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

# todo:
# 1) map caps lock as control
# 2) install dotfiles

