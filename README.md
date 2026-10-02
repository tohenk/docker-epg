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
  CURATED_DAYS=2
  CURATED_CON=1
  SITES="cubmu.com dens.tv mncvision.id tivie.id vidio.com visionplus.id"
  SITES_TWO="maxstream.tv"
  ```

  The default guide environment above define two sets of sites which is `SITES` and `SITES_TWO`.
  You can group as many sites as you prefer then later can be referenced from CRON job.

  The number of connections for fetching the site can be specified by appending the
  number delimited by `:`, e.g. `mncvision.id:5` will use max connections of 5.

* A curated channels can be provided if necessary.

  ```sh
  vi config/channels.xml
  ```

  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <channels>
    <channel site="nowplayer.now.com" site_id="113" lang="en" xmltv_id="CinemaxAsia.sg@SD">CINEMAX</channel>
    <channel site="nowplayer.now.com" site_id="115" lang="en" xmltv_id="HBOAsia.sg@SD">HBO</channel>
    <channel site="nowplayer.now.com" site_id="112" lang="en" xmltv_id="HBOFamilyAsia.sg@SD">HBO Family</channel>
    <channel site="nowplayer.now.com" site_id="111" lang="en" xmltv_id="HBOHitsAsia.sg@SD">HBO Hits</channel>
    <channel site="nowplayer.now.com" site_id="114" lang="en" xmltv_id="HBOSignatureAsia.sg@SD">HBO Signature</channel>
  </channels>
  ```

  More curated channels is supported, just drop the filename as `[alias].channels.xml`.
  The `[alias]` would be any name of your choice, e.g. `nowplayer.now.com.channels.xml`.

* If necessary, you can customize CRON job. By default it will build EPG once, then every 00:00
  for default `SITES`, and every 01:00 for `SITES_TWO`.

  ```sh
  vi cron/crontab.prod
  ```

  ```
  * * * * * /scripts/epg.sh auto 2>&1 | tee -a ~/epg.log
  0 0 * * * /scripts/epg.sh 2>&1 | tee -a ~/epg.log
  0 1 * * * /scripts/epg.sh two 2>&1 | tee -a ~/epg.log
  ```

  Please be warned, when running for non default sites, the curated channels will be skipped.

* Start the container, if you need to view the console output use `docker logs`.

  ```sh
  sudo docker compose up -d
  sudo docker logs -f epg-cron
  ```

  ```
  --- timezone.sh ---

  Current default time zone: 'Asia/Jakarta'
  Local time is now:      Fri Oct  2 08:50:35 WIB 2026.
  Universal Time is now:  Fri Oct  2 01:50:35 UTC 2026.

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
  Updating files: 100% (1901/1901), done.
  Checking latest npm version...
  Updating npm to 12.2.0...
  Updating node modules...
  npm warn deprecated whatwg-encoding@3.1.1: Use @exodus/bytes instead for a more spec-conformant and faster implementation
  npm warn deprecated glob@10.5.0: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me
  npm warn deprecated glob@11.1.0: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me
  npm warn deprecated glob@11.1.0: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me
  npm warn deprecated glob@11.1.0: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me
  npm warn deprecated glob@11.1.0: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me

  added 838 packages, and audited 839 packages in 2m

  140 packages are looking for funding
    run `npm fund` for details

  6 high severity vulnerabilities

  To address all issues (including breaking changes), run:
    npm audit fix --force

  Run `npm audit` for details.
  Preparing directory...
  Loading EPG api...
  npm notice run api:load
  npm notice run tsx scripts/commands/api/load.ts
  --- Fri Oct  2 08:54:50 WIB 2026 ---
  Building guide for cubmu.com...
  Building guide for dens.tv...
  Building guide for maxstream.tv...
  Building guide for mncvision.id (id)...
  Building guide for tivie.id...
  Building guide for vidio.com...
  Building guide for visionplus.id (id)...
  Building guide for nowplayer.now.com channels...
  Guide nowplayer.now.com: ✔ done in 00h 00m 15s
  Guide visionplus.id: ✔ done in 00h 00m 31s
  Guide dens.tv: ✔ done in 00h 00m 34s
  Guide vidio.com: ✔ done in 00h 00m 44s
  Guide cubmu.com: ✔ done in 00h 00m 47s
  Guide maxstream.tv: ✔ done in 00h 01m 21s
  Guide tivie.id: ✔ done in 00h 01m 17s
  Guide mncvision.id: ✔ done in 00h 01m 32s
  ```

* Once build completed, head to http://your-docker-ip/guides/ to view the guides.

* A build log for each site can be viewed by `exec`-ing into container.

  ```sh
  sudo docker exec -it epg-cron su epg
  ls /build/log
  ```

  ```
  cubmu.com.log  curator.log  dens.tv.log  maxstream.tv.log  mncvision.id.log  nowplayer.now.com.log  tivie.id.log  vidio.com.log  visionplus.id.log
  ```

* To build EPG on demand, create an empty `.run` file in `build` folder.

  ```sh
  touch ./build/.run
  ```

## Curating EPG

It is now possible to collect prefered channels from generated output as curated
channels. To do so, we just need a standard curated channel as shown above then
place it under `config/curating/` directory. The filename should ends with
`*-channels.xml`.

  ```sh
  vi config/curating/mytv-channels.xml
  ```

  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <channels>
    <channel site="maxstream.tv" site_id="0_86sal99e" lang="id" xmltv_id="AnimaxAsia.sg@SD">Animax</channel>
    <channel site="nowplayer.now.com" site_id="113" lang="en" xmltv_id="CinemaxAsia.sg@SD">CINEMAX</channel>
    <channel site="nowplayer.now.com" site_id="115" lang="en" xmltv_id="HBOAsia.sg@SD">HBO</channel>
    <channel site="nowplayer.now.com" site_id="112" lang="en" xmltv_id="HBOFamilyAsia.sg@SD">HBO Family</channel>
    <channel site="nowplayer.now.com" site_id="111" lang="en" xmltv_id="HBOHitsAsia.sg@SD">HBO Hits</channel>
    <channel site="nowplayer.now.com" site_id="114" lang="en" xmltv_id="HBOSignatureAsia.sg@SD">HBO Signature</channel>
    <channel site="maxstream.tv" site_id="0_jhb1o6kj" lang="id" xmltv_id="StudioUniversalLatinAmerica.us@Brazil">Studio Universal</channel>
    <channel site="visionplus.id" site_id="00000000000000000047" lang="id" xmltv_id="ZeeBioskop.id@SD">Zee Bioskop</channel>
  </channels>
  ```
