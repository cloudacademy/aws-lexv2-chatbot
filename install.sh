#!/bin/bash
APIKEY=TMDB_API_KEY_HERE

find . -name '.DS_Store' -type f -delete

pushd lambda
rm -rf ./package
pip3 install --target ./package tmdbv3api
pushd ./package
zip -r ../lambda-movieapi.zip .
popd
zip -g lambda-movieapi.zip lambda_function.py

if ! aws iam get-role --role-name AWSServiceRoleForLexBots; then
    aws iam create-service-linked-role --aws-service-name lex.amazonaws.com
fi

if aws lambda get-function --function-name movierecommendations; then
    aws lambda delete-function --function-name movierecommendations
fi

aws lambda create-function \
    --function-name movierecommendations \
    --runtime python3.9 \
    --zip-file fileb://lambda-movieapi.zip \
    --handler lambda_function.lambda_handler \
    --environment Variables="{APIKEY=$APIKEY}" \
    --role arn:aws:iam::379242798045:role/service-role/MovieAPI-role-a07iyqe9

popd
pushd lex
zip -r ../lex-movierecommendations.zip .
popd

echo
echo ===========================
echo "within the AWS Lex console:" 
echo "import the lex-movierecommendations.zip package"
echo ===========================