:- begin_tests(web_api).

:- use_module('../src/chatbot.pl').
:- use_module('../src/memory.pl').
:- use_module('../src/concepts.pl').
:- use_module(library(http/http_open)).
:- use_module(library(http/http_client)).
:- use_module(library(http/json)).

test(web_chat_success_response, [setup(bootstrap), cleanup(stop_server)]) :-
    once((
        start_server(8097),
        setup_call_cleanup(
            http_open('http://127.0.0.1:8097/chat', Stream, [
                method(post),
                post(string('{"input":"robot finds father"}')),
                request_header('Content-Type'='application/json')
            ]),
            json_read_dict(Stream, Json),
            close(Stream)
        ),
        Json.response == "learned",
        is_dict(Json.debug),
        get_dict(dimensions, Json.debug, _)
    )).

test(web_concepts_endpoint, [setup(bootstrap), cleanup(stop_server)]) :-
    once((
        register_concept(test_concept, and([actor-robot, action-finds]), [], manual),
        start_server(8098),
        setup_call_cleanup(
            http_open('http://127.0.0.1:8098/concepts', Stream, []),
            json_read_dict(Stream, Json),
            close(Stream)
        ),
        Json.concepts = [Concept],
        sub_string(Concept, _, _, _, "test_concept")
    )).

test(web_forget_observation, [setup(bootstrap), cleanup(stop_server)]) :-
    once((
        learn_observation([actor-robot, action-finds, object-father], Id),
        format(string(Body), '{"observation_id":"~w"}', [Id]),
        start_server(8099),
        setup_call_cleanup(
            http_open('http://127.0.0.1:8099/forget', Stream, [
                method(post),
                post(string(Body)),
                request_header('Content-Type'='application/json')
            ]),
            json_read_dict(Stream, Json),
            close(Stream)
        ),
        atom_string(Id, IdString),
        Json.forgotten == IdString,
        memory_snapshot(Snapshot),
        Snapshot.counts.observations =:= 0
    )).

test(web_forget_concept, [setup(bootstrap), cleanup(stop_server)]) :-
    once((
        register_concept(test_concept, and([actor-robot, action-finds]), [], manual),
        start_server(8100),
        setup_call_cleanup(
            http_open('http://127.0.0.1:8100/forget', Stream, [
                method(post),
                post(string('{"concept":"test_concept"}')),
                request_header('Content-Type'='application/json')
            ]),
            json_read_dict(Stream, Json),
            close(Stream)
        ),
        Json.forgotten == "test_concept",
        list_concepts([])
    )).

test(web_reset_endpoint, [setup(bootstrap), cleanup(stop_server)]) :-
    once((
        learn_observation([actor-robot, action-finds, object-father], _),
        chat("robot finds father", _, _),
        start_server(8101),
        setup_call_cleanup(
            http_open('http://127.0.0.1:8101/reset', Stream, [
                method(post),
                post(string('{}')),
                request_header('Content-Type'='application/json')
            ]),
            json_read_dict(Stream, Json),
            close(Stream)
        ),
        Json.status == "reset",
        memory_snapshot(Snapshot),
        Snapshot.counts.observations =:= 0,
        Snapshot.context == []
    )).

:- end_tests(web_api).
