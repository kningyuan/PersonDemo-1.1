#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

jq --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "Please Install 'jq' https://stedolan.github.io/jq/ to execute this script"
	echo
	exit 1
fi

starttime=$(date +%s)

# Print the usage message
function printHelp () {
  echo "Usage: "
  echo "  ./testAPIs.sh -l golang|node"
  echo "    -l <language> - chaincode language (defaults to \"golang\")"
}
# Language defaults to "golang"
LANGUAGE="golang"

# Parse commandline args
while getopts "h?l:" opt; do
  case "$opt" in
    h|\?)
      printHelp
      exit 0
    ;;
    l)  LANGUAGE=$OPTARG
    ;;
  esac
done

##set chaincode path
function setChaincodePath(){
	LANGUAGE=`echo "$LANGUAGE" | tr '[:upper:]' '[:lower:]'`
	case "$LANGUAGE" in
		"golang")
		CC_SRC_PATH0="github.com/example_cc/go0"
		CC_SRC_PATH1="github.com/example_cc/go1"
		CC_SRC_PATH2="github.com/example_cc/go2"
		CC_SRC_PATH3="github.com/example_cc/go3"
		;;
		"node")
		CC_SRC_PATH="$PWD/artifacts/src/github.com/example_cc/node"
		;;
		*) printf "\n ------ Language $LANGUAGE is not supported yet ------\n"$
		exit 1
	esac
}

setChaincodePath

echo "POST request Enroll on Org1  ..."
echo
ORG1_TOKEN=$(curl -s -X POST \
  http://192.168.1.200:4000/users \
  -H "content-type: application/x-www-form-urlencoded" \
  -d 'username=Jim&orgName=Org1')
echo $ORG1_TOKEN
ORG1_TOKEN=$(echo $ORG1_TOKEN | jq ".token" | sed "s/\"//g")
echo
echo "ORG1 token is $ORG1_TOKEN"
echo

echo "POST request Enroll on Org2 ..."
echo
ORG2_TOKEN=$(curl -s -X POST \
  http://192.168.1.200:4000/users \
  -H "content-type: application/x-www-form-urlencoded" \
  -d 'username=Barry&orgName=Org2')
echo $ORG2_TOKEN
ORG2_TOKEN=$(echo $ORG2_TOKEN | jq ".token" | sed "s/\"//g")
echo
echo "ORG2 token is $ORG2_TOKEN"
echo
echo

echo "POST request Create channel  ..."
echo
curl -s -X POST \
  http://192.168.1.200:4000/channels \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"channelName":"person1",
	"channelConfigPath":"../artifacts/channel/person1.tx"
}'
echo
echo
sleep 20

echo "POST request Join channel on Org1"
echo
curl -s -X POST \
  http://192.168.1.200:4000/channels/person1/peers \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["peer0.org1.example.com","peer1.org1.example.com"]
}'
echo
echo

echo "POST request Join channel on Org2"
echo
curl -s -X POST \
  http://192.168.1.200:4000/channels/person1/peers \
  -H "authorization: Bearer $ORG2_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["peer0.org2.example.com","peer1.org2.example.com"]
}'
echo
echo

echo "common"
echo "POST Install chaincode on Org1"
echo
curl -s -X POST \
  http://192.168.1.200:4000/chaincodes \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d "{
	\"peers\": [\"peer0.org1.example.com\",\"peer1.org1.example.com\"],
	\"chaincodeName\":\"common\",
	\"chaincodePath\":\"$CC_SRC_PATH0\",
	\"chaincodeType\": \"$LANGUAGE\",
	\"chaincodeVersion\":\"v0\"
}"
echo
echo

echo "POST Install chaincode on Org2"
echo
curl -s -X POST \
  http://192.168.1.200:4000/chaincodes \
  -H "authorization: Bearer $ORG2_TOKEN" \
  -H "content-type: application/json" \
  -d "{
	\"peers\": [\"peer0.org2.example.com\",\"peer1.org2.example.com\"],
	\"chaincodeName\":\"common\",
	\"chaincodePath\":\"$CC_SRC_PATH0\",
	\"chaincodeType\": \"$LANGUAGE\",
	\"chaincodeVersion\":\"v0\"
}"
echo
echo

echo "person"
echo "POST Install chaincode on Org1"
echo
curl -s -X POST \
  http://192.168.1.200:4000/chaincodes \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d "{
	\"peers\": [\"peer0.org1.example.com\",\"peer1.org1.example.com\"],
	\"chaincodeName\":\"person\",
	\"chaincodePath\":\"$CC_SRC_PATH1\",
	\"chaincodeType\": \"$LANGUAGE\",
	\"chaincodeVersion\":\"v0\"
}"
echo
echo

