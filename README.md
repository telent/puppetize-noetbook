# puppetize my notebook

This is probably more use to me than to anyone else on the planet, but if you

* have a Samsung Series 9 running Debian
* use xfce4 and sawfish as an X desktop
* like to build your own emacs
* write Clojure
* have the username 'dan'

then you might find it useful.  If you do some but not all those things you
might find some but not all of it useful

## Installation

These steps are approximate and have not _actually_ been tested.

1. Install Debian 7.1.0.  Deselect all the task groups to get a minimal system.  Maybe you can do this with `sudo debootstrap  --include=git,puppet,ssh --variant=minbase jessie /newroot http://localhost:3142/ftp.debian.org/debian/`
1. `apt-get install git puppet ssh`
1. `cd /etc && mv puppet oldpuppet && git clone git@github.com:telent/puppetize-noetbook.git puppet`
1. `puppet apply /etc/puppet/manifests/site.pp`


