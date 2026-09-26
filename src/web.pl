:- module(web,
    [ start_server/1,
      stop_server/0
    ]).

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(dialogue).
:- use_module(memory).

:- dynamic server_port/1.

:- http_handler(root(.), home_handler, []).
:- http_handler(root(chat), chat_handler, [method(post)]).
:- http_handler(root(memory), memory_handler, [method(get)]).
:- http_handler(root(concepts), concepts_handler, [method(get)]).
:- http_handler(root(predictions), predictions_handler, [method(get)]).
:- http_handler(root(forget), forget_handler, [method(post)]).
:- http_handler(root(reset), reset_handler, [method(post)]).

start_server(Port) :-
    http_server(http_dispatch, [port(Port)]),
    retractall(server_port(_)),
    assertz(server_port(Port)).

stop_server :-
    server_port(Port),
    http_stop_server(Port, []),
    retractall(server_port(_)).

home_handler(_Request) :-
    format('Content-type: text/html~n~n'),
    format('<html><body><h1>minichatbot</h1><p>POST /chat with JSON {"input":"..."}</p></body></html>').

chat_handler(Request) :-
    http_read_json_dict(Request, Dict),
    chat(Dict.input, Response, Debug),
    debug_json(Debug, DebugJson),
    reply_json_dict(_{response:Response, debug:DebugJson}).

memory_handler(_Request) :-
    memory_snapshot(Snapshot),
    json_term(Snapshot, SnapshotJson),
    reply_json_dict(_{memory:SnapshotJson}).

concepts_handler(_Request) :-
    list_concepts(Concepts),
    json_terms(Concepts, ConceptStrings),
    reply_json_dict(_{concepts:ConceptStrings}).

predictions_handler(_Request) :-
    list_predictions(Predictions),
    json_terms(Predictions, PredictionStrings),
    reply_json_dict(_{predictions:PredictionStrings}).

forget_handler(Request) :-
    http_read_json_dict(Request, Dict),
    (   _{observation_id:Id} :< Dict
    ->  (   forget_observation(Id)
        ->  reply_json_dict(_{forgotten:Id})
        ;   reply_json_dict(_{error:"observation not found", observation_id:Id}, [status(404)])
        )
    ;   _{concept:Concept} :< Dict
    ->  (   forget_concept(Concept)
        ->  reply_json_dict(_{forgotten:Concept})
        ;   reply_json_dict(_{error:"concept not found", concept:Concept}, [status(404)])
        )
    ;   reply_json_dict(_{error:"expected observation_id or concept"}, [status(400)])
    ).

reset_handler(_Request) :-
    reset_memory,
    reset_dialogue,
    reply_json_dict(_{status:"reset"}).

debug_json(Debug, Json) :-
    json_terms(Debug.dimensions, DimensionStrings),
    json_term(Debug.prediction, PredictionString),
    json_term(Debug.explanation, ExplanationString),
    Json = _{
        dimensions:DimensionStrings,
        prediction:PredictionString,
        explanation:ExplanationString
    }.

json_terms(Terms, Strings) :-
    maplist(json_term, Terms, Strings).

json_term(Term, String) :-
    term_string(Term, String).
