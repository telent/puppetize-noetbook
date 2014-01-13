MODULEPATH=`pwd`/modules
TEMPLATEDIR=`pwd`/templates

all:
	puppet apply --modulepath=$(MODULEPATH) --templatedir=$(TEMPLATEDIR) manifests/site.pp
