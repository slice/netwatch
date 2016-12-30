sleep = (require "socket").sleep

class NetWatch
  new: =>
    @ping = nil
    @ping_address = "8.8.8.8"
    @slow_thresh = 200

  turn_off_network: =>
    os.execute "nmcli n off"

  turn_on_network: =>
    os.execute "nmcli n on"

  get_network_status: =>
    -- get the status of the network with with nmcli
    io.popen("nmcli -t --fields state -c no g")\read("l")

  wait_for_connectivity: =>
    did_say_connecting = false
    while true
      status = @get_network_status!
      if not did_say_connecting and status == "connecting"
        print "+ network is connecting, please be patient"
        did_say_connecting = true
      break if status == "connected"
      sleep 1
    print "+ network connected"

  wait_for_internet: =>
    waiter = io.popen("ping #{@ping_address} 2>&1")

    tries = 0

    for line in waiter\lines!
      if tries > 10
        print "- waiting failed: tries=#{tries}"
      if line\match("icmp_seq=") ~= nil
        break
      tries += 1

  restart_network: =>
    @turn_off_network!
    @turn_on_network!

  revive_network: =>
    -- we are still connected to the network, but
    -- we have lost connectivity. we must revive the network

    -- restart the network. we assume that this will fix the
    -- problem.
    print "! reviving the network"
    print "* restarting the network"
    @restart_network!

    -- wait for a connection to the network. at this point
    -- we may or may not have an internet connection
    print "* waiting for connectivity"
    @wait_for_connectivity!

    -- wait for an internet connection before monitoring the
    -- network again
    print "* waiting for initial internet connection"
    @wait_for_internet!

    -- restored! woohoo
    print "+ connectivity restored"

  monitor: =>
    print "* monitoring the network for downtime"

    while true
      -- starting a new ping process
      print "* starting a new ping process (#{@slow_thresh}ms thresh)"
      @ping\close! if @ping ~= nil
      @ping = io.popen "ping #{@ping_address} 2>&1"

      times = {}
      unde = 0

      -- read all lines from the ping process
      for line in @ping\lines!
        is_unreachable = line\match("unreachable") ~= nil or
          line\match("Unreachable") ~= nil

        -- read the time
        time = line\match("time=(%d+)")
        table.insert(times, time)
        avg_sum = 0
        for time in *times
          avg_sum += time
        avg = avg_sum / #times

        print "@ time: #{time}ms (#{avg}ms avg)" if time ~= nil
        if time ~= nil
          ms = tonumber time
          -- got back to desirable times, push back counter
          -- to zero
          if unde > 0 and ms < @slow_thresh
            print "+ time fell back (#{ms}ms)"
            unde = 0
          if ms > @slow_thresh
            unde += 1
            print "- undesirable times detected (##{unde}, #{ms}ms)"
            if unde >= 3
              print "- network is too slow, reviving"
              is_unreachable = true

        io.stdout\flush!

        -- if we can't reach the ping_address, revive the network
        if is_unreachable
          @revive_network!
          break

nw = NetWatch!
nw\monitor!
