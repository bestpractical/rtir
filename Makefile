# Location of perl on your system
PERL                    =       /usr/bin/perl

# This is the group that all of the installed files will be chgrp'ed to.
RTGROUP			=	rt


# User which should own rt binaries.
BIN_OWNER		=	root

RT_ROOT			=	/opt/rt3
RT_HTML_PATH		=	$(RT_ROOT)/share/html
RT_SBIN_PATH		=	$(RT_ROOT)/sbin
DBA			=	root
RTIR_CONFIG_FILE	= 	$(RT_ROOT)/etc/RTIR_Config.pm
TAG			=       rtir-1-0-5rc1


install: config-install install-html instruct

config-install:
	[ -f $(RTIR_CONFIG_FILE) ] || cp etc/RTIR_Config.pm $(RTIR_CONFIG_FILE)
	chgrp $(RTGROUP) $(RTIR_CONFIG_FILE)
	chown $(BIN_OWNER) $(DESTDIR)/$(RTIR_CONFIG_FILE)
	chmod 0550 $(DESTDIR)/$(RTIR_CONFIG_FILE)

	@echo "Installed configuration. about to install RTIR in  $(RT_ROOT)"

install-html:
	mkdir -p $(RT_HTML_PATH)
	cp -R html/* $(RT_HTML_PATH)/
	find $(RT_HTML_PATH)/RTIR -type d |xargs chmod 755
	find $(RT_HTML_PATH)/RTIR -type f |xargs chmod 644
	find $(RT_HTML_PATH)/Callbacks/RTIR -type d |xargs chmod 755
	find $(RT_HTML_PATH)/Callbacks/RTIR -type f |xargs chmod 644
	cp -R lib/RT/Condition/* $(RT_ROOT)/lib/RT/Condition/
	find $(RT_ROOT)/lib/RT/Condition -type d |xargs chmod 755
	find $(RT_ROOT)/lib/RT/Condition -type f |xargs chmod 644
	cp -R lib/RT/Action/* $(RT_ROOT)/lib/RT/Action/
	find $(RT_ROOT)/lib/RT/Action -type d |xargs chmod 755
	find $(RT_ROOT)/lib/RT/Action -type f |xargs chmod 644

instruct:
	@echo ""
	@echo "Congratulations. RTIR has been installed. "
	@echo ""
	@echo "You must now edit the file $(RT_ROOT)/etc/RT_SiteConfig.pm as described"
	@echo "in the README, then stop and start your web server."
	@echo ""
	@echo "After that, you need to initialize RTIR's database by running" 
	@echo " 'make initdb'"


initdb:
	$(RT_SBIN_PATH)/rt-setup-database --datafile etc/initialdata --dba $(DBA) --prompt-for-dba-password --action insert		


tag-and-release-baseline:
	aegis -cp -ind Makefile -output /tmp/Makefile.tagandrelease; \
	$(MAKE) -f /tmp/Makefile.tagandrelease tag-and-release-never-by-hand


# Running this target in a working directory is 
# WRONG WRONG WRONG.
# it will tag the current baseline with the version of RT defined 
# in the currently-being-worked-on makefile. which is wrong.
#you want tag-and-release-baseline

tag-and-release-never-by-hand:
	aegis --delta-name $(TAG)
	rm -rf /tmp/$(TAG)
	mkdir /tmp/$(TAG)
	cd /tmp/$(TAG); \
			 aegis -cp -ind -delta $(TAG) . ;\
			 chmod 600 Makefile;\
			 aegis --report --project rtir.1 --change 0 \
				--page_width 80 \
				--page_length 9999 \
				--output Changelog Change_Log;

	cd /tmp; tar czvf /home/ftp/pub/rt/devel/$(TAG).tar.gz $(TAG)/
	chmod 644 /home/ftp/pub/rt/devel/$(TAG).tar.gz

regression: 
	$(PERL) lib/t/02regression.t

upgrade: config-install install-html upgrade-instruct

upgrade-instruct: 
	@echo "Congratulations. RTIR has been upgraded."
	@echo "You should update RTIR's system database objects by running "
	@echo "   ls etc/upgrade"
	@echo ""
	@echo "For each item in that directory whose name is greater than"
	@echo "your previously installed RT version, run:"
	@echo "	   $(RT_SBIN_PATH)/rt-setup-database --dba $(DB_DBA) --prompt-for-dba-password --action insert --datadir etc/upgrade/<version>"
upgrade-instruct: 

