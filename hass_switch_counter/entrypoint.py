#!/usr/bin/env python

import os
import Rpi.GPIO as GPIO
import paho.mqtt.client as mqtt

channel   = 21               if not os.environ['GPIO']      else os.environ['GPIO']
host      = 'localhost'      if not os.environ['MQTT_HOST'] else os.environ['MQTT_HOST']
port      = 1883             if not os.environ['MQTT_PORT'] else os.environ['MQTT_PORT']
protocol  = mqtt.MQTTv311    if not os.environ['MQTT_OLD']  else mqtt.MQTTv31
topic     = 'switch/counter' if not os.environ['TOPIC']     else os.environ['TOPIC']
send_time = 30               if not os.environ['SEND_TIME'] else os.environ['SEND_TIME']

count = 0
lastsend = 0

# increment counter
def on_switch(channel):
	count += 1

# init gpio
GPIO.setmode(GPIO.BCM)
GPIO.setup(channel, GPIO.IN, pull_up_down=GPIO.PUD_UP)
GPIO.add_event_detect(channel, GPIO.BOTH, callback=on_switch)

# connect to mqtt
client = mqtt.Client(protocol=protocol)
client.connect_async(host, port)
client.loop_start()

# main loop
while True:
	client.publish(topic, count)
	count = 0
	time.sleep(send_time)

# clean up
client.loop_stop()
GPIO.cleanup()
