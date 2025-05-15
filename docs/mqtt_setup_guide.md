# MQTT Broker Setup Guide

To set up your local MQTT broker:

1. Install Mosquitto:
   ```
   sudo apt install mosquitto
   ```

2. Start the service:
   ```
   sudo systemctl start mosquitto
   ```

3. Enable on boot:
   ```
   sudo systemctl enable mosquitto
   ```

4. Test connection:
   ```
   mosquitto_sub -t "test" -v
   mosquitto_pub -t "test" -m "hello"
   ```
