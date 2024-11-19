# Electronic Program Guide (EPG) Downloader

A media player like [KODI](https://kodi.tv) can use Electronic Program Guide
(EPG) to provide a guide when watching TV channel. There is an utility to
download those EPG available at https://github.com/iptv-org/epg. This Docker
Compose can be used to automate those task.

## Usage

The steps is described as follows:

* Clone this repository.

  ```sh
  cd ~
  git clone https://github.com/tohenk/docker-epg
  cd docker-epg
  ```

* Adjust `.env` as you need, you can change the web server port, customize NGINX guides path,
  provide your time zone,  choose the Debian mirror to close as possible to your location,
  and choose which Node major version to use.

  ```sh
  vi .env
  ```

  ```
  APP_NAME=epg
  APP_HTTP_PORT=80
  APP_GUIDES_DIR=guides
  APP_TIMEZONE=Asia/Jakarta
  APT_MIRROR=kartolo.sby.datautama.net.id
  NODE_VERSION=20
  ```

* Includes which sites and language to build, see https://github.com/iptv-org/epg/blob/master/SITES.md.

  ```sh
  vi cron/guides.var
  ```

  ```sh
  LANGS="id"
  SITES="firstmedia.com indihometv.com mncvision.id vidio.com visionplus.id"
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
    <channel site="playtv.unifi.com.my" lang="en" xmltv_id="MoonbugKids.uk" site_id="59924306">Moonbug</channel>
    <channel site="mytvsuper.com" lang="en" xmltv_id="ChineseDrama.hk" site_id="CDR3">Chinese Drama</channel>
  </channels>
  ```

* If necessary, you can customize CRON job. By default it will build EPG once, then every 00:01.

  ```sh
  vi cron/crontab.prod
  ```

  ```
  * * * * * /cron/epg.sh oneshot 2>&1 | tee -a ~/epg.log
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
  Local time is now:      Sat Nov 16 15:56:08 WIB 2024.
  Universal Time is now:  Sat Nov 16 08:56:08 UTC 2024.

  --- genvar.sh ---
  --- apt.sh ---
  debconf: delaying package configuration, since apt-utils is not installed
  --- nodejs.sh ---
  debconf: delaying package configuration, since apt-utils is not installed
  debconf: delaying package configuration, since apt-utils is not installed
  --- cron.sh ---
  debconf: delaying package configuration, since apt-utils is not installed
  dos2unix: converting file /cron/channels.xml to Unix format...
  dos2unix: converting file /cron/crontab.prod to Unix format...
  dos2unix: converting file /cron/epg.sh to Unix format...
  dos2unix: converting file /cron/epg.var to Unix format...
  dos2unix: converting file /cron/guides.var to Unix format...
  SCHEDULER_ENV is not set, using prod
  Loading crontab file: /cron/crontab.prod
  --- cleanlock.sh ---
  Cleaning /build/.once...
  --- setowner.sh ---
  --- viewlog.sh ---
  Starting cron...
  === epg.sh ===
  Cloning EPG source...
  Cloning into 'epg'...
  Updating files: 100% (1201/1201), done.
  Updating npm modules...
  npm warn deprecated are-we-there-yet@2.0.0: This package is no longer supported.
  npm warn deprecated npmlog@5.0.1: This package is no longer supported.
  npm warn deprecated q@1.5.1: You or someone you depend on is using Q, the JavaScript Promise library that gave JavaScript developers strong feelings about promises. They can almost certainly migrate to the native JavaScript promise now. Thank you literally everyone for joining me in this bet against the odds. Be excellent to each other.
  npm warn deprecated
  npm warn deprecated (For a CapTP with native promises, see @endo/eventual-send and @endo/captp)
  npm warn deprecated inflight@1.0.6: This module is not supported, and leaks memory. Do not use it. Check out lru-cache if you want a good and tested way to coalesce async requests by a key value, which is much more comprehensive and powerful.
  npm warn deprecated rimraf@3.0.2: Rimraf versions prior to v4 are no longer supported
  npm warn deprecated @humanwhocodes/object-schema@2.0.3: Use @eslint/object-schema instead
  npm warn deprecated @humanwhocodes/config-array@0.13.0: Use @eslint/config-array instead
  npm warn deprecated glob@7.2.3: Glob versions prior to v9 are no longer supported
  npm warn deprecated gauge@3.0.2: This package is no longer supported.
  npm warn deprecated eslint@8.57.1: This version is no longer supported. Please see https://eslint.org/version-support for other options.

  added 719 packages, and audited 720 packages in 2m

  134 packages are looking for funding
    run `npm fund` for details

  1 high severity vulnerability

  To address all issues (including breaking changes), run:
    npm audit fix --force

  Run `npm audit` for details.
  npm notice
  npm notice New minor version of npm available! 10.8.2 -> 10.9.0
  npm notice Changelog: https://github.com/npm/cli/releases/tag/v10.9.0
  npm notice To update run: npm install -g npm@10.9.0
  npm notice
  Preparing directory...
  Loading EPG api...

  > api:load
  > npx tsx scripts/commands/api/load.ts

  --- Sat Nov 16 16:01:03 WIB 2024 ---
  Building guide for firstmedia.com...
  Building guide for indihometv.com...
  Building guide for mncvision.id (id)...
  Building guide for vidio.com...
  Building guide for visionplus.id...
  Building guide for curated channels...
  ```

* Once build completed, head to http://your-docker-ip/guides to view the guides.

* A build log for each site can be viewed by `exec`-ing into container.

  ```sh
  sudo docker exec -it epg-cron /bin/bash
  su epg
  ls ~
  ```

  ```
  epg.log  firstmedia.com.log  indihometv.com.log  mncvision.id.log  vidio.com.log  visionplus.id.log
  ```
