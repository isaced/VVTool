require 'socket'

def get_first_public_ipv4
  ip_info = Socket.ip_address_list.detect{|intf| intf.ipv4? and !intf.ipv4_loopback? and !intf.ipv4_multicast? and !intf.ipv4_private?}
  ip_info.ip_address unless ip_info.nil?
end