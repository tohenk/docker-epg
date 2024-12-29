# Electronic Program Guide (EPG) Downloader

A media player like [KODI](https://kodi.tv) can use Electronic Program Guide
(EPG) to provide a guide when watching TV channel. There is an utility to
download those EPG available at https://github.com/iptv-org/epg. This Docker
Compose can be used to automate those task.

This docker compose created with concept of `plug and forget`, once the configuration
is satisfied, start docker compose then forget it. The guide will always be built
based on latest fix available on EPG site.

## Features

* Automatically sync repository on every EPG build

* Your local changes to repository is stashed on EPG build and then re-applied

* Configurable languages, sites, and max connections

* Schedule EPG build as you need using CRON

* Curated channels

* On demand EPG build

## Usage

The steps is described as follows:

* Clone this repository.

  ```sh
  cd ~
  git clone https://github.com/tohenk/docker-epg
  cd docker-epg
  ```

* Adjust `.env` as you need, you can change the web server port, customize NGINX guides path,
  provide your time zone, choose the [Debian mirror](https://www.debian.org/mirror/list) to
  close as possible to your location, and choose which Node major version to use.

  ```sh
  vi .env
  ```

  ```
  APP_NAME=epg
  APP_HTTP_PORT=80
  APP_GUIDES_DIR=guides
  APP_TIMEZONE=Asia/Jakarta
  APT_MIRROR=kartolo.sby.datautama.net.id
  NODE_VERSION=22
  ```

* Includes which sites and language to build, see https://github.com/iptv-org/epg/blob/master/SITES.md.
  If you include curated channels, adjust the days for those channels to fetch.

  ```sh
  vi cron/guides.env
  ```

  ```sh
  LANGS="id"
  SITES="firstmedia.com indihometv.com mncvision.id vidio.com visionplus.id"
  CURATED_DAYS="2"
  ```

  The number of connections for fetching the site can be specified by appending the number delimited by `:`,
  e.g. `mncvision.id:5` will use max connections of 5.

* A curated channels can be provided if necessary.

  ```sh
  vi cron/channels.xml
  ```

  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <channels>
    <channel site="cubmu.com" lang="id" xmltv_id="BioskopIndonesia.id" site_id="4028c68574537fcd0174be26e4325724">Bioskop Indonesia</channel>
  </channels>
  ```

* If necessary, you can customize CRON job. By default it will build EPG once, then every 00:01.

  ```sh
  vi cron/crontab.prod
  ```

  ```
  * * * * * /cron/epg.sh auto 2>&1 | tee -a ~/epg.log
  1 0 * * * /cron/epg.sh 2>&1 | tee -a ~/epg.log
  ```

* Start the container, if you need to view the console output use `docker logs`.

  ```sh
  sudo docker compose up -d
  sudo docker logs -f epg-cron
  ```

  ```
  --- timezone.sh ---

  Current default time zone: 'Asia/Jakarta'
  Local time is now:      Sun Dec 29 16:55:44 WIB 2024.
  Universal Time is now:  Sun Dec 29 09:55:44 UTC 2024.

  --- genenv.sh ---
  --- apt.sh ---
  debconf: delaying package configuration, since apt-utils is not installed
  --- nodejs.sh ---
  debconf: delaying package configuration, since apt-utils is not installed
  debconf: delaying package configuration, since apt-utils is not installed
  --- cron.sh ---
  debconf: delaying package configuration, since apt-utils is not installed
  dos2unix: converting file /cron/channels.xml to Unix format...
  dos2unix: converting file /cron/crontab.prod to Unix format...
  dos2unix: converting file /cron/epg.env to Unix format...
  dos2unix: converting file /cron/epg.sh to Unix format...
  dos2unix: converting file /cron/guides.env to Unix format...
  SCHEDULER_ENV is not set, using prod
  Loading crontab file: /cron/crontab.prod
  --- cleanlock.sh ---
  --- setowner.sh ---
  --- viewlog.sh ---
  Starting cron...
  tail: cannot open '/home/epg/epg.log' for reading: No such file or directory
  tail: '/home/epg/epg.log' has appeared;  following new file
  === epg.sh ===
  Cloning EPG source...
  Cloning into 'epg'...
  Updating files: 100% (1253/1253), done.
  Updating npm modules...
  npm warn deprecated q@1.5.1: You or someone you depend on is using Q, the JavaScript Promise library that gave JavaScript developers strong feelings about promises. They can almost certainly migrate to the native JavaScript promise now. Thank you literally everyone for joining me in this bet against the odds. Be excellent to each other.
  npm warn deprecated
  npm warn deprecated (For a CapTP with native promises, see @endo/eventual-send and @endo/captp)
  npm warn deprecated inflight@1.0.6: This module is not supported, and leaks memory. Do not use it. Check out lru-cache if you want a good and tested way to coalesce async requests by a key value, which is much more comprehensive and powerful.
  npm warn deprecated glob@7.2.3: Glob versions prior to v9 are no longer supported

  added 765 packages, and audited 766 packages in 2m

  137 packages are looking for funding
    run `npm fund` for details

  1 critical severity vulnerability

  Some issues need review, and may require choosing
  a different dependency.

  Run `npm audit` for details.
  npm notice
  npm notice New major version of npm available! 10.9.0 -> 11.0.0
  npm notice Changelog: https://github.com/npm/cli/releases/tag/v11.0.0
  npm notice To update run: npm install -g npm@11.0.0
  npm notice
  Preparing directory...
  Loading EPG api...

  > api:load
  > npx tsx scripts/commands/api/load.ts

  --- Sun Dec 29 17:01:00 WIB 2024 ---
  Building guide for firstmedia.com...
  Building guide for indihometv.com...
  Building guide for mncvision.id (id)...
  Building guide for vidio.com...
  Building guide for visionplus.id (id)...
  Building guide for curated channels...
  Site curated: done in 00h 00m 04s
  Site visionplus.id: done in 00h 00m 42s
  Site vidio.com: done in 00h 00m 57s
  Site firstmedia.com: done in 00h 01m 32s
  Site indihometv.com: done in 00h 02m 40s
  Site mncvision.id: done in 00h 08m 27s
  ```

* Once build completed, head to http://your-docker-ip/guides/ to view the guides.

* A build log for each site can be viewed by `exec`-ing into container.

  ```sh
  sudo docker exec -it epg-cron /bin/bash
  su epg
  ls ~
  ```

  ```
  epg.log  firstmedia.com.log  indihometv.com.log  mncvision.id.log  vidio.com.log  visionplus.id.log
  ```

* To build EPG on demand, create an empty `.run` file in `build` folder.

  ```sh
  touch ./build/.run
  ```