#!/bin/bash

url1="localhost:3000/products"
url2="localhost:3000/products/1"
url3="localhost:3000/products/1/details"

response_time1=$(curl -s -w "%{time_total}\n" -o /dev/null "$url1")
response_time2=$(curl -s -w "%{time_total}\n" -o /dev/null "$url2")
response_time3=$(curl -s -w "%{time_total}\n" -o /dev/null "$url3")

echo "The products API take: $response_time1 seconds"
echo "The product API take: $response_time2 seconds"
echo "The product Details API take: $response_time3 seconds"