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
	"channelConfigPath":"../artifacts/channel/person1.tx",
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
	"peers": ["192.168.1.200:7051","192.168.1.200:8051"]
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
	"peers": ["192.168.1.200:9051","192.168.1.200:10051"]
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
	\"peers\": [\"192.168.1.200:7051\",\"192.168.1.200:8051\"],
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
	\"peers\": [\"192.168.1.200:9051\",\"192.168.1.200:10051\"],
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
	\"peers\": [\"192.168.1.200:7051\",\"192.168.1.200:8051\"],
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
	\"peers\": [\"192.168.1.200:9051\",\"192.168.1.200:10051\"],
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
	\"peers\": [\"192.168.1.200:7051\",\"192.168.1.200:8051\"],
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
	\"peers\": [\"192.168.1.200:9051\",\"192.168.1.200:10051\"],
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
	\"peers\": [\"192.168.1.200:7051\",\"192.168.1.200:8051\"],
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
	\"peers\": [\"192.168.1.200:9051\",\"192.168.1.200:10051\"],
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

#echo "===========================test person==================="


echo "POST invoke chaincode on peers of Org1[注册用户 person_test]"
echo
curl -s -X POST \
  http://192.168.1.200:4000/channels/person1/chaincodes/account \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["192.168.1.200:7051","192.168.1.200:8051"],
	"fcn":"register_account",
	"args":["person_test","password_test","id_person_test"]
}'
echo
echo

echo "GET query chaincode on peer1 of Org1 [账户查询 person_test ]"
echo
curl -s -X GET \
  "http://192.168.1.200:4000/channels/person1/chaincodes/account?peer=peer1&fcn=query_account&args=%5b%22person_test%22%2c%22person_test%22%2c%22password_test%22%5d" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

echo "POST invoke chaincode on peers of Org1[实名制 person_test]"
echo
curl -s -X POST \
  http://192.168.1.200:4000/channels/person1/chaincodes/person \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["192.168.1.200:7051","192.168.1.200:8051"],
	"fcn":"add_person",
	"args":["name_test","id_person_test","age_test","school_test","mobile_test","email_test","person_test","password_test"]
}'
echo
echo

echo "GET query chaincode on peer1 of Org1 [权限记录查询 2] "
echo
curl -s -X GET \
  "http://192.168.1.200:4000/channels/person1/chaincodes/authority?peer=peer1&fcn=query_authority_list&args=%5b%222%22%5d" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo


echo "GET query chaincode on peer1 of Org1 [记录查询  person_test]  "
echo
curl -s -X GET \
  "http://192.168.1.200:4000/channels/person1/chaincodes/person?peer=peer1&fcn=query_person&args=%5b%222%22%2c%22person_test%22%2c%22password_test%22%5d" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

echo "POST invoke chaincode on peers of Org1[注册用户 person_test1]"
echo
curl -s -X POST \
  http://192.168.1.200:4000/channels/person1/chaincodes/account \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["192.168.1.200:7051","192.168.1.200:8051"],
	"fcn":"register_account",
	"args":["person_test1","password_test","id_person_test"]
}'
echo
echo

echo "POST invoke chaincode on peers of Org1[实名制 person_test1]"
echo 
curl -s -X POST \
  http://192.168.1.200:4000/channels/person1/chaincodes/person \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["192.168.1.200:7051","192.168.1.200:8051"],
	"fcn":"add_person",
	"args":["name_test","id_person_test","age_test","school_test","mobile_test","email_test","person_test1","password_test"]
}'
echo
echo

echo "GET query chaincode on peer1 of Org1 [权限记录查询 3] "
echo
curl -s -X GET \
  "http://192.168.1.200:4000/channels/person1/chaincodes/authority?peer=peer1&fcn=query_authority_list&args=%5b%223%22%5d" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo


echo "GET query chaincode on peer1 of Org1 [记录查询  person_test1]  "
echo
curl -s -X GET \
  "http://192.168.1.200:4000/channels/person1/chaincodes/person?peer=peer1&fcn=query_person&args=%5b%223%22%2c%22person_test%22%2c%22password_test%22%5d" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo


echo "GET query chaincode on peer1 of Org1 [authourty all list 记录查询] "
echo
curl -s -X GET \
  "http://192.168.1.200:4000/channels/person1/chaincodes/authority?peer=peer1&fcn=query_all_authority_list&args=%5b%22Authority%22%5d" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

echo "GET query chaincode on peer1 of Org1 [person_test1 记录查询 person_test  error] "
echo
curl -s -X GET \
  "http://192.168.1.200:4000/channels/person1/chaincodes/person?peer=peer1&fcn=query_person&args=%5b%222%22%2c%22person_test1%22%2c%22password_test%22%5d" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

