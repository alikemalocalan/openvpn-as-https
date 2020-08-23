#!/bin/bash

echo "OpenVPN is already installed."
echo
echo "Select an option:"
echo "   1) Add a new client"
echo "   2) Revoke an existing client"
echo "   3) Remove OpenVPN"
echo "   4) Exit"
# shellcheck disable=SC2162
read -p "Option: " option
until [[ "$option" =~ ^[1-4]$ ]]; do
  echo "$option: invalid selection."
  # shellcheck disable=SC2162
  read -p "Option: " option
done
case "$option" in
1)
  echo
  echo "Provide a name for the client:"
  # shellcheck disable=SC2162
  read -p "Name: " unsanitized_client
  # shellcheck disable=SC2001
  client=$(sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]/_/g' <<<"$unsanitized_client")
  while [[ -z "$client" || -e /etc/openvpn/server/easy-rsa/pki/issued/"$client".crt ]]; do
    echo "$client: invalid name."
    # shellcheck disable=SC2162
    read -p "Name: " unsanitized_client
    # shellcheck disable=SC2001
    client=$(sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]/_/g' <<<"$unsanitized_client")
  done
  # shellcheck disable=SC2164
  cd /etc/openvpn/server/easy-rsa/
  EASYRSA_CERT_EXPIRE=3650 ./easyrsa build-client-full "$client" nopass
  # Generates the custom client.ovpn
  new_client
  echo
  echo "$client added. Configuration available in:" ~/"$client.ovpn"
  exit
  ;;
2)
  # This option could be documented a bit better and maybe even be simplified
  # ...but what can I say, I want some sleep too
  number_of_clients=$(tail -n +2 /etc/openvpn/server/easy-rsa/pki/index.txt | grep -c "^V")
  if [[ "$number_of_clients" == 0 ]]; then
    echo
    echo "There are no existing clients!"
    exit
  fi
  echo
  echo "Select the client to revoke:"
  tail -n +2 /etc/openvpn/server/easy-rsa/pki/index.txt | grep "^V" | cut -d '=' -f 2 | nl -s ') '
  # shellcheck disable=SC2162
  read -p "Client: " client_number
  until [[ "$client_number" =~ ^[0-9]+$ && "$client_number" -le "$number_of_clients" ]]; do
    echo "$client_number: invalid selection."
    # shellcheck disable=SC2162
    read -p "Client: " client_number
  done
  client=$(tail -n +2 /etc/openvpn/server/easy-rsa/pki/index.txt | grep "^V" | cut -d '=' -f 2 | sed -n "$client_number"p)
  echo
  # shellcheck disable=SC2162
  read -p "Confirm $client revocation? [y/N]: " revoke
  until [[ "$revoke" =~ ^[yYnN]*$ ]]; do
    echo "$revoke: invalid selection."
    # shellcheck disable=SC2162
    read -p "Confirm $client revocation? [y/N]: " revoke
  done
  if [[ "$revoke" =~ ^[yY]$ ]]; then
    # shellcheck disable=SC2164
    cd /etc/openvpn/server/easy-rsa/
    ./easyrsa --batch revoke "$client"
    EASYRSA_CRL_DAYS=3650 ./easyrsa gen-crl
    rm -f /etc/openvpn/server/crl.pem
    cp /etc/openvpn/server/easy-rsa/pki/crl.pem /etc/openvpn/server/crl.pem
    # CRL is read with each client connection, when OpenVPN is dropped to nobody
    # shellcheck disable=SC2154
    chown nobody:"$group_name" /etc/openvpn/server/crl.pem
    echo
    echo "$client revoked!"
  else
    echo
    echo "$client revocation aborted!"
  fi
  exit
  ;;
4)
  exit
  ;;
esac
