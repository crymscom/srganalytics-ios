#!/usr/bin/python2.5

import sys, urllib2, json
analytic_json = json.load(urllib2.urlopen("https://pastebin.com/raw/RnZYEWCA"))

from Foundation import NSMutableArray
url_schemes = NSMutableArray.array()
for app in analytic_json:
	if len(app["ios"]):
		url_schemes.append(app["ios"])

from Foundation import NSMutableDictionary
mutable_dictionnary = NSMutableDictionary.dictionary()
mutable_dictionnary['LSApplicationQueriesSchemes'] = url_schemes
success = mutable_dictionnary.writeToFile_atomically_('LSApplicationQueriesSchemesForSRGAnalytics.plist', 1)
if not success:
  print "plist failed to write!"
  sys.exit(1)
else:
  print "You have it in the SApplicationQueriesSchemesForSRGAnalytics.plist file"