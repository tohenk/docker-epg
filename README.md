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

* Adjust `.env` as you need, you can change the web server port, customize NGINX guides
  path, provide your time zone, choose the [Debian mirror](https://www.debian.org/mirror/list)
  to close as possible to your location, and choose which Node major version to use.

  ```sh
  vi .env
  ```

  ```
  APP_NAME=epg
  APP_HTTP_PORT=80
  APP_GUIDES_DIR=guides
  APP_TIMEZONE=Asia/Jakarta
  APT_MIRROR=deb.debian.org
  DEBIAN_VERSION=trixie-slim
  NODE_VERSION=24
  ```

* Includes which sites and language to build, see https://github.com/iptv-org/epg/blob/master/SITES.md.
  If you include curated channels, adjust the days for those channels to fetch.

  ```sh
  vi config/guides.env
  ```

  ```sh
  LANGS="id"
  SITES="firstmedia.com indihometv.com mncvision.id vidio.com visionplus.id"
  CURATED_DAYS="2"
  ```

  The number of connections for fetching the site can be specified by appending the
  number delimited by `:`, e.g. `mncvision.id:5` will use max connections of 5.

* A curated channels can be provided if necessary.

  ```sh
  vi config/channels.xml
  ```

  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <channels>
    <channel site="tivie.id" lang="id" xmltv_id="HBOAsia.sg" site_id="hbo">HBO</channel>
  </channels>
  ```

  More curated channels is supported, just drop the filename as `[alias].channels.xml`.
  The `[alias]` would be any name of your choice, e.g. `my-fav-guide.channels.xml`.

* If necessary, you can customize CRON job. By default it will build EPG once, then every 00:00.

  ```sh
  vi cron/crontab.prod
  ```

  ```
  * * * * * /cron/epg.sh auto 2>&1 | tee -a ~/epg.log
  0 0 * * * /cron/epg.sh 2>&1 | tee -a ~/epg.log
  ```

* Start the container, if you need to view the console output use `docker logs`.

  ```sh
  sudo docker compose up -d
  sudo docker logs -f epg-cron
  ```

  ```
  --- timezone.sh ---

  Current default time zone: 'Asia/Jakarta'
  Local time is now:      Fri Oct 31 15:44:45 WIB 2025.
  Universal Time is now:  Fri Oct 31 08:44:45 UTC 2025.

  --- apt.sh ---
  --- adduser.sh ---
  --- apt-install.sh ---
  --- genenv.sh ---
  --- nodejs.sh ---
  --- cron.sh ---
  SCHEDULER_ENV is not set, using prod
  Loading crontab file: /cron/crontab.prod
  --- cleanlock.sh ---
  --- setowner.sh ---
  --- viewlog.sh ---
  Starting cron...
  === epg.sh ===
  Cloning EPG source...
  Cloning into 'epg'...
  Updating files: 100% (1765/1765), done.
  Checking latest npm version...
  npm notice
  npm notice New patch version of npm available! 11.6.1 -> 11.6.2
  npm notice Changelog: https://github.com/npm/cli/releases/tag/v11.6.2
  npm notice To update run: npm install -g npm@11.6.2
  npm notice

  removed 1 package, and changed 28 packages in 5s

  28 packages are looking for funding
    run `npm fund` for details
  Updating npm modules...
  npm warn deprecated inflight@1.0.6: This module is not supported, and leaks memory. Do not use it. Check out lru-cache if you want a good and tested way to coalesce async requests by a key value, which is much more comprehensive and powerful.
  npm warn deprecated glob@7.2.3: Glob versions prior to v9 are no longer supported
  npm warn deprecated skip-postinstall@1.0.0: Package no longer supported. Contact Support at https://www.npmjs.com/support for more info.

  added 925 packages, and audited 926 packages in 4m

  150 packages are looking for funding
    run `npm fund` for details

  found 0 vulnerabilities
  Preparing directory...
  Loading EPG api...

  > api:load
  > tsx scripts/commands/api/load.ts

  --- Fri Oct 31 15:50:54 WIB 2025 ---
  Building guide for firstmedia.com...
  Building guide for indihometv.com...
  Building guide for mncvision.id (id)...
  Building guide for vidio.com...
  Building guide for visionplus.id (id)...
  Building guide for curated channels...
  Guide firstmedia.com: success done in 00h 00m 20s
  Guide vidio.com: success done in 00h 00m 38s
  Guide visionplus.id: success done in 00h 00m 45s
  Guide curated: success done in 00h 00m 47s
  Guide indihometv.com: success done in 00h 03m 49s
  Guide mncvision.id: success done in 00h 10m 58s
  ```

* Once build completed, head to http://your-docker-ip/guides/ to view the guides.

* A build log for each site can be viewed by `exec`-ing into container.

  ```sh
  sudo docker exec -it epg-cron su epg
  ls ~
  ```

  ```
  curated.log  epg.log  firstmedia.com.log  indihometv.com.log  mncvision.id.log  vidio.com.log  visionplus.id.log
  ```

* To build EPG on demand, create an empty `.run` file in `build` folder.

  ```sh
  touch ./build/.run
  ```