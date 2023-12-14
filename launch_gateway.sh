#!/usr/bin/env bash

brave-browser $(ip route | grep -Po '(?<=via )(\d{1,3}.){4}')

