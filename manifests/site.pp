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
#    user=>$username,
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
            'nmap', 'wireshark', 'tshark',
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

package {['man-db', 'manpages',
          'rsyslog',
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

class mediaserver($directory="/srv/media") {
  package {'mediatomb': }
  service {'mediatomb':
    require=>[Package['mediatomb']],
    subscribe=>[File['/etc/default/mediatomb']],
    ensure=>running,
    enable=>true
  }
  file {'/etc/default/mediatomb':
    content=>"#
NO_START=no
OPTIONS=\"-a $directory\"
USER=mediatomb
GROUP=mediatomb
"
  }

  $zip = 'bubbleupnp.zip'
  fetch {$zip:
    url=>'http://www.bubblesoftapps.com/bubbleupnpserver/0.7/BubbleUPnPServer-0.7.zip',
    cwd=>'/usr/local/tarballs',
  }
  file {'/usr/local/lib/bubbleupnp':
    require=>Exec['bubbleupnp:install'],
    ensure=>directory,
    owner=>'bubbleupnp'
  }
  file {'/usr/local/lib/bubbleupnp/configuration.xml':
    require=>Exec['bubbleupnp:install'],
    ensure=>present,
    owner=>'bubbleupnp'
  }
  exec {'bubbleupnp:install':
    cwd=>'/usr/local/lib/bubbleupnp',
    command=>"/usr/bin/unzip /usr/local/tarballs/$zip",
    creates=>'/usr/local/lib/bubbleupnp/launch.sh'
  }

  user {'bubbleupnp':
    home=>'/usr/local/lib/bubbleupnp/',
    system=>true
  }

  service {'bubbleupnp':
    provider=>base,
    require=>User['bubbleupnp'],
    pattern=>'^java.+BubbleUPnPServer.jar$',
    ensure=>running, enable=>true,
    start=>'/bin/su bubbleupnp /usr/local/lib/bubbleupnp/launch.sh >>/var/log/bubbleupnp.log 2>&1 &',
    stop=>'/usr/bin/pkill -u bubbleupnp -f  BubbleUPnPServer.jar',
    status=>'/usr/bin/pgrep -u bubbleupnp -f  BubbleUPnPServer.jar',
    hasrestart=>false,
    hasstatus=>false
  }
}

file {'/usr/local/bin/xpathsubst':
  mode=>0755,
  source=>'puppet:///files/usr/local/bin/xpathsubst'
}

class opionatedbasesystem {
  include xorglibs
  include emacs
  include diagnostic
  include dev
  include ssh
  include ruby
  include runit
  include dan
  service {'rsyslog':
    ensure=>running, enable=>true
  }
}

class telent {
  package {'cups':}
  include opionatedbasesystem
  include lxc
  include media
  include android
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

class runit {
  package {'runit': }
}
define runit::script($script, $log_directory = "/var/log/$name") {
  file {["/etc/sv/$name","/etc/sv/$name/log"]: ensure=>directory}
  file {"/etc/sv/$name/run":
    content=>$script,
    mode=>0755,
    owner=>root
  }
  file {"/etc/sv/$name/log/run":
    content=>"#!/bin/sh\nexec svlogd $log_directory\n",
    mode=>0755,
    owner=>root
  }
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
    command=>"/bin/sh -c 'ulimit -t 120 && get_iplayer --output=$directory --subdir --versions=default --pvr '",
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

class collectd($listen_addr="192.168.0.2") {
  package {['collectd', 'librrd-dev']: }
  file {'/etc/collectd/collectd.conf.d/master.conf':
    content=>template("etc/collectd/collectd.conf")
  }
  service {'collectd':
    subscribe => File['/etc/collectd/collectd.conf.d/master.conf'],
    require => Package['collectd']
  }
}

class nfs {
  package {'nfs-kernel-server':}
  file {'/etc/exports.d':
    ensure=>directory
  }
  file {'/etc/exports':
    content=>"# please use /etc/exports.d\n"
  }
  service {'nfs-kernel-server':
    require => Service['rsyslog'],
  }
  exec {'exportfs-a':
    refreshonly=>true,
    command=>'/usr/sbin/exportfs -a'
  }    
}
define nfs::export($clients, $options=[]) {
  $opts = inline_template("<%= @options.join(',') %>")
  $fname = inline_template("<%= @title.tr('/','_') %>")
  file { "/etc/exports.d/$fname.exports":
    content=>"$title $clients($opts)\n",
    notify=>Exec['exportfs-a']
  }
}

class exim4($domain, $local_domains) {
  package {['exim4-base','exim4-dev', 'exim4-daemon-heavy',
            'spamassassin']:
  }
  user {'maildir':
    system=>true,
    ensure=>present
  }
  file {'/etc/default/spamassassin':
    source=>'puppet:///files/etc/default/spamassassin'
  }
  service {'spamassassin':,
    require=>[Package['spamassassin'],
              File['/etc/default/spamassassin']],
    ensure=>running,
    enable=>true
  }
  service {'exim4':
    require=>File['/etc/exim4/exim4.conf','/etc/exim4/passwd'],
    ensure=>running,
    enable=>true
  }
  file {'/etc/exim4/exim4.conf':
    content=>template("etc/exim4/exim4.conf")
  }
  exec {'exim4:make_passwd':
    cwd => '/etc/exim4',
    command=> '/usr/bin/perl -e \'while(($l,$p,$u)=getpwent()) {($u>=1000) && ($u<32767) && print "$l:$p\n"}\'  > /etc/exim4/passwd',
    creates => '/etc/exim4/passwd'
  }
  file {'/etc/exim4/passwd':
    require=>Exec['exim4:make_passwd'],
    mode=>'0440',
    owner=>root,
    group=>'Debian-exim'
  }
  file {'/var/maildir':
    ensure=>directory, 
    mode=>0755, owner=>'maildir', group=>'root'
  }
}

class bytemarkdns {
  file {'/usr/local/etc/dns':
    ensure=>directory
  }
  file {'/usr/local/etc/dns/Makefile':
    source=>'puppet:///files/usr/local/etc/dns/Makefile'
  }
}

class jabber($host,$admin_user) {
  package {'ejabberd': }
  file {'/etc/ejabberd/ejabberd.cfg':
    content=>template("etc/ejabberd/ejabberd.cfg"),
    owner=>ejabberd,
    group=>ejabberd,
    mode=>0400
  }
  service {'ejabberd':
    hasstatus=>false,
    enable=>true, ensure=>running
  }
}

class nginx {
  package {'nginx': }
  service {'nginx':
    ensure=>running, enable=>true,
    require=>Package['nginx'] }
}

define nginx::reverse_proxy($hostname = $title, $backend_ports, $enable=true) {
  file {"/etc/nginx/sites-available/$hostname":
    content=>template("etc/nginx/reverse-proxy")
  }
  file {"/etc/nginx/sites-enabled/$hostname":
    ensure => $enable ? { true => 'symlink', false => 'absent' },
    target => "/etc/nginx/sites-available/$hostname",
    notify=>Service['nginx']
  }
}


class my-way {
  nginx::reverse_proxy {'ww.telent.net':
    backend_ports=>[4567,4568],
  }
  user {'my-way':
    ensure=>present,
    managehome=>true
  }
  gitrepo {'my-way':
    require=>User['my-way'],
    repo => '/home/git/my-way.git',
    username => 'my-way',
    parentdirectory => '/home/my-way/'  
  }
  exec {'my-way:install':
    refreshonly=>true,
    subscribe=>Gitrepo['my-way'],
    cwd => '/home/my-way/my-way',
    logoutput=>true,
    timeout=>120,
    command=>'/bin/su -l my-way -s /bin/bash -c "cd /home/my-way/my-way && chruby ruby && bundle install --deployment"'
  }
  runit::script {'my-way':
    script=>'#!/bin/bash
exec 2>&1
cd /home/my-way/my-way
. /usr/local/share/chruby/chruby.sh
chruby ruby-2.0.0 
export LANG=en_GB.UTF-8
exec chpst -u my-way -v bundle exec ruby -I lib bin/my-way.rb
',
    log_directory=>'/var/log/my-way'
  }
  service {'my-way':
    require=>Runit::Script['my-way'],
    provider=>runit,
    enable=>true, ensure=>running
  }
}

node 'sehll' {
  include opinionatedbasesystem
  include bytemarkdns
  class {'jabber':
    host=>'telent.net',
    admin_user=>'admin'
  }
  include nginx
  include my-way
  
  class {'exim4':
    local_domains => ['coruskate.net','btyemark.telent.net','firebrox.com'],
    domain => 'telent.net'
  }
  service {'rsyslog': }
}
import 'private/*.pp'

node 'loaclhost' {
  include telent
  include xorglibs
  include githost
  include mediaserver
  include eth0
  include collectd
  package {'lm-sensors': }
  exec {'coretemp':
    command=>"/bin/echo coretemp >>/etc/modules",
    unless=>'/bin/grep coretemp /etc/modules'
  }		       
  include nfs
  nfs::export {
    "/srv/media":
      options=>["no_subtree_check","ro"],
      clients=>"192.168.0.0/24"
  }
  nfs::export {
    "/srv/nfsroot/pi":
      options=>["no_subtree_check","no_root_squash","rw"],
      clients=>"192.168.0.137"
  }
  class {'iplayer': }
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
  
  mount {'swap':
    name=>'none',
    atboot=>true,
    device=>'/dev/disk/by-label/SWAP',
    fstype=>'swap',
    options=>'defaults',
    ensure=>present
  }
  exec {'swapon':
    subscribe=>Mount['swap'],
    refreshonly=>true,
    command=>'/sbin/swapon -a'
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
