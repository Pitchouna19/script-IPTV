#!/bin/bash
docker run --rm -d --name srs --network host -v /usr/local/etc/srs:/usr/local/etc/srs ossrs/srs
