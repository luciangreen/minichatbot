:- begin_tests(bootstrap).

:- use_module('../src/chatbot.pl').
:- use_module('../src/memory.pl').
:- use_module('../src/concepts.pl').
:- use_module(library(http/http_open)).
:- use_module(library(http/http_client)).
:- use_module(library(http/json)).


test(starts_empty, [setup(bootstrap)]) :-
    memory_snapshot(Snapshot),
    Snapshot.counts.observations =:= 0,
    Snapshot.counts.associations =:= 0,
    Snapshot.counts.concepts =:= 0.

test(short_term_context_question_answering, [setup(bootstrap)]) :-
    chat("robot has father", _, _),
    chat("he taught it geometry", _, _),
    chat("what did he taught?", Response, Debug),
    Response = "geometry",
    Debug.prediction == geometry.

test(recursive_concepts_and_explanations, [setup(bootstrap)]) :-
    once((
        register_concept(teaching_relationship, and([actor-father, action-teaches, object-child]), [], manual),
        register_concept(family_teaching_memory, and([concept(teaching_relationship), object-geometry]), [], manual),
        expand_concept(concept(family_teaching_memory), and(Expanded)),
        member(and(TeachingComponents), Expanded),
        memberchk(action-teaches, TeachingComponents),
        memberchk(actor-father, TeachingComponents),
        memberchk(object-child, TeachingComponents),
        learn([action-create, domain-music], [], [object-song], _),
        predict_known_dimensions([action-create, domain-music], candidates([candidate(object-song, _, _)|_])),
        explain_prediction([action-create, domain-music], object-song, Explanation),
        Explanation.candidate == object-song
    )).

test(dialogue_partial_prediction_records_prediction, [setup(bootstrap)]) :-
    learn([action-create, mode-imperative], [], [object-song], _),
    chat("create something", Response, Debug),
    sub_string(Response, 0, _, _, "I predict"),
    Debug.prediction == object-song,
    memory:list_predictions([prediction(_, _, _, object-song, _)|_]).


test(web_predictions_empty_state, [setup(bootstrap), cleanup(stop_server)]) :-
    once((
        start_server(8096),
        setup_call_cleanup(
            http_open('http://127.0.0.1:8096/predictions', Stream, []),
            read_string(Stream, _, Body),
            close(Stream)
        ),
        sub_string(Body, _, _, _, "\"predictions\": []")
    )).

test(web_home_page_contains_chat_ui, [setup(bootstrap), cleanup(stop_server)]) :-
    once((
        start_server(8092),
        setup_call_cleanup(
            http_open('http://127.0.0.1:8092/', Stream, []),
            read_string(Stream, _, Body),
            close(Stream)
        ),
        sub_string(Body, _, _, _, "<title>minichatbot</title>"),
        sub_string(Body, _, _, _, "id=\"chat-form\""),
        sub_string(Body, _, _, _, "Conversation"),
        sub_string(Body, _, _, _, "fetch('/chat'")
    )).

test(web_memory_counts_endpoint, [setup(bootstrap), cleanup(stop_server)]) :-
    once((
        start_server(8091),
        setup_call_cleanup(
            http_open('http://127.0.0.1:8091/memory', Stream, []),
            json_read_dict(Stream, Json),
            close(Stream)
        ),
        Json.counts.observations =:= 0,
        Json.counts.predictions =:= 0,
        Json.counts.concepts =:= 0,
        Json.counts.corrections =:= 0,
        string(Json.memory)
    )).

test(web_predictions_endpoint, [setup(bootstrap), cleanup(stop_server)]) :-
    once((
        learn([action-create, mode-imperative], [], [object-song], _),
        start_server(8093),
        chat("create something", _, _),
        setup_call_cleanup(
            http_open('http://127.0.0.1:8093/predictions', Stream, []),
            json_read_dict(Stream, Json),
            close(Stream)
        ),
        Json.predictions = [Prediction|_],
        sub_string(Prediction, _, _, _, "object-song")
    )).

test(web_chat_missing_input_returns_400, [setup(bootstrap), cleanup(stop_server)]) :-
    once((
        start_server(8094),
        catch(
            http_open('http://127.0.0.1:8094/chat', Stream, [
                method(post),
                post(string('{}')),
                request_header('Content-Type'='application/json')
            ]),
            error(existence_error(url, _), context(_, status(400, _))),
            Stream = error_400
        ),
        Stream == error_400
    )).

test(web_forget_invalid_json_returns_400, [setup(bootstrap), cleanup(stop_server)]) :-
    once((
        start_server(8095),
        catch(
            http_open('http://127.0.0.1:8095/forget', Stream, [
                method(post),
                post(string('{')),
                request_header('Content-Type'='application/json')
            ]),
            error(existence_error(url, _), context(_, status(400, _))),
            Stream = error_400
        ),
        Stream == error_400
    )).

:- end_tests(bootstrap).
