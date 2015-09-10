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

    # Generate driver
    profile = Selenium::WebDriver::Firefox::Profile.new
    profile['intl.accept_languages'] = 'en'
    @driver = Selenium::WebDriver.for :firefox, profile: profile
  end

  # Searches for links on Google
  def search
    categorizeLinks(getPage("http://google.com", @driver, @operators + " " + @searchterm, @use_proxy))
  end

  # Gets the links from the page
  def getLinks(page)
    # Sleep while things load
    sleep(10)
    
    # Extract arr
    return page.find_elements(css: "a").inject(Array.new) do |link_arr, al|
      begin
        link_arr.push(al.attribute("href"))
      rescue
        
      end
     
      link_arr
    end
  end

  # Categorizes the links on results page into results and other search pages
  def categorizeLinks(page)
    links = getLinks(page)
    links.each do |link| 
      if link
        if isResultLink?(link)
          siteURLSave(link)
        elsif isSearchPageLink?(link)
          nextSearchPage(link)
        end
      end
    end
  end

  # Determines if url is link to search result
  def isResultLink?(link)
    return (link.include? @op_val) &&
           (!link.include? "webcache") &&
           (!link.include? @operators.gsub(" ", "+")) &&
           (!link.include?("translate.google"))
  end

  # Determines if URL is link to next search page
  def isSearchPageLink?(link)
    return (link.include? "&sa=N") && (link.include? "&start=")
  end

  
  # Parse and save the URLs for search results
  def siteURLSave(link)
    @urllist.push(link)
  end

  # Process search links and go to next page
  def nextSearchPage(link)
    page_index_num = link.split("&start=")[1].split("&sa=N")[0]
  
    if page_index_num.to_i == @startindex
      @startindex += 10
      categorizeLinks(getPage(link, @driver, @use_proxy))
    end
  end

  
  # Gets all data and returns in JSON
  def getData
    search
    @urllist.each do |url|
      getPageData(url, @driver)
    end
    @driver.close
    return JSON.pretty_generate(@output)
  end

  # Returns a list of search result URLs
  def getURLs
    search
    @driver.close
    return JSON.pretty_generate(@urllist)
  end
end

