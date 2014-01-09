MODULEPATH=`pwd`/modules
all:
	puppet apply --modulepath=$(MODULEPATH) manifests/site.pp
