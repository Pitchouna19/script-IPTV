#!/bin/bash
docker run --rm -d --name srs --network host -v /usr/local/etc/srs/srs.conf:/usr/local/srs/conf/srs.conf ossrs/srs ./objs/srs -c /usr/local/srs/conf/srs.conf
