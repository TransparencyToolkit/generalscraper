require 'mechanize'
require 'json'
require 'nokogiri'
require 'open-uri'
require 'uploadconvert'

class GeneralScraper
  def initialize(scrapesite, input, type)
   @input = input
   @scrapesite = scrapesite
   @output = Array.new
   @urllist = Array.new
   @startindex = 10
   @type = type
  end

  # TODO:
  # Get proxies working
  # Choose one at random from list (list external)
  # Remove delay
  
  # Script for running Google scraper

  # Separate:
  # Allow multiple operators and values
  # Get page not in examine
  # Separate file for page parsing
  # Start agent/get URL
  
  # Searches for links on Google
  def search
    agent = Mechanize.new
    agent.user_agent_alias = 'Linux Firefox'
    gform = agent.get("http://google.com").form("f")
    gform.q = @type+":" + @scrapesite + " " + @input
    page = agent.submit(gform, gform.buttons.first)
    examine(page)
  end

  # Generates query
  def parseQuery
    # Check if type list is array
    # If it is not an array, process as @type+":"+@value+" " @input
    # Otherwise set query to "" and loop through type and set-
    # query += t+":"+@value[i]
    # Keep index i
    # Then at end- query += " "+@input
  end
 
  # Examines a search page
  def examine(page)
    page.links.each do |link|
      if (link.href.include? @scrapesite) && (!link.href.include? "webcache") && (!link.href.include? @type+":"+@scrapesite)
        saveurl = link.href.split("?q=")
        
        if saveurl[1]
          url = saveurl[1].split("&")
          @urllist.push(url[0])
          # getPage(url[0])
        end
      end

      if (link.href.include? "&sa=N") && (link.href.include? "&start=")
        url1 = link.href.split("&start=")
        url2 = url1[1].split("&sa=N")

        if url2[0].to_i == @startindex
          sleep(rand(30..90))
          @startindex += 10
          agent = Mechanize.new # Need to modify this and split out
          examine(agent.get("http://google.com" + link.href + "&filter=0"))
        end
      end
    end
  end

  # Scrape the page content
  def getPage(url)
    pagehash = Hash.new
    begin
      url.gsub!("%3F", "?")
      url.gsub!("%3D", "=")
      pagehash[:url] = url
      pagehash[:date_retrieved] = Time.now
      html = Nokogiri::HTML(open(url))
      pagehash[:title] = html.css("title").text
      html.css("meta").each do |m|
        if m
          pagehash[m['name']] = m['content']
        end
      end

      # Download and OCR any PDFs
      if url.include? ".pdf"
        `wget -P public/uploads #{url}`
        path = url.split("/")
        u = UploadConvert.new("public/uploads/" + path[path.length-1].chomp.strip)
        pdfparse = JSON.parse(u.handleDoc)
        pdfparse.each{|k, v| pagehash[k] = v}
      else
        pagehash[:text] = html.css("body").text
      end
      @output.push(pagehash)
    rescue
      
    end
  end

  # Gets all data and returns in JSON
  def getData
    search
    return JSON.pretty_generate(@output)
  end

  # Returns a list of search result URLs
  def getURLs
    search
    return JSON.pretty_generate(@urllist)
  end
end

g = GeneralScraper.new("linkedin.com/pub", "xkeyscore", "site")
puts g.getURLs
