# This is the group that all of the installed files will be chgrp'ed to.
RTGROUP			=	rt


# User which should own rt binaries.
BIN_OWNER		=	root

RT_ROOT			=	/opt/rt3
RT_HTML_PATH		=	$(RT_ROOT)/local/html
RT_SBIN_PATH		=	$(RT_ROOT)/sbin
DBA			=	root
SITE_CONFIG_RTIR_FILE	= 	$(RT_ROOT)/etc/RT_SiteConfig_RTIR.pm


install: config-install install-html instruct

config-install:
	[ -f $(SITE_CONFIG_RTIR_FILE) ] || cp etc/RT_SiteConfig_RTIR.pm $(SITE_CONFIG_RTIR_FILE)
	chgrp $(RTGROUP) $(SITE_CONFIG_RTIR_FILE)
	chown $(BIN_OWNER) $(DESTDIR)/$(SITE_CONFIG_RTIR_FILE)

	@echo "Installed configuration. about to install RTIR in  $(RT_ROOT)"

install-html:
	mkdir -p $(RT_HTML_PATH)
	cp -R html/* $(RT_HTML_PATH)/
	find $(RT_HTML_PATH)/RTIR -type d |xargs chmod 755
	find $(RT_HTML_PATH)/RTIR -type f |xargs chmod 644

instruct:
	@echo ""
	@echo "Congratulations. RTIR has been installed. "
	@echo ""
	@echo "You must now edit the file $(RT_ROOT)/RT.pm as described in the README, then stop and start your web server."
	@echo ""
	@echo "You may configure RTIR by editing $(SITE_CONFIG_RTIR_FILE)."
	@echo ""
	@echo "After that, you need to initialize RT's database by running" 
	@echo " 'make initdb'"


initdb:
	$(RT_SBIN_PATH)/rt-setup-database --datafile etc/initialdata --dba $(DBA) --prompt-for-dba-password --action insert		
