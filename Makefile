MODULEPATH=`pwd`/modules
TEMPLATEDIR=`pwd`/templates
ifdef DEBUG
DEBUG_FLAG=--debug --color=no
endif

all:
	puppet apply --modulepath=$(MODULEPATH) --templatedir=$(TEMPLATEDIR) manifests/site.pp $(DEBUG_FLAG)
