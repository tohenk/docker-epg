# Electronic Program Guide (EPG) Downloader

A media player like [KODI](https://kodi.tv) can use Electronic Program Guide
(EPG) to provide a guide when watching TV channel. There is an utility to
download those EPG available at https://github.com/iptv-org/epg. This Docker
Compose can be used to automate those task.

## Usage

The steps is described as follows:

* Clone this repository.

  ```sh
  $ cd ~
  $ git clone https://github.com/tohenk/docker-epg
  $ cd docker-epg
  ```

* Adjust `.env` as you need, you can change the web server port, provide your
  time zone,  choose the Debian mirror to close as possible to your location,
  and choose which Node major version to use.

  ```sh
  $ vi .env
  ```

  ```
  APP_NAME=epg
  APP_HTTP_PORT=80
  APP_TIMEZONE=Asia/Jakarta
  APT_MIRROR=kartolo.sby.datautama.net.id
  NODE_VERSION=20
  ```

* Includes which sites and language to build, see https://github.com/iptv-org/epg/blob/master/SITES.md.

  ```sh
  $ vi cron/guides.sh
  ```

  ```sh
  LANGS="id"
  SITES="firstmedia.com indihometv.com mncvision.id vidio.com visionplus.id"
  ```

* A curated channels can be provided if necessary.

  ```sh
  $ vi cron/channels.xml
  ```

  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <channels>
    <channel site="playtv.unifi.com.my" lang="en" xmltv_id="MoonbugKids.uk" site_id="59924306">Moonbug</channel>
    <channel site="mytvsuper.com" lang="en" xmltv_id="ChineseDrama.hk" site_id="CDR3">Chinese Drama</channel>
  </channels>
  ```

* If necessary, you can customize CRON job. By default it will build EPG once, then every 00:05.

  ```sh
  $ vi cron/crontab.prod
  ```

  ```
  * * * * * /cron/epg.sh oneshot 2>&1 | tee -a ~/epg.log
  5 0 * * * /cron/epg.sh 2>&1 | tee -a ~/epg.log
  ```

* Start the container, if you need to view the console output use `docker logs`.

  ```sh
  $ sudo docker compose up -d
  $ sudo docker logs -f epg-cron
  ```

  ```
  Current default time zone: 'Asia/Jakarta'
  Local time is now:      Tue Nov 21 15:11:09 WIB 2023.
  Universal Time is now:  Tue Nov 21 08:11:09 UTC 2023.

  debconf: delaying package configuration, since apt-utils is not installed
  deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main
  debconf: delaying package configuration, since apt-utils is not installed
  SCHEDULER_ENV is not set, using prod
  dos2unix: converting file /cron/channels.xml to Unix format...
  dos2unix: converting file /cron/crontab.prod to Unix format...
  dos2unix: converting file /cron/epg.sh to Unix format...
  dos2unix: converting file /cron/guides.sh to Unix format...
  Loading crontab file: /cron/crontab.prod
  Starting cron...
  === epg.sh ===
  Cloning EPG source...
  Cloning into 'epg'...
  Updating npm modules...

  added 710 packages, and audited 711 packages in 1m

  129 packages are looking for funding
    run `npm fund` for details

  found 0 vulnerabilities
  Preparing directory...
  Loading EPG api...

  > api:load
  > npx tsx scripts/commands/api/load.ts

  --- Tue Nov 21 15:14:34 WIB 2023 ---
  Building guide for firstmedia.com...
  Building guide for indihometv.com...
  Building guide for mncvision.id (id)...
  Building guide for vidio.com...
  Building guide for visionplus.id...
  Building guide for curated channels...
  ```

* Once build completed, head to http://your-docker-ip/guides to view the guides.
  If you wish to change the path, edit [NGINX default configuration](/templates/default.conf.template).

* A build log for each site can be viewed by `exec`-ing into container.

  ```sh
  $ sudo docker exec -it epg-cron /bin/bash
  $ su epg
  $ ls ~
  ```

  ```
  epg.log  firstmedia.com.log  indihometv.com.log  mncvision.id.log  vidio.com.log  visionplus.id.log
  ```
