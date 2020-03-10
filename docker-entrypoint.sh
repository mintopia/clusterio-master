#!/bin/bash
if [ "$CLUSTERIO_MODE" != "master" ] && [ "$CLUSTERIO_MODE" != "client" ]
then
	echo "Please specify a mode by setting CLUSTERIO_MODE to client or master!" >&2
	exit -1
fi

# Generate a config file from environment variables
/factorioClusterio/make-config.sh || exit -1

echo "Starting $INSTANCE in mode $CLUSTERIO_MODE"
if [ "$CLUSTERIO_MODE" == "master" ]
then
	if [ ! -e secret-api-token.txt ]; then
		echo "Running to generate secret API token"
		node master.js
	fi;
	echo "API Token: $(cat secret-api-token.txt)"
	node master.js
elif [ "$CLUSTERIO_MODE" == "client" ]
then
	# create instance on client
	node client.js start $INSTANCE
	node client.js manage shared mods add clusterio
	node client.js start $INSTANCE
fi