echo "POST invoke chaincode on peers of Org1[person_test授权 person_test1]"
echo
curl -s -X POST \
  http://192.168.1.200:4000/channels/person1/chaincodes/authority \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["192.168.1.200:7051","192.168.1.200:8051"],
	"fcn":"user_authority",
	"args":["2","person_test1","authority","person_test","password_test"]
}'
echo
echo

echo "GET query chaincode on peer1 of Org1 [person_test1 记录查询 person_test] "
echo
curl -s -X GET \
  "http://192.168.1.200:4000/channels/person1/chaincodes/person?peer=peer1&fcn=query_person&args=%5b%222%22%2c%22person_test1%22%2c%22password_test%22%5d" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

echo "POST invoke chaincode on peers of Org1[person_test 取消授权 person_test1]"
echo
curl -s -X POST \
  http://192.168.1.200:4000/channels/person1/chaincodes/authority \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["192.168.1.200:7051","192.168.1.200:8051"],
	"fcn":"user_authority",
	"args":["2","person_test1","cancel","person_test","password_test"]
}'
echo
echo

echo "GET query chaincode on peer1 of Org1 [person_test1 记录查询 person_test error] "
echo
curl -s -X GET \
  "http://192.168.1.200:4000/channels/person1/chaincodes/person?peer=peer1&fcn=query_person&args=%5b%222%22%2c%22person_test1%22%2c%22password_test%22%5d" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

echo "POST invoke chaincode on peers of Org1[person_test托管 OK]"
echo
curl -s -X POST \
  http://192.168.1.200:4000/channels/person1/chaincodes/authority \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["192.168.1.200:7051","192.168.1.200:8051"],
	"fcn":"admin_collocation",
	"args":["2","collocation","person_test","password_test"]
}'
echo
echo

echo "POST invoke chaincode on peers of Org1[person_test1托管 OK]"
echo
curl -s -X POST \
  http://192.168.1.200:4000/channels/person1/chaincodes/authority \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["192.168.1.200:7051","192.168.1.200:8051"],
	"fcn":"admin_collocation",
	"args":["3","collocation","person_test1","password_test"]
}'
echo
echo

echo "POST invoke chaincode on peers of Org1[admin授权 person_test1]"
echo
curl -s -X POST \
  http://192.168.1.200:4000/channels/person1/chaincodes/authority \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["192.168.1.200:7051","192.168.1.200:8051"],
	"fcn":"admin_authority",
	"args":["2","person_test1","authority","admin","admin"]
}'
echo
echo

echo "POST invoke chaincode on peers of Org1[admin授权 person_test]"
echo
curl -s -X POST \
  http://192.168.1.200:4000/channels/person1/chaincodes/authority \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["192.168.1.200:7051","192.168.1.200:8051"],
	"fcn":"admin_authority",
	"args":["3","person_test","authority","admin","admin"]
}'
echo
echo


echo "GET query chaincode on peer1 of Org1 [person_test1 记录查询 person_test OK] "
echo
curl -s -X GET \
  "http://192.168.1.200:4000/channels/person1/chaincodes/person?peer=peer1&fcn=query_person&args=%5b%222%22%2c%22person_test1%22%2c%22password_test%22%5d" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

echo "GET query chaincode on peer1 of Org1 [person_test 记录查询 person_test1 OK] "
echo
curl -s -X GET \
  "http://192.168.1.200:4000/channels/person1/chaincodes/person?peer=peer1&fcn=query_person&args=%5b%223%22%2c%22person_test%22%2c%22password_test%22%5d" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

echo "POST invoke chaincode on peers of Org1[admin 取消授权 person_test]"
echo
curl -s -X POST \
  http://192.168.1.200:4000/channels/person1/chaincodes/authority \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["192.168.1.200:7051","192.168.1.200:8051"],
	"fcn":"admin_authority",
	"args":["3","person_test","cancel","admin","admin"]
}'
echo
echo

echo "GET query chaincode on peer1 of Org1 [权限记录查询 3] "
echo
curl -s -X GET \
  "http://192.168.1.200:4000/channels/person1/chaincodes/authority?peer=peer1&fcn=query_authority_list&args=%5b%223%22%5d" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

echo "POST invoke chaincode on peers of Org1[user 取消授权 person_test]"
echo
curl -s -X POST \
  http://192.168.1.200:4000/channels/person1/chaincodes/authority \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["192.168.1.200:7051","192.168.1.200:8051"],
	"fcn":"user_authority",
	"args":["3","person_test","cancel","person_test1","password_test"]
}'
echo
echo

echo "GET query chaincode on peer1 of Org1 [person_test 记录查询 person_test1 error] "
echo
curl -s -X GET \
  "http://192.168.1.200:4000/channels/person1/chaincodes/person?peer=peer1&fcn=query_person&args=%5b%223%22%2c%22person_test%22%2c%22password_test%22%5d" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

echo "Total execution time : $(($(date +%s)-starttime)) secs ..."
