#!/bin/bash
source lib/params.sh

bash deb.sh "$version-$revision"
bash rpm.sh "$version-$revision"