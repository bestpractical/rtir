RT_ROOT		=	/opt/rt3
RT_HTML_PATH	=	$(RT_ROOT)/local/html
RT_SBIN_PATH	=	$(RT_ROOT)/sbin
DBA		=	root


install: install-html

install-html:
	cp -R html/RTIR $(RT_HTML_PATH)/
	find $(RT_HTML_PATH)/RTIR -type d |xargs chmod 755
	find $(RT_HTML_PATH)/RTIR -type f |xargs chmod 644


initdb:
	$(RT_SBIN_PATH)/rt-setup-database --datafile etc/initialdata --dba $(DBA) --prompt-for-dba-password --action insert		
