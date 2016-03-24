# projectatomic/v1.10-migrator

This is the same as the upstream
[docker/v1.10-migrator](https://github.com/docker/v1.10-migrator)
project except that the resulting image is compatible with
the [atomic](https://github.com/projectatomic/atomic)
command-line. Thus, you should be able to migrate your
containers by simply doing:

```
  atomic run projectatomic/v1.10-migrator
```

This will work for most setups. If you have a more
complicated setup, then you will need to pass the required
options yourself:

```
  atomic run projectatomic/v1.10-migrator \
    --graph /custom/path \
    --storage-driver overlay
```

Upstream reference and documentation:

- https://github.com/docker/v1.10-migrator
- https://docs.docker.com/engine/migration/
- https://hub.docker.com/r/docker/v1.10-migrator/
- https://hub.docker.com/r/projectatomic/v1.10-migrator/

To build the image, simply run:

```
  make docker-image-base
```

# docker/v1.10-migrator

Starting from `v1.10` docker uses content addressable IDs for the images and layers instead of using generated ones. This tool calculates SHA256 checksums for docker layer content, so that they don't need to be recalculated when the daemon starts for the first time.

The migration usually runs on daemon startup but it can be quite slow(usually 100-200MB/s) and daemon will not be able to accept requests during that time. You can run this tool instead while the old daemon is still running and skip checksum calculation on startup.

## Usage

```
v1.10-migrator --help
Usage of v1.10-migrator:
  -g, --graph string            Docker root dir (default "/var/lib/docker")
  -s, --storage-driver string   Storage driver to migrate (default "auto")
      --storage-opt value       Set storage driver option (default [])
```

Supported storage drivers are `aufs`, `overlay`, `btrfs`, `vfs` and `devicemapper`. `auto` tries to automatically detect the driver from the root directory. `zfs` is currently not supported.

### Copyright and license

Copyright © 2016 Docker, Inc. All rights reserved, except as follows. Code
is released under the Apache 2.0 license. The README.md file, and files in the
"docs" folder are licensed under the Creative Commons Attribution 4.0
International License under the terms and conditions set forth in the file
"LICENSE.docs". You may obtain a duplicate copy of the same license, titled
CC-BY-SA-4.0, at http://creativecommons.org/licenses/by/4.0/.
