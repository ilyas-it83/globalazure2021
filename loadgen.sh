#!/bin/bash

echo -e "Generating Load"

while :
do
    curl -s http://localhost/productpage > /dev/null echo -n .;
    sleep 0.1 
done
echo "Generating Load Interrupted"