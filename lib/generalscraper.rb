require 'mechanize'
require 'json'
require 'nokogiri'
require 'open-uri'
require 'uploadconvert'

class GeneralScraper
  def initialize(scrapesite, input, table, type)
   @input = input
   @scrapesite = scrapesite
   @output = Array.new
   @startindex = 10
   @table = table
   @type = type
  end

  # Searches for links on Google
  def search
    agent = Mechanize.new
    agent.user_agent_alias = 'Linux Firefox'
    gform = agent.get("http://google.com").form("f")
    gform.q = @type+":" + @scrapesite + " " + @input
    page = agent.submit(gform, gform.buttons.first)
    examine(page)
  end
 
  # Examines a search page
  def examine(page)
    page.links.each do |link|
      if (link.href.include? @scrapesite) && (!link.href.include? "webcache") && (!link.href.include? @type+":"+@scrapesite)
        saveurl = link.href.split("?q=")
        
        if saveurl[1]
          url = saveurl[1].split("&")
          getPage(url[0])
        end
      end

      if (link.href.include? "&sa=N") && (link.href.include? "&start=")
        url1 = link.href.split("&start=")
        url2 = url1[1].split("&sa=N")

        if url2[0].to_i == @startindex
          sleep(rand(30..90))
          @startindex += 10
          agent = Mechanize.new
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
      if @table == false
        if url.include? ".pdf"
          `wget -P public/uploads #{url}`
          path = url.split("/")
          u = UploadConvert.new("public/uploads/" + path[path.length-1].chomp.strip)
          pdfparse = JSON.parse(u.handleDoc)
          pdfparse.each{|k, v| pagehash[k] = v}
        else
          pagehash[:text] = html.css("body").text
        end
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
end

