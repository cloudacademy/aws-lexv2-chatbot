import os
from tmdbv3api import TMDb
from tmdbv3api import Movie
from tmdbv3api import Discover

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
    # Dispatch to your bot's intent handlers
    if intent_name == 'MovieRecommendation':
        return MovieRecommendation(intent_request)
    #elif intent_name == 'FollowupCheckBalance':
    #    return FollowupCheckBalance(intent_request)

    raise Exception('Intent with name ' + intent_name + ' not supported')

def lambda_handler(event, context):
    response = dispatch(event)
    return response

