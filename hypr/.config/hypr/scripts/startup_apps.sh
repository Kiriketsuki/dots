#!/bin/bash

# Launch communication apps with delays to ensure proper workspace assignment
sleep 2
slack &

sleep 3
teams-for-linux &

sleep 3
thunderbird &

sleep 3
whatsapp-linux-desktop --trace-warnings &
