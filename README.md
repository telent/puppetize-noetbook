# I accidentally the whole puppet

Puppet manifests to install everything I want on my notebook (called
noetbook) and shell machine (called loaclhost).  In toto this is
probably more use to me than to anyone else on the planet, but if you
are looking for a grab-bag of low-ceremony puppet snippets to do
things like

* have a Samsung Series 9 running Debian
* or a desktop box based on an Asus P5Q-EM mobo
* use xfce4 and sawfish as an X desktop
* like to build your own emacs
* write Clojure
* have the username 'dan'

then you might find it useful.  If you do some but not all those things you
might find some but not all of it useful

## Installation

These steps are approximate and not regularly tested.

For `notebook`: I install debian interactively, deselecting all the
task groups to get a minimal system.  Then I logged in as root.

For `loaclhost`, I installed from an existing debian system 

* mkfs and mount the new machine's disk under `/newroot`
* run debootstrap : `sudo debootstrap  --include=git,puppet,ssh --variant=minbase jessie /newroot http://localhost:3142/ftp.debian.org/debian/`
* `chroot /newroot /bin/bash`

For both systems, I then did

1. `apt-get install git puppet ssh ca-certificates`
1. `cd /etc && mv puppet oldpuppet && git clone https://github.com:telent/puppetize-noetbook.git puppet`
1. `sudo make -C /etc/puppet/`

