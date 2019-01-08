#!/usr/bin/env python

#script modified from amazon provided solution to parse IPS from their published IP list.
import requests

ip_ranges = requests.get('https://ip-ranges.amazonaws.com/ip-ranges.json').json()['prefixes']
amazon_ips = [item['ip_prefix'] for item in ip_ranges if item["service"] == "AMAZON"]
ec2_ips = [item['ip_prefix'] for item in ip_ranges if item["service"] == "EC2" and "us-" in item["region"] and "gov" not in item["region"] ]
for ip in ec2_ips: print(str(ip))
