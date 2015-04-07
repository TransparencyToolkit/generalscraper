This gem scrapes Google using any operators specified.

To use-
1. Download the gem 'generalscraper' and add it to your gemfile
2. Maked a new GeneralScraper object:
l = GeneralScraper.new("site:site.com inurl:.pdf and other operators", "search terms", "path to proxy list")
3. Get the list or resulting pages (l.getURLs) or get full text of results (l.getData)

The proxy list must be a list of proxies in a textfile with each IP on its own line.

Additionally, lib/proxy_manager.rb can be mixed into any class that has the following-
@proxylist variable with the proxy list file loaded into array
@usedproxies hash

[![Code Climate](https://codeclimate.com/github/TransparencyToolkit/generalscraper/badges/gpa.svg)](https://codeclimate.com/github/TransparencyToolkit/generalscraper)
