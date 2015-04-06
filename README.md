This gem scrapes Google using any operators specified.

To use-
1. Download the gem 'generalscraper' and add it to your gemfile
2. Maked a new GeneralScraper object: l = GeneralScraper.new("site:site.com inurl:.pdf and other operators", "search terms")
3. Get the list or resulting pages (l.getURLs) or get full text of results (l.getData)

[![Code Climate](https://codeclimate.com/github/TransparencyToolkit/generalscraper/badges/gpa.svg)](https://codeclimate.com/github/TransparencyToolkit/generalscraper)
