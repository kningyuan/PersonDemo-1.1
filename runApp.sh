#!/bin/bash -e


# Parse commandline args
while getopts "h?m:t:clr" opt; do
	case "$opt" in
	h | \?)
		usage
		exit 1
		;;
	m) MODE=$OPTARG ;;

	c) COUCHDB='y' ;;

	l) ENABLE_LOGS='y' ;;

	r) REGENERATE='y' ;;

	t)
		TAG="$OPTARG"
		##TODO: ensure package.json contains right node packages
		if [ "$TAG" == "beta" -o "$TAG" == "rc1" ]; then
			IMAGE_TAG="$(uname -m)-1.0.0-$OPTARG"
		elif [ "$TAG" == "1.0.0" ]; then
			IMAGE_TAG="$(uname -m)-1.0.0"
		else
			usage
		fi
		;;
	esac
done

: ${MODE:="restart"}
: ${IMAGE_TAG:="latest"}
: ${COUCHDB:="n"}
: ${ENABLE_LOGS:="n"}
export IMAGE_TAG

COMPOSE_FILE=./artifacts/docker-compose.yaml
COMPOSE_FILE_WITH_COUCH=./artifacts/docker-compose-couch.yaml
function dkcl() {
	CONTAINERS=$(docker ps -a | wc -l)
	if [ "$CONTAINERS" -gt "1" ]; then
		docker rm -f $(docker ps -aq)
	else
		printf "\n========== No containers available for deletion ==========\n"
	fi
}

function dkrm() {
	DOCKER_IMAGE_IDS=$(docker images | grep "dev\|none\|test-vp\|peer[0-9]-" | awk '{print $3}')
	echo
	if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" = " " ]; then
		echo "========== No images available for deletion ==========="
	else
		docker rmi -f $DOCKER_IMAGE_IDS
	fi
	echo
}

function cleanAndInstall() {
	## Make sure cleanup the node_moudles and re-install them again
	rm -rf ./node_modules

	printf "\n============== Installing node modules =============\n"
	npm install
}

function installNodeModules() {
	echo
	if [ -d node_modules ]; then
		npm ls fabric-client fabric-ca-client || cleanAndInstall
	else
		cleanAndInstall && npm ls fabric-client fabric-ca-client
	fi
	echo
}
function checkForDockerImages() {
	DOCKER_IMAGES=$(docker images | grep "$IMAGE_TAG" | wc -l)
	if [ $DOCKER_IMAGES -ne 9 ]; then
		printf "\n############# You don't have all fabric images, Let me them pull for you ###########\n"
		for IMAGE in peer orderer ca couchdb ccenv javaenv kafka tools zookeeper; do
			docker pull hyperledger/fabric-$IMAGE:$IMAGE_TAG
		done
	fi
}

function startApp() {
	if [ "$IMAGE_TAG" = "latest" ]; then
		printf "\n ========= Using latest Docker images ===========\n"
	else
		printf "\n ========= FABRIC IMAGE TAG : $IMAGE_TAG ===========\n"
		checkForDockerImages
	fi
	### dynamic generation of Org certs and channel artifacts
	if [ "$REGENERATE" = "y" ]; then
		rm -rf ./artifacts/channel/*.block ./artifacts/channel/*.tx ./artifacts/crypto-config
		source artifacts/generateArtifacts.sh
		echo "TODO######"
		exit
	fi

	#Launch the network
	if [ "$COUCHDB" = "y" -o "$COUCHDB" = "Y" ]; then
		docker-compose -f $COMPOSE_FILE -f $COMPOSE_FILE_WITH_COUCH up -d
	else
		rm -rf fabric-client-kv-org*/
		rm -rf /tmp/fabric-client-kv-org*
		sudo rm -rf /var/hyperledger/*
		read
		docker-compose -f $COMPOSE_FILE up -d
	fi
	if [ $? -ne 0 ]; then
		printf "\n\n!!!!!!!! Unable to pull the start the network, Check your docker-compose !!!!!\n\n"
		exit
	fi

	##Install node modules
	installNodeModules

	##Start app on port 4000
	PORT=4000 node app
}

function shutdownApp() {
	printf "\n======================= TEARDOWN NETWORK ====================\n"
	if [ "$ENABLE_LOGS" = "y" -o "$ENABLE_LOGS" = "Y" ]; then
		source ./artifacts/getContainerLogs.sh
	fi
	# teardown the network and clean the containers and intermediate images
	docker-compose -f $COMPOSE_FILE -f $COMPOSE_FILE_WITH_COUCH down
	dkcl
	dkrm
	echo y | docker network prune
	# cleanup the material
	printf "\n======================= CLEANINGUP ARTIFACTS ====================\n\n"
	rm -rf /tmp/hfc-test-kvs_peerOrg* $HOME/.hfc-key-store/ /tmp/fabric-client-kvs_peerOrg*

}

#Launch the network using docker compose
case $MODE in
'start' | 'up')
	startApp
	;;
'stop' | 'down')
	shutdownApp
	;;
'restart')
	shutdownApp
	startApp
	;;
*)
	usage
	;;
esac
