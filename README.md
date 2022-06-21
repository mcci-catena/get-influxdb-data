# get-influxdb-data

This repository has a shell script that will fetch data from an InfluxDB repository as JSON and output to stdout.

Please note that (as of this writing) this script does *not* work in Git for Windows, because of Windows PTY issues. However, it has been tested and works with Ubuntu 20.4 LTS for Windows, and on native Ubuntu. It has not been tested on macOS, but it will probably work there, as long as you have `bash` installed. 

If you're looking for the home page on GitHub, it's here: https://github.com/mcci-catena/get-influxdb-data.

To clone this using the `git` command line, use:

```bash
git clone https://github.com/mcci-catena/get-influxdb-data
```

To use it, you need the following:

1. The fully-qualified internet address of your influxdb server, e.g. `myserver.example.com`.

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
   > use mydatabase # <--- this needs to be the name of your database
   Using database mydatabase
   > show measurements
   name: measurements
   name
   ----
   data # <--- this wil be different depending on what's in your database.
   >
   ```

   Once again, make a note.

5. The name(s) of your *fields* to be queried. Again, if you've forgotten, you can ask influx.

   ```console
   $ cd /opt/docker/{your-dashboard-directory}
   $ docker-compose exec influxdb /bin/bash
   root@whatever:/opt/influxdb-backup# influx
   Connected to http://localhost:8086 version 1.8.10
   InfluxDB shell version: 1.8.10
   > use mydatabase # <--- this needs to be the name of your database
   Using database mydatabase
   > show field keys
   name: data
   fieldKey         fieldType
   --------         ---------
   bandwidth        float
   battery          float
   humidity         float
   rssi             float
   snr              float
   spreading_factor float
   tDewpoint        float
   tHeatIndex       float
   temperature      float
   uplinkCount      float
   >
   ```

6. You need the names of the fields used to identify your source devices. THese are called *tag keys*. We need to use this to group the data. Again, you can ask influx.

   ```console
   $ cd /opt/docker/{your-dashboard-directory}
   $ docker-compose exec influxdb /bin/bash
   root@whatever:/opt/influxdb-backup# influx
   Connected to http://localhost:8086 version 1.8.10
   InfluxDB shell version: 1.8.10
   > use mydatabase # <--- this needs to be the name of your database
   Using database mydatabase
   > show tag keys
   name: data
   tagKey
   ------
   dev_eui
   device_id
   >
   ```

  We'll use `device_id` in the query below.

## Testing your connection

Try the following:

```bash
get-influxdb-data.sh -S myserver.example.com -u apikey1 -d mydatabase -s data -t 36 -q "humidity,temperature" -g device_id
```

You will get a summary of the temperatures & humidities for each sensor, averaged per day.

To get a whole bunch of data (all the points, without averaging or anything):

```bash
./get-influxdb-data.sh -S medicinespring.ddns.net -u apikey1 -d medicinespring -s data -t 1 -q "humidity,temperature" -g 'time(1ms),"device_id"' > /tmp/junk.json
```

(This puts the data into a temporary file for later use. You might want to pipe it to python instead, or the json-aware tool of your choice.)
