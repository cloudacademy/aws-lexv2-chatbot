#!/bin/bash
APIKEY=TMDB_API_KEY_HERE
AWS_ACCOUNT_ID=$(aws iam get-user | grep Arn | cut -d':' -f6)

# cleanups
find . -name '.DS_Store' -type f -delete
rm -rf lambda/package
rm -f lambda/lambda-movieapi.zip
rm -f lex-movierecommendations.zip

echo
echo step1: packaging the lambda function...
echo
pushd lambda
rm -rf ./package
pip3 install --target ./package tmdbv3api
pushd ./package
zip -r ../lambda-movieapi.zip .
popd
zip -g lambda-movieapi.zip lambda_function.py

echo
echo step2: creating lex service linked role...
echo
if ! aws iam get-role --role-name AWSServiceRoleForLexBots > /dev/null 2>&1; then
    aws iam create-service-linked-role --aws-service-name lex.amazonaws.com
fi

echo
echo step3: creating lambda exec policy...
echo
if ! aws iam get-policy --policy-arn arn:aws:iam::$AWS_ACCOUNT_ID:policy/LexChatbotLambdaExecPolicy > /dev/null 2>&1; then
    aws iam create-policy --policy-name LexChatbotLambdaExecPolicy --policy-document file://lambda_exec_iam_policy.json 
fi

LAMBDA_POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName == 'LexChatbotLambdaExecPolicy'].Arn" --output text)
echo LAMBDA_POLICY_ARN=$LAMBDA_POLICY_ARN

echo
echo step4: creating lambda exec role...
echo
if ! aws iam get-role --role-name LexChatbotLambdaExecRole > /dev/null 2>&1; then
    aws iam create-role --role-name LexChatbotLambdaExecRole --assume-role-policy-document file://lambda_trust_policy.json
    aws iam attach-role-policy --policy-arn $LAMBDA_POLICY_ARN --role-name LexChatbotLambdaExecRole
fi

LAMBDA_ROLE_ARN=$(aws iam list-roles --query "Roles[?RoleName == 'LexChatbotLambdaExecRole'].Arn" --output text)
echo LAMBDA_ROLE_ARN=$LAMBDA_ROLE_ARN

echo
echo step5: creating lambda function...
echo
if aws lambda get-function --function-name movierecommendations > /dev/null 2>&1; then
    aws lambda delete-function --function-name movierecommendations
fi

ATTEMPTS=0
until aws lambda create-function \
    --function-name movierecommendations \
    --runtime python3.9 \
    --zip-file fileb://lambda-movieapi.zip \
    --handler lambda_function.lambda_handler \
    --environment Variables="{APIKEY=$APIKEY}" \
    --role $LAMBDA_ROLE_ARN &> /dev/null
do
    if [ $ATTEMPTS -eq 5 ]; then
        echo unable to create lambda function...
        exit 1
    fi
    sleep 2
    ((ATTEMPTS++))
    echo "retrying ($ATTEMPTS of 5)..."
done

echo lambda function created!

echo
echo step6: packaging the lex chatbot deployment...
echo
popd
pushd lex
zip -r ../lex-movierecommendations.zip .
popd

echo
echo ===========================
echo "within the AWS Lex console:" 
echo "import the lex-movierecommendations.zip package"
echo ===========================