This script installs libraries and codes on AWS GPU instances

## Quick Start

To build all libraries and codes, simply run

```
source driver.sh
```

## Toggle Installs/Builds

To install only select libraries or codes, edit the `driver.sh` script and set `INSTALL_ALL_LIBRARIES=false` and/or `INSTALL_ALL_CODES=false` and toggle to `true` the desired libraries/codes to install

## Current List of Supported Codes

```
DESC
TERPSICHORE
GX
```