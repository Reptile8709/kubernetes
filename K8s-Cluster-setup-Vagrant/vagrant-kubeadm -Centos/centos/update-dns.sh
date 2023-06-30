#!/bin/bash

sed -i -e 's/#DNS=/DNS=8.8.8.8/' /etc/systemd/resolved.conf
sed -i -e 's/#DNS=/DNS=192.168.0.1/' /etc/systemd/resolved.conf

service systemd-resolved restart