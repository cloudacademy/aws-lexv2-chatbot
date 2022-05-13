# Amazon Lex Movie Recommendations Chatbot

## Introduction
A simple [Amazon Lex](https://aws.amazon.com/lex/) Chatbot that is able to provide movie recommendations for a given movie genre. This implementation is performed using [Amazon Lex V2](https://docs.aws.amazon.com/lexv2/latest/dg/what-is.html).

## Amazon Lex V2 Slides
![AWSLexV2Chatbots.pdf](./doc/AWSLexV2Chatbots.pdf)

## Integration
Movie recommendation data is provided by The Movie Database ([TMDB](https://www.themoviedb.org/)). 

![import chatbot package](./doc/images/TMDB.png)

## Lambda Function
The chatbot integrates with [TMDB API](https://developers.themoviedb.org/3) endpoint using a custom AWS [Lambda Function](./lambda/lambda_function.py) developed in Python3:

```python
import os
from tmdbv3api import TMDb, Discover

tmdb = TMDb()
tmdb.api_key = os.getenv('APIKEY')

GENRES = {
"action": 28,
"adventure": 12,
"animation": 16,
"comedy": 35,
"crime": 80,
"documentary": 99,
"drama": 18,
"family": 10751,
"Fantasy": 14,
"history": 36,
"horror": 27,
"music": 10402,
"mystery": 9648,
"romance": 10749,
"science fiction": 878,
"thriller": 53,
"war": 10752,
"western": 37
}

def get_slots(intent_request):
    return intent_request['sessionState']['intent']['slots']
    
def get_slot(intent_request, slotName):
    slots = get_slots(intent_request)
    if slots is not None and slotName in slots and slots[slotName] is not None:
        return slots[slotName]['value']['interpretedValue']
    else:
        return None    

def get_session_attributes(intent_request):
    sessionState = intent_request['sessionState']
    if 'sessionAttributes' in sessionState:
        return sessionState['sessionAttributes']

    return {}

def elicit_intent(intent_request, session_attributes, message):
    return {
        'sessionState': {
            'dialogAction': {
                'type': 'ElicitIntent'
            },
            'sessionAttributes': session_attributes
        },
        'messages': [ message ] if message != None else None,
        'requestAttributes': intent_request['requestAttributes'] if 'requestAttributes' in intent_request else None
    }

def close(intent_request, session_attributes, fulfillment_state, message):
    intent_request['sessionState']['intent']['state'] = fulfillment_state
    return {
        'sessionState': {
            'sessionAttributes': session_attributes,
            'dialogAction': {
                'type': 'Close'
            },
            'intent': intent_request['sessionState']['intent']
        },
        'messages': [message],
        'sessionId': intent_request['sessionId'],
        'requestAttributes': intent_request['requestAttributes'] if 'requestAttributes' in intent_request else None
    }

def MovieRecommendation(intent_request):
    session_attributes = get_session_attributes(intent_request)
    slots = get_slots(intent_request)
    genre = get_slot(intent_request, 'genre')

    discover = Discover()
    movies = discover.discover_movies({
        'primary_release_date.gte': '2019-01-01',
        'primary_release_date.lte': '2021-12-01',
        'with_genres': GENRES.get(genre.lower())
    })

    recs = ""
    for movie in movies:
        recs = recs + f" {movie.title}, "

    text = f"Thank you. Your recommended movies are: {recs}"
    message =  {
            'contentType': 'PlainText',
            'content': text
        }

    fulfillment_state = "Fulfilled"    
    return close(intent_request, session_attributes, fulfillment_state, message)
    
def dispatch(intent_request):
    intent_name = intent_request['sessionState']['intent']['name']
    response = None

    if intent_name == 'MovieRecommendation':
        return MovieRecommendation(intent_request)
    #elif intent_name == 'OtherIntent':
    #    return OtherIntent(intent_request)

    raise Exception('Intent with name ' + intent_name + ' not supported')

def lambda_handler(event, context):
    response = dispatch(event)
    return response
```

## Installation
1. Register for a TMDB API key
2. Within the **install.sh** file, update the ```APIKEY``` variable:

**install.sh**:
```
APIKEY=TMDB_API_KEY_HERE
```
3. Execute the **install.sh** script
4. Log in to the AWS Lex console and then import the newly created **lex-movierecommendations.zip** package

![import chatbot package](./doc/images/image1.png)
![import chatbot package](./doc/images/image2.png)

Set the following options:

- **Bot name**, enter ```MovieRecommendations```

- **IAM permissions**, select **create a role with basic Amazon Lex permissions**

- **Childrens Online Privacy Protection Act**, select **No**

5. After the import has succeeded - in the lefthand menu navigate to **Deployment/Aliases** for the newly created **MovieRecommendations** bot and click on the **TestBotAlias**

![bind lambda function](./doc/images/image3.png)

6. Within the **TestBotAlias** click on the **English** language

![bind lambda function](./doc/images/image4.png)

7. Select **movierecommendations** for **Source**, and **$LATEST** for **Lambda function version or alias**. Click Save.

![bind lambda function](./doc/images/image5.png)

8. In the lefthand menu navigate to **Bot versions/Draft version**, and then under **Languages** click on the **English** language link.

![bind lambda function](./doc/images/image6.png)

9. In the bottom menu bar click on the **build** button to compile the MovieRecommendations Chatbot.

![bind lambda function](./doc/images/image7.png)

10. Confirm that the MovieRecommendations Chatbot build has completed successfully.

![bind lambda function](./doc/images/image8.png)

11. Confirm that the MovieRecommendations Chatbot build has completed successfully, and then click on the **Test** button to activate the Chatbot.

12. Within the Chatbot test pane, enter any of the following utterances to start the Chatbot conversation:

```
recommend a movie
recommend a {genre} movie
recommend a {genre} film
I want to watch a movie
I want to watch a {genre} movie
```

Note: The following movie genres are supported:

```
Action
Adventure
Animation
Comedy
Crime
Documentary
Drama
Family
Fantasy
History
Horror
Music
Mystery
Romance
Science Fiction
Thriller
War
Western
```

Example Chatbot conversation:

![bind lambda function](./doc/images/image9.png)
