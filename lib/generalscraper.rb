require 'json'
require 'nokogiri'
require 'mechanize'

load 'parse_page.rb'
load 'proxy_manager.rb'

class GeneralScraper
  include ParsePage
  include ProxyManager
  
  def initialize(operators, searchterm, proxylist, use_proxy)
    @operators = operators
    @searchterm = searchterm
    @op_val = @operators.split(" ")[0].split(":")[1]
    @proxylist = IO.readlines(proxylist)
    @usedproxies = Hash.new
    
    @output = Array.new
    @urllist = Array.new
    @startindex = 10
    @use_proxy = use_proxy
  end

  # Searches for links on Google
  def search
    categorizeLinks(getPage("http://google.com", @operators + " " + @searchterm, @use_proxy))
  end

  # Categorizes the links on results page into results and other search pages
  def categorizeLinks(page)
    page.links.each do |link|
      if isResultLink?(link)
        siteURLSave(link)
      elsif isSearchPageLink?(link)
        nextSearchPage(link)
      end
    end
  end

  # Determines if url is link to search result
  def isResultLink?(link)
    return (link.href.include? @op_val) && (!link.href.include? "webcache") && (!link.href.include? @operators.gsub(" ", "+"))
  end

  # Determines if URL is link to next search page
  def isSearchPageLink?(link)
    return (link.href.include? "&sa=N") && (link.href.include? "&start=")
  end

  
  # Parse and save the URLs for search results
  def siteURLSave(link)
    site_url = link.href.split("?q=")[1]
    @urllist.push(site_url.split("&")[0]) if site_url
  end

  # Process search links and go to next page
  def nextSearchPage(link)
    page_index_num = link.href.split("&start=")[1].split("&sa=N")[0]
    
    if page_index_num.to_i == @startindex
      @startindex += 10
      categorizeLinks(getPage("http://google.com" + link.href + "&filter=0", @use_proxy))
    end
  end

  
  # Gets all data and returns in JSON
  def getData
    search
    @urllist.each do |url|
      getPageData(url)
    end
    return JSON.pretty_generate(@output)
  end

  # Returns a list of search result URLs
  def getURLs
    search
    return JSON.pretty_generate(@urllist)
  end
end
