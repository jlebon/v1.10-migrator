#!/bin/bash
set -euo pipefail

# This is a small wrapper script that automatically fetches
# the storage options from the docker-storage sysconfig file
# and passes them to the migrator. However, it makes sure to
# take out the use_deferred_removal option, which won't work
# in a container:
#
#   https://github.com/docker/v1.10-migrator/issues/12
#
# If the script is passed arguments, then no magic is done
# and all arguments are directly passed to the migrator.
# This allows users to avoid having to override the
# entrypoint if they have custom settings not supported by
# this script.

# act as a passthrough if args given
if [ $# -ne 0 ]; then
	exec /v1.10-migrator-local "$@"
fi

MIGRATOR=/usr/bin/v1.10-migrator-local
STORAGE_FILE=/host/etc/sysconfig/docker-storage
GRAPH=/host/var/lib/docker

if [ ! -d "$GRAPH" ]; then
	echo "ERROR: Cannot find docker root dir at \"$GRAPH\"." >&2
	exit 1
fi

# Note that this approach is not rock-solid. The actual
# parser in systemd supports specifier expansion and
# multiline definitions. If we want to be as technically
# correct as possible, then we could use an INSTALL label to
# put in a systemd file that picks up the env and runs the
# migrator and in RUN just use systemctl start.

# yuck yuck yuck
storage_opts=
if [ -r "$STORAGE_FILE" ] && grep -q -E '^DOCKER_STORAGE_OPTIONS\s*=' "$STORAGE_FILE"; then
	storage_opts=$(sed -n -e 's/^DOCKER_STORAGE_OPTIONS\s*=\s*// p' "$STORAGE_FILE")
	storage_opts=${storage_opts#\"}
	storage_opts=${storage_opts%\"}
fi

# more yuckyness -- we have to make sure we take out use_deferred_removal
is_storage_opt=0
final_storage_opts=
for opt in $storage_opts; do
	if [[ $opt == --storage-opt ]]; then
		is_storage_opt=1
	elif [[ $opt == dm.use_deferred_removal ]] || \
	     [[ $opt == dm.use_deferred_removal=true ]]; then
		if [ $is_storage_opt != 1 ]; then
			echo "ERROR: malformed DOCKER_STORAGE_OPTIONS in \"$STORAGE_FILE\""
			exit 1
		fi
		is_storage_opt=0
	elif [[ $opt == --storage-opt=dm.use_deferred_removal ]] || \
	     [[ $opt == --storage-opt=dm.use_deferred_removal=true ]]; then
		if [ $is_storage_opt != 0 ]; then
			echo "ERROR: malformed DOCKER_STORAGE_OPTIONS in \"$STORAGE_FILE\""
			exit 1
		fi
	else
		if [ $is_storage_opt == 1 ]; then
			final_storage_opts="$final_storage_opts --storage-opt"
			is_storage_opt=0
		fi
		final_storage_opts="$final_storage_opts $opt"
	fi
done

CMD="/v1.10-migrator-local --graph $GRAPH $final_storage_opts"
echo "RUNNING: $CMD"
eval $CMD
