#!/bin/bash
docker run --rm -d --name srs -p 1935:1935 -p 1985:1985 -p 8080:8080 -v /usr/local/etc/srs:/usr/local/etc/srs ossrs/srs
