# get-influxdb-data

This repository has a shell script that fetches recorded IoT data from an InfluxDB repository and output it in JSON form, either to the console or to a file.

## Introduction

InfluxDB is a nice way to collect data from an IoT system using The Things Network or other LoRaWAN networks. Systems like the [docker-iot-dashboard](https://github.com/mcci-catena/docker-iot-dashboard) provide a simplified Node-RED, Influx, Graphana pipeline. Excel and G-Suite plugins are avialble for pulling data from Influx into a spreadsheet.

However, the combination Graphana + InfluxDB is often inconvenient for processing data, becuase you have to work through Graphana. Not only is there minimal automation in the UI,Graphana pre-processes the data for display -- what you get is the graph data, not the original data.

Sometimes you need a scriptable method for getting data into a file, so you cna process it yourself to get reports or extract information in ways that Graphana can't. This script can sit at the head of your data pipeline, pulling the primary data from InfluxDB for further processing by your other scripts.

This script is not very general purpose. Advance programmers may find that a full Python API library is more convenient and flexible, and it doesn't requrie that you fire up Python program just to get your data. You can get your data, then do your Python magic on the local copy.

## Some practical details

You run this script on a PC or Linux machine, typically not on the server, and it produces data for local processing.

It has been tested and works on native Ubuntu, and on Ubuntu 20.4 LTS for Windows. It has not been tested on macOS, but it will probably work there, as long as you have `bash` installed. 

Please note that (as of this writing) this script does *not* work in Git for Windows, because of Windows PTY issues. 

If you got this package as a zipfile, and you're looking for the home page on GitHub, it's here: https://github.com/mcci-catena/get-influxdb-data.

To clone this using the `git` command line, use:

```bash
git clone https://github.com/mcci-catena/get-influxdb-data
```

This will create a directory named `get-influxdb-data` in the current directory.

## What you need to get started

This script needs a lot of information about your database to do its work. You need the following items.

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

## Testing your connection to the database

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

## Other things in this repo

The `assets` directory has a couple of scripts in MCCI's `bright` language for post-processing the JSON data to give reduced results. `Bright` looks a lot like Lua, with C syntax. They show simple things you can do with data fetched from the database.

## Meta

This script was written by Terry Moore as part of his activities with [The Things Network New York](https://thethings.nyc) and [The Things Netowk Ithaca](https://ttni.tech).

### Copyright and License

See [`LICENSE`](LICENSE.txt).

### Support Open Source Community Networking

The Things Network NY, Inc., is a 501(c)(3) public charity dedicated to creating a technical community to support teachers, students, governments, and others using a free community IoT network, [The Things Network](https://thethingsnetwork.org). Please check out [our website](https://thethings.nyc), and feel free to get involved in our activities -- even if you're not based in New York.  If you prefer to make a financial contribution, you may do so [here](https://the-things-network-new-york-inc.square.site/).
