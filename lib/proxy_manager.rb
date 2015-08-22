require 'active_support/time'
require 'mechanize'
require 'uri'

module ProxyManager 
  # Get the page with a proxy
  def getPage(url, form_input = nil, fail_count = 0, use_proxy)
    agent = Mechanize.new do |a|
      a.user_agent_alias = "Linux Firefox"

      # Set proxy if specified, otherwise delay to avoid blocks
      if use_proxy
        a.set_proxy(*getRandomProxy(url))
      else
        sleep(20)
      end
    end

    # Slightly different based on filling in form or not
    begin
      if form_input
        gform = agent.get(url).form("f")
        gform.q = form_input
        return agent.submit(gform, gform.buttons.first)
      else
        return agent.get(url)
      end
    rescue # Only retry request 10 times
      getPage(url, form_input, fail_count+=1) if fail_count < 10
    end
  end

  # Choose a random proxy
  def getRandomProxy(url)
    max = @proxylist.length
    chosen = @proxylist[Random.rand(max)]

    # Only use proxy if it hasn't been used in last 20 seconds on same host
    if isNotUsed?(chosen, url)
      @usedproxies[chosen] = [Time.now, URI.parse(url).host]
      return parseProxy(chosen)
    else
      sleep(0.005)
      getRandomProxy(url)
    end
  end

  # Splits up proxy into IP, port, user, password
  def parseProxy(chosen)
    proxy_info = chosen.split(":")
    proxy_info[proxy_info.length-1] = proxy_info.last.strip
    return proxy_info
  end

  # Checks if a proxy has been used on domain in the last 20 seconds
  def isNotUsed?(chosen, url)
    return !@usedproxies[chosen] || @usedproxies[chosen][0] <= Time.now-20 || @usedproxies[chosen][1] != URI.parse(url).host
  end
end