echo "POST Install chaincode on Org2"
echo
curl -s -X POST \
  http://192.168.1.200:4000/chaincodes \
  -H "authorization: Bearer $ORG2_TOKEN" \
  -H "content-type: application/json" \
  -d "{
	\"peers\": [\"peer0.org2.example.com\",\"peer1.org2.example.com\"],
	\"chaincodeName\":\"person\",
	\"chaincodePath\":\"$CC_SRC_PATH1\",
	\"chaincodeType\": \"$LANGUAGE\",
	\"chaincodeVersion\":\"v0\"
}"
echo
echo

echo "account"
echo "POST Install chaincode on Org1"
echo
curl -s -X POST \
  http://192.168.1.200:4000/chaincodes \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d "{
	\"peers\": [\"peer0.org1.example.com\",\"peer1.org1.example.com\"],
	\"chaincodeName\":\"account\",
	\"chaincodePath\":\"$CC_SRC_PATH2\",
	\"chaincodeType\": \"$LANGUAGE\",
	\"chaincodeVersion\":\"v0\"
}"
echo
echo

echo "POST Install chaincode on Org2"
echo
curl -s -X POST \
  http://192.168.1.200:4000/chaincodes \
  -H "authorization: Bearer $ORG2_TOKEN" \
  -H "content-type: application/json" \
  -d "{
	\"peers\": [\"peer0.org2.example.com\",\"peer1.org2.example.com\"],
	\"chaincodeName\":\"account\",
	\"chaincodePath\":\"$CC_SRC_PATH2\",
	\"chaincodeType\": \"$LANGUAGE\",
	\"chaincodeVersion\":\"v0\"
}"
echo
echo

echo "authority"
echo "POST Install chaincode on Org1"
echo
curl -s -X POST \
  http://192.168.1.200:4000/chaincodes \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d "{
	\"peers\": [\"peer0.org1.example.com\",\"peer1.org1.example.com\"],
	\"chaincodeName\":\"authority\",
	\"chaincodePath\":\"$CC_SRC_PATH3\",
	\"chaincodeType\": \"$LANGUAGE\",
	\"chaincodeVersion\":\"v0\"
}"
echo
echo
echo "POST Install chaincode on Org2"
echo
curl -s -X POST \
  http://192.168.1.200:4000/chaincodes \
  -H "authorization: Bearer $ORG2_TOKEN" \
  -H "content-type: application/json" \
  -d "{
	\"peers\": [\"peer0.org2.example.com\",\"peer1.org2.example.com\"],
	\"chaincodeName\":\"authority\",
	\"chaincodePath\":\"$CC_SRC_PATH3\",
	\"chaincodeType\": \"$LANGUAGE\",
	\"chaincodeVersion\":\"v0\"
}"
echo
echo
echo "POST instantiate common chaincode on peer1 of Org1"
echo
curl -s -X POST \
  http://192.168.1.200:4000/channels/person1/chaincodes \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d "{
	\"chaincodeName\":\"common\",
	\"chaincodeVersion\":\"v0\",
	\"chaincodeType\": \"$LANGUAGE\",
	\"functionName\":\"init\",
	\"args\":[\"a\",\"100\",\"b\",\"200\"]
}"
echo
echo

echo "POST instantiate person chaincode on peer1 of Org1"
echo
curl -s -X POST \
  http://192.168.1.200:4000/channels/person1/chaincodes \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d "{
	\"chaincodeName\":\"person\",
	\"chaincodeVersion\":\"v0\",
	\"chaincodeType\": \"$LANGUAGE\",
	\"functionName\":\"init\",
	\"args\":[\"a\",\"100\",\"b\",\"200\"]
}"
echo
echo

echo "POST instantiate account chaincode on peer1 of Org1"
echo
curl -s -X POST \
  http://192.168.1.200:4000/channels/person1/chaincodes \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d "{
	\"chaincodeName\":\"account\",
	\"chaincodeVersion\":\"v0\",
	\"chaincodeType\": \"$LANGUAGE\",
	\"functionName\":\"init\",
	\"args\":[\"a\",\"100\",\"b\",\"200\"]
}"
echo
echo

echo "POST instantiate authority chaincode on peer1 of Org1"
echo
curl -s -X POST \
  http://192.168.1.200:4000/channels/person1/chaincodes \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d "{
	\"chaincodeName\":\"authority\",
	\"chaincodeVersion\":\"v0\",
	\"chaincodeType\": \"$LANGUAGE\",
	\"functionName\":\"init\",
	\"args\":[\"a\",\"100\",\"b\",\"200\"]
}"
echo
echo

echo "Total execution time : $(($(date +%s)-starttime)) secs ..."
