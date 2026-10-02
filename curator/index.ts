/**
 * The MIT License (MIT)
 *
 * Copyright (c) 2026 Toha <tohenk@yahoo.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is furnished to do
 * so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import fs from 'node:fs';
import path from 'node:path';
import { glob } from 'glob';
import { XmlDocument, XmlNode, XmlXPath } from 'libxml2-wasm';

const LOCK_LOCK = '.curating';
const LOCK_HALT = '.wait';

interface NamedPath {
    [key: string]: import('path-scurry').Path;
}

async function collect(dir: string, suffix: string): Promise<NamedPath> {
    const res: NamedPath = {};
    const files = (await glob(path.join(dir, `*${suffix}`), {
        withFileTypes: true,
        windowsPathsNoEscape: true,
    })).sort((a, b) => a.name.localeCompare(b.name));
    for (const file of files) {
        const name = file.name.substr(0, file.name.length - suffix.length);
        res[name] = file;
    }
    return res;
}

function writelock(lockdir: any, callback: any = null) {
    if (typeof lockdir === 'string') {
        const lockfile = path.join(lockdir, LOCK_LOCK);
        if (fs.existsSync(lockfile)) {
            return false;
        } else {
            fs.writeFileSync(lockfile, '');
            if (typeof callback === 'function') {
                callback();
            }
        }
    }
    return true;
}

function cleanlock(lockdir: any) {
    if (typeof lockdir === 'string') {
        const lockfile = path.join(lockdir, LOCK_LOCK);
        if (fs.existsSync(lockfile)) {
            fs.rmSync(lockfile, {force: true});
        }
    }
}

function ishalted(lockdir: any) {
    if (typeof lockdir === 'string') {
        const lockfile = path.join(lockdir, LOCK_HALT);
        if (fs.existsSync(lockfile)) {
            return true;
        }
    }
    return false;
}

async function run(srcdir: string, workdir: string, lockdir: any) {
    if (!writelock(lockdir, () => {
        process.on('SIGINT', () => cleanlock(lockdir));
        process.on('SIGTERM', () => cleanlock(lockdir));
    })) {
        return;
    }
    try {
        const srcfiles = await collect(srcdir, '-channels.xml');
        const files = await collect(workdir, '.xml');
        const channelXpath = XmlXPath.compile('/tv/channel');
        const programmes: {[key: string]: [XmlNode, XmlNode[]]} = {};
        for (const [name, file] of Object.entries(files)) {
            if (Object.keys(srcfiles).includes(name)) {
                continue;
            }
            console.log(`Found EPG ${name}...`);
            const doc = XmlDocument.fromBuffer(fs.readFileSync(file.fullpath()));
            const channels = doc.find(channelXpath);
            for (const channel of channels) {
                const channelId = channel.get('@id')?.content;
                if (!channelId) {
                    continue;
                }
                const programmeXpath = XmlXPath.compile(`/tv/programme[@channel="${channelId}"]`);
                const programme = doc.find(programmeXpath);
                if (programme.length) {
                    programmes[[name, channelId].join(':')] = [channel, programme];
                }
            }
        }
        const curatedChannelXpath = XmlXPath.compile('/channels/channel');
        for (const [name, file] of Object.entries(srcfiles)) {
            if (ishalted(lockdir)) {
                break;
            }
            process.stdout.write(`Collecting ${name}`);
            let _date: any;
            const _channels: string[] = [];
            const _programmes: string[] = [];
            const doc = XmlDocument.fromBuffer(fs.readFileSync(file.fullpath()));
            const curatedChannels = doc.find(curatedChannelXpath);
            for (const channel of curatedChannels) {
                if (ishalted(lockdir)) {
                    break;
                }
                const site = channel.get('@site')?.content;
                const xmltvId = channel.get('@xmltv_id')?.content;
                if (site && xmltvId) {
                    const channelKey = [site, xmltvId].join(':');
                    if (programmes[channelKey] !== undefined) {
                        const [channel, programme] = programmes[channelKey];
                        if (!_date) {
                            _date = channel.parent?.get('@date')?.content;
                        }
                        _channels.push(channel.canonicalizeToString());
                        _programmes.push(...programme.map(a => a.canonicalizeToString()));
                        process.stdout.write('.');
                    }
                }
            }
            if (!ishalted(lockdir)) {
                const lines = [
                    `<?xml version="1.0" encoding="UTF-8" ?><tv date="${_date}">`,
                    ..._channels,
                    ..._programmes,
                    '</tv>'
                ];
                const outfile = path.join(workdir, `${name}.xml`);
                fs.writeFileSync(outfile, lines.join('\n'));
                console.log(`\nSaved to ${outfile}...`);
            }
        }
    } catch (err) {
        console.error(err);
    }
    cleanlock(lockdir);
}

const args = process.argv.slice(2);
if (args.length > 1) {
    run(args[0], args[1], args.length > 2 ? args[2] : null);
}
