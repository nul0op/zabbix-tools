# zabbix-tools
various tools/scripts/... around zabbix monitoring

the service id is the serviceid of the container folder as can be found by hovering the hyperlink in web gui (and not the service with the actuel trigger)

this can be only run once, so be sure to have your hierarchy setup before.
if you need to rereun it again, just delete the previous entries with something likes:

delete from service_alarms where serviceid in (351,352,353,354,369,356,357,358,359,360,361,362,363,364,365,366,367);

(all childs need to be specificaly included)
