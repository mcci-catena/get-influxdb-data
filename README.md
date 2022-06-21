# get-influxdb-data

This repository has a shell script that will fetch data from an InfluxDB repository as JSON and output to stdout.

To use it, you need the following:

1. The address of your influxdb server
2. A login that will let you get data. If you're using the [docker-iot-dashboard](https://github.com/mcci-catena/docker-iot-dashboard), and you followed the setup instructions, you should have a couple of "api key" logins. Normally they're something like `apikey1`, `apikey2`, etc. You should also have the corresponding passwords.

   * if you have lost these, then you need to login to the nginx container and add one or more keys. For example:

      ```console
      $ cd /opt/docker/{your-dashboard-directory}
      $ docker-compose exec nginx /bin/bash
      root@02a8f9e2514d:/# cd /etc/nginx/authdata/influxdb
      root@02a8f9e2514d:/etc/nginx/authdata/influxdb#
      root@02a8f9e2514d:/etc/nginx/authdata/influxdb# htpasswd -B .htpasswd apikey1
      New password:
      Re-type new password:
      Adding password for user apikey1
      root@02a8f9e2514d:/etc/nginx/authdata/influxdb# exit
      $
      ```

     Don't forget to record the password for the api key.

3. The name of your database on the influxdb server.

   If you have forgotten, you need to similarly log into the influxdb container and ask the server some questions.

   ```console
   $ cd /opt/docker/{your-dashboard-directory}
   $ docker-compose exec influxdb /bin/bash
   root@whatever:/opt/influxdb-backup# influx
   Connected to http://localhost:8086 version 1.8.10
   InfluxDB shell version: 1.8.10
   > show databases
   name: databases
   name
   ----
   _internal
   mydatabase
   >
   ```

   In this case, `mydatabase` is the name of your database.

4. The name of the "measurement" in your database. Again, if you've forgotten, you can ask influx.

   ```console
   $ cd /opt/docker/{your-dashboard-directory}
   $ docker-compose exec influxdb /bin/bash
   root@whatever:/opt/influxdb-backup# influx
   Connected to http://localhost:8086 version 1.8.10
   InfluxDB shell version: 1.8.10
   > using mydatabase # <--- this needs to be the name of your database
   Using database mydatabase
   > show measurements
   name: measurements
   name
   ----
   data # <--- this wil be different depending on what's in your datagbase.
   >
   ```

   Once again, make a note.

