#!/usr/bin/env python

import os
import sys
import time
import RPi.GPIO as GPIO
import paho.mqtt.client as mqtt

channel   = os.environ['GPIO']      if os.environ.has_key('GPIO')      else 21
host      = os.environ['MQTT_HOST'] if os.environ.has_key('MQTT_HOST') else 'localhost'
port      = os.environ['MQTT_PORT'] if os.environ.has_key('MQTT_PORT') else 1883
protocol  = mqtt.MQTTv31            if os.environ.has_key('MQTT_V31')  else mqtt.MQTTv311
topic     = os.environ['TOPIC']     if os.environ.has_key('TOPIC')     else 'switch/counter'
send_time = os.environ['SEND_TIME'] if os.environ.has_key('SEND_TIME') else 30
debounce  = 100

count = 0
lastsend = 0

# logging
def log(message):
	print(time.strftime('%Y-%m-%d %H:%M:%S'), message)
	sys.stdout.flush()

# increment counter
def on_switch(channel):
	global count
	count += 1

# init gpio
log('init gpio %d' % channel)
GPIO.setmode(GPIO.BCM)
GPIO.setup(channel, GPIO.IN, pull_up_down=GPIO.PUD_UP)
GPIO.add_event_detect(channel, GPIO.BOTH, callback=on_switch, bouncetime=debounce)

# connect to mqtt
log('connect to mqtt')
client = mqtt.Client(protocol=protocol)
client.connect_async(host, port)
client.loop_start()

# main loop
log('enter main loop')
while True:
	log('sleep %d seconds' % send_time)
	time.sleep(send_time)
	log('send count %d to %s:%d' % (count, host, port))
	client.publish(topic, count)
	count = 0

# clean up
log('clean up')
client.loop_stop()
GPIO.cleanup()
