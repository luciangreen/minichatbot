:- module(web,
    [ start_server/1,
      stop_server/0
    ]).

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(library(http/json)).
:- use_module(dialogue).
:- use_module(memory).
:- use_module(concepts).

:- dynamic server_port/1.

:- http_handler(root(.), home_handler, []).
:- http_handler(root(chat), chat_handler, [method(post)]).
:- http_handler(root(memory), memory_handler, [method(get)]).
:- http_handler(root(concepts), concepts_handler, [method(get)]).
:- http_handler(root(predictions), predictions_handler, [method(get)]).
:- http_handler(root(forget), forget_handler, [method(post)]).
:- http_handler(root(reset), reset_handler, [method(post)]).

start_server(Port) :-
    stop_server,
    http_server(http_dispatch, [port(Port)]),
    retractall(server_port(_)),
    assertz(server_port(Port)).

stop_server :-
    (   retract(server_port(Port))
    ->  http_stop_server(Port, [])
    ;   true
    ).

home_handler(_Request) :-
    format('Content-type: text/html~n~n'),
    format('<html><body><h1>minichatbot</h1><p>POST /chat with JSON {"input":"..."}</p></body></html>').

chat_handler(Request) :-
    (   read_json_dict_safe(Request, Dict)
    ->  (   _{input:Input} :< Dict
    ->  chat(Input, Response, Debug),
        debug_json(Debug, DebugJson),
        reply_json_dict(_{response:Response, debug:DebugJson})
    ;   reply_json_dict(_{error:"input is required"}, [status(400)])
    )
    ;   reply_json_dict(_{error:"invalid JSON body"}, [status(400)])
    ).

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
    (   read_json_dict_safe(Request, Dict)
    ->  (   _{observation_id:RawId} :< Dict
    ->  (   normalize_request_value(RawId, IdInput)
        ->  (   resolve_observation_id(IdInput, Id)
            ->  (   forget_observation(Id)
                ->  reply_json_dict(_{forgotten:Id})
                ;   reply_json_dict(_{error:"observation not found", observation_id:IdInput}, [status(404)])
                )
            ;   reply_json_dict(_{error:"observation not found", observation_id:IdInput}, [status(404)])
            )
        ;   reply_json_dict(_{error:"observation_id must be a string or atom"}, [status(400)])
        )
    ;   _{concept:RawConcept} :< Dict
    ->  (   normalize_request_value(RawConcept, ConceptInput)
        ->  (   resolve_concept_name(ConceptInput, Concept)
            ->  (   forget_concept(Concept)
                ->  reply_json_dict(_{forgotten:Concept})
                ;   reply_json_dict(_{error:"concept not found", concept:ConceptInput}, [status(404)])
                )
            ;   reply_json_dict(_{error:"concept not found", concept:ConceptInput}, [status(404)])
            )
        ;   reply_json_dict(_{error:"concept must be a string or atom"}, [status(400)])
        )
    ;   reply_json_dict(_{error:"expected observation_id or concept"}, [status(400)])
    )
    ;   reply_json_dict(_{error:"invalid JSON body"}, [status(400)])
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

normalize_request_value(Value, Value) :-
    string(Value),
    !.
normalize_request_value(Value, Value) :-
    atom(Value).

resolve_observation_id(Value, Id) :-
    list_observations(Observations),
    member(observation(Id, _, _), Observations),
    identifier_matches(Value, Id).

resolve_concept_name(Value, Name) :-
    list_concepts(Concepts),
    member(concept(Name, _, _, _), Concepts),
    identifier_matches(Value, Name).

identifier_matches(Value, Id) :-
    atom(Value),
    Value == Id.
identifier_matches(Value, Id) :-
    string(Value),
    atom_string(Id, Value).

read_json_dict_safe(Request, Dict) :-
    catch(http_read_json_dict(Request, Dict), _, fail).
