#! /bin/bash

DATADIR := ./data
PREFIX  := $(DATADIR)/404-report-



cronjob: daily data/summary.csv

install-cronjob:
	sudo ln -s $$(pwd)/etc-cron.daily-404tracker.sh  /etc/cron.daily/404tracker

uninstall-cronjob:
	rm /etc/cron.daily/404tracker

daily:
	mkdir -p $(DATADIR) ;\
	grep '" 404 ' /var/log/nginx/*access.log /var/log/nginx/*access.log.1 | \
        py/extract.py '^(?P<log>[^:]+)' 'GET (?P<path>/[^/ ]+/?)' '(?P<uri>GET [^"]+)' \
	| gzip -c >$(PREFIX)$$(date +%Y%d%m).csv.gz

data/summary.csv: $(wildcard $(PREFIX)*)
	zcat $< | q -d, -H \
        'select count(*) as number, log, path from - group by log,path having number>5 order by number desc'  |\
	egrep -v 'apple-touch-icon|robots.txt|favicon.ico' \
	> $@
