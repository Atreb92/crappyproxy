# CrappyProxy

Quick toggle for the Wi-Fi HTTP/HTTPS proxy on a rootless-jailbroken iOS device
(tested on Dopamine, iOS 16.7.1). Inspired by
[android-proxy-toggle](https://github.com/theappbusiness/android-proxy-toggle).

One `.deb` contains:

- a **Control Centre tile** (needs [CCSupport](https://opa334.github.io/), `com.opa334.ccsupport`),
- a **companion app** with a list of saved proxies,
- **`proxyctl`**, the helper that does the work.

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

## Notes

- `proxyctl` is installed **setuid root**: it must write the system network
  configuration, which the app and the tile (running as `mobile`) cannot. It only
  edits the proxy keys of the Wi-Fi (`en0`) services. Treat it as part of the device's
  trusted base and install this only on devices you control.
- Proxy authentication is not supported.
- `proxyctl dump` and `proxyctl services` are debug commands.

## Licence

MIT, see `LICENSE`.
