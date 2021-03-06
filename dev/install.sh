#!/bin/bash

# This runs as root on the server

chef_binary=/var/lib/gems/2.0.0/gems/chef-11.16.4/bin/chef-solo

# Are we on a vanilla system?
if ! test -f "$chef_binary"; then
    #export DEBIAN_FRONTEND=noninteractive
    # Upgrade headlessly (this is only safe-ish on vanilla systems)

    # Install Ruby and Chef
    apt-get install -y ruby2.0 ruby2.0-dev make
    gem2.0 install --no-rdoc --no-ri chef
fi

"$chef_binary" -c solo.rb -j solo.json
