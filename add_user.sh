#!/bin/bash

# Add a user with username "exampleuser"
sudo useradd veresz

# Set a password for the user
echo "veresz:XXXXXXXX" | sudo chpasswd
