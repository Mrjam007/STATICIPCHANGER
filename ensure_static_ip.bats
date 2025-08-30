#!/usr/bin/env bats

IP_DESIRED="192.168.1.150"
GATEWAY="192.168.1.1"
INTERFACE="wlan0"

@test "Check and fix static IP" {
  # Get current IP
  CURRENT_IP=$(ip -4 addr show $INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

  # If IP is wrong, change it
  if [ "$CURRENT_IP" != "$IP_DESIRED" ]; then
    echo "IP is $CURRENT_IP, changing to $IP_DESIRED"
    
    # Temporary change
    sudo ip addr flush dev $INTERFACE
    sudo ip addr add $IP_DESIRED/24 dev $INTERFACE
    sudo ip route add default via $GATEWAY
    
    # Permanent change in dhcpcd.conf (avoid duplicates)
    if ! grep -q "$IP_DESIRED" /etc/dhcpcd.conf; then
      echo -e "\ninterface $INTERFACE\nstatic ip_address=$IP_DESIRED/24\nstatic routers=$GATEWAY\nstatic domain_name_servers=$GATEWAY 8.8.8.8" | sudo tee -a /etc/dhcpcd.conf
      sudo systemctl restart dhcpcd
    fi
  else
    echo "IP is already correct: $CURRENT_IP"
  fi

  # Test passes if the IP is now correct
  [[ "$(ip -4 addr show $INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}')" == "$IP_DESIRED" ]]
}
