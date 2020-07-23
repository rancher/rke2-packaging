# rke2-packaging
Packaging repository for RKE2

## Versioning/Tagging

The version parsing logic for `rancher/rke2-packaging` expects tags to be of a certain format (that directly correlates to RKE2 version)

The following list shows the expected tag to (example) transformation for RPM's

|Tag|Tree State|Output RPM|RPM Channel|Notes|
|:--|:---------|:---------|:----------|:----|
| master (no tag) | Clean | `rke2-common-1.18.4~alpha8~0d52f7d8-0.el7.x86_64.rpm` | Testing | When building with a clean tree on master, it will automatically grab the latest listed release in `rancher/rke2` (pre-release or not)|
| master (no tag) | Dirty | `rke2-common-1.18.4~alpha8~0d52f7d8dirty-0.el7.x86_64.rpm` | Testing | When building with a clean tree on master, it will automatically grab the latest listed release in `rancher/rke2` (pre-release or not)|
| v1.18.4-alpha8+rke2.latest.0 | Clean | `rke2-common-1.18.4~alpha8-0.el7.x86_64.rpm` | Latest ||
| v1.18.4-alpha8+rke2.latest.1 | Clean | `rke2-common-1.18.4~alpha8-1.el7.x86_64.rpm` | Latest ||
| v1.18.4+rke2.stable.0 | Clean | `rke2-common-1.18.4-0.el7.x86_64.rpm` | Stable ||
| v1.18.4+rke2.stable.1 | Clean | `rke2-common-1.18.4-1.el7.x86_64.rpm` | Stable ||
