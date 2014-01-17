include password.mk

ifndef RSYNC_USERNAME
$(error RSYNC_USERNAME is not set in password.mk)
endif
ifndef RSYNC_PASSWORD
$(error RSYNC_PASSWORD is not set in password.mk)
endif

all: upload

download:
	test -d zones || mkdir zones
	RSYNC_PASSWORD=$(RSYNC_PASSWORD) rsync -av dns@upload.ns.bytemark.co.uk::$(RSYNC_USERNAME) zones

upload:
	RSYNC_PASSWORD=$(RSYNC_PASSWORD) rsync -v zones/* dns@upload.ns.bytemark.co.uk::$(RSYNC_USERNAME)/

