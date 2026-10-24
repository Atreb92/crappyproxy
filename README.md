# CrappyProxy

Quick toggle for the Wi-Fi HTTP/HTTPS proxy on a rootless-jailbroken iOS device
(tested on Dopamine, iOS 16.7.1). Inspired by
[android-proxy-toggle](https://github.com/theappbusiness/android-proxy-toggle).

One `.deb` contains:

- a **Control Centre tile** (needs [CCSupport](https://opa334.github.io/), `com.opa334.ccsupport`),
- a **companion app** with a list of saved proxies,
- **`proxyctl`**, the helper that does the work.

## Install

**From Sileo (recommended):**

1. In Sileo, go to Sources › **+** and add `https://atreb92.github.io/crappyproxy/`.
2. Install **CrappyProxy**. It requires **CCSupport** (`com.opa334.ccsupport`, rootless build) for the
   Control Centre tile.
3. Respring, then add *Proxy* in Settings › Control Centre.

**From a .deb:** install CCSupport first, then `dpkg -i` the `.deb` from the
[latest release](https://github.com/Atreb92/crappyproxy/releases/latest) and respring.

## Usage

Add a proxy in the CrappyProxy app, then use the app's switch or the Control Centre
tile (Settings → Control Centre → add *Proxy*). The tile and the switch turn the
saved proxy on and off for the Wi-Fi network.

`proxyctl` can also be used directly: `proxyctl on [host port] | off | set host port | status | get`.

## Build

Needs [Theos](https://theos.dev) and an iOS 16.x SDK:

    export THEOS=~/theos
    USER=root make package

Theos's fakeroot step can fail on some Linux hosts; building as `USER=root` avoids it.
The result is a rootless (`/var/jb`) package in `packages/`.

### Publishing a release (maintainers)

```sh
make package FINALPACKAGE=1 && scripts/mkrepo.sh   # updates repo/ (the Sileo source)
git add repo && git commit && git push             # a workflow deploys repo/ to GitHub Pages
gh release create v<version> packages/com.atreb92.crappyproxy_<version>_iphoneos-arm64.deb
```

## Security

`proxyctl` is installed **setuid root**: it has to write the system network configuration,
which the app and the tile (running as `mobile`) cannot. It only edits the proxy keys of the
Wi-Fi (`en0`) services.

- Only root and the device's `mobile` user (looked up, not assumed to be uid 501) may run it.
- Host and port are validated, and the saved host/port file (writable by `mobile`) is type-checked.
- It cannot tell *which* program called it. Any process running as `mobile` that can execute
  it can redirect the phone's Wi-Fi HTTP/HTTPS traffic. Install this only on devices you
  control. A root daemon that checks its callers over XPC would close that gap.
- The `dump` and `services` commands exist only in debug builds (plain `make package`);
  `FINALPACKAGE=1 make package` leaves them out.

## Notes

- Proxy authentication is not supported.

## Licence

MIT, see `LICENSE`.
