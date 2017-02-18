This gem scrapes Google using any operators specified.

1. Download the gems 'generalscraper' and 'requestmanager'
2. Make a new request manager:
requests = RequestManager.new("path/to/proxielist", [min request wait time, max request wait time], # of browsers)
3. Make a new GeneralScraper object:
l = GeneralScraper.new("site:site.com inurl:.pdf and other operators", "search terms", requests, nil or captcha hash, nil or cm_hash)
4. Get the list or resulting pages (l.getURLs) or get full text of results (l.getData)

The proxy list must be a list of proxies in a textfile with each IP on its own line.

The hash to have CAPTCHAs solved is as follows-
{
  captcha_key: "TwoCaptcha key"
}
If you don't want CAPTCHA's solved, just pass nil.

[![Code Climate](https://codeclimate.com/github/TransparencyToolkit/generalscraper/badges/gpa.svg)](https://codeclimate.com/github/TransparencyToolkit/generalscraper)

To translate pages-
requests_google = RequestManager.new(nil, [1, 3], 1)
t = TranslatePage.new([link, array], requests_google)
