require 'active_support/time'
require 'mechanize'
require 'uri'

module ProxyManager 
  # Get the page with a proxy
  def getPage(url, form_input = nil, fail_count = 0)
    agent = Mechanize.new do |a|
      a.user_agent_alias = "Linux Firefox"
      a.set_proxy(*getRandomProxy(url))
    end

    begin
      if form_input
        gform = agent.get(url).form("f")
        gform.q = form_input
        return agent.submit(gform, gform.buttons.first)
      else
        return agent.get(url)
      end
    rescue
      getPage(url, form_input, fail_count+=1) if fail_count < 5
    end
  end

  # Choose a random proxy
  def getRandomProxy(url)
    max = @proxylist.length
    chosen = @proxylist[Random.rand(max)]

    # Only use proxy if it hasn't been used in last 20 seconds on same host
    if !@usedproxies[chosen] || @usedproxies[chosen][0] < Time.now-20 || @usedproxies[chosen][1] != URI.parse(url).host
      @usedproxies[chosen] = [Time.now, URI.parse(url).host]
      proxy_info = chosen.split(":")
      proxy_info[proxy_info.length-1] = proxy_info.last.strip
      return proxy_info
    else
      sleep(0.005)
      getRandomProxy(url)
    end
  end
end
