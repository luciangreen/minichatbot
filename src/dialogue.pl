:- module(dialogue,
    [ chat/3,
      chat/4,
      reset_dialogue/0
    ]).

:- use_module(library(lists)).
:- use_module(dimensions).
:- use_module(learner).
:- use_module(memory).
:- use_module(prediction).
:- use_module(explanation).

chat(Input, Response, Debug) :-
    chat(Input, Response, Debug, _).

chat(Input, Response, Debug, EventId) :-
    infer_dimensions(Input, Observation0),
    discourse_entities(Entities),
    resolve_pronouns(Observation0, Entities, Observation),
    observation_pairs(Observation, Pairs),
    (   correction_input(Pairs, CorrectionPairs)
    ->  handle_correction(CorrectionPairs, Response, Debug, EventId)
    ;   memberchk(query-object, Pairs)
    ->  answer_from_context(Pairs, Response, Debug, EventId)
    ;   partial_observation(Pairs)
    ->  predict_response(Pairs, Response, Debug, EventId)
    ;   remember_context(Pairs, user, EventId),
        update_discourse(Pairs),
        learn_observation(Pairs, _),
        Response = "learned",
        Debug = debug{dimensions:Pairs, prediction:none, explanation:none}
    ).

reset_dialogue :-
    clear_state(last_prediction),
    clear_state(last_input),
    clear_state(last_response),
    clear_state(last_reference),
    clear_state(last_subject),
    clear_state(last_target).

correction_input(Pairs, Corrected) :-
    memberchk(token(1)-no, Pairs),
    exclude(is_prefix_noise, Pairs, Corrected).

is_prefix_noise(token(1)-no).
is_prefix_noise(speech_act-statement).
is_prefix_noise(token_count-_).

answer_from_context(Pairs, Response, Debug, EventId) :-
    remember_context(Pairs, user_query, EventId),
    (   memberchk(actor-Actor, Pairs),
        memberchk(action-Action, Pairs),
        context_answer(Actor, Action, Object)
    ->  format(string(Response), "~w", [Object]),
        Debug = debug{dimensions:Pairs, prediction:Object, explanation:context}
    ;   predict_response_no_context(Pairs, Response, Debug)
    ).

context_answer(Actor, Action, Object) :-
    list_context(Context),
    reverse(Context, Reversed),
    member(context(_, ContextPairs, _), Reversed),
    memberchk(actor-Actor, ContextPairs),
    memberchk(action-Action, ContextPairs),
    memberchk(object-Object, ContextPairs),
    !.

partial_observation(Pairs) :-
    member(_-something, Pairs), !.
partial_observation(Pairs) :-
    member(_-unknown, Pairs), !.
partial_observation(Pairs) :-
    member(query-_, Pairs).

predict_response_no_context(Pairs, Response, Debug) :-
    exclude(query_marker, Pairs, PredictionPairs),
    predict_known_dimensions(PredictionPairs, Candidates),
    prediction_result(PredictionPairs, Candidates, Response, Debug).

query_marker(query-_).

predict_response(Pairs, Response, Debug, EventId) :-
    remember_context(Pairs, user_partial, EventId),
    update_discourse(Pairs),
    predict_known_dimensions(Pairs, Candidates),
    prediction_result(Pairs, Candidates, Response, Debug).

prediction_result(KnownPairs, Candidates, Response, Debug) :-
    (   best_candidate(Candidates, best(BestPair, Score, _Evidence))
    ->  explain_prediction(KnownPairs, BestPair, Explanation),
        remember_prediction(KnownPairs, Candidates, BestPair, Explanation, _PredictionId),
        set_state(last_prediction, prediction(KnownPairs, BestPair)),
        set_state(last_input, KnownPairs),
        format(string(Response), "I predict ~w (~2f)", [BestPair, Score]),
        Debug = debug{dimensions:KnownPairs, prediction:BestPair, explanation:Explanation}
    ;   Response = "I do not know yet.",
        Debug = debug{dimensions:KnownPairs, prediction:none, explanation:none}
    ).

handle_correction(CorrectedPairs, Response, Debug, EventId) :-
    remember_context(CorrectedPairs, correction, EventId),
    (   get_state(last_prediction, prediction(Known, Rejected)),
        corrected_pair(CorrectedPairs, Corrected)
    ->  learn_correction(Known, Rejected, Corrected, _),
        learn_observation(CorrectedPairs, _),
        Response = "correction learned",
        Debug = debug{dimensions:CorrectedPairs, rejected:Rejected, corrected:Corrected}
    ;   Response = "I need a prior prediction before I can learn a correction.",
        Debug = debug{dimensions:CorrectedPairs, rejected:none, corrected:none}
    ).

corrected_pair(Pairs, Pair) :-
    member(Pair, Pairs),
    Pair = (_-_),
    Pair \= speech_act-_,
    Pair \= token_count-_,
    Pair \= token(_)-_.

discourse_entities(Entities) :-
    get_state(last_reference, Reference),
    get_state(last_subject, Subject),
    (get_state(last_target, Target) -> true ; Target = Subject),
    Entities = [subject-Subject, reference-Reference, target-Target],
    !.
discourse_entities(Entities) :-
    list_context(Context),
    reverse(Context, Reversed),
    findall(Entity,
        ( member(context(_, Pairs, _), Reversed),
          entity_in_pairs(Pairs, Entity)
        ),
        Entities0),
    list_to_set(Entities0, Entities).

update_discourse(Pairs) :-
    ( memberchk(actor-Actor, Pairs) -> set_state(last_subject, Actor) ; true ),
    ( memberchk(target-Target, Pairs) -> set_state(last_target, Target) ; memberchk(actor-Actor, Pairs) -> set_state(last_target, Actor) ; true ),
    ( memberchk(target-_, Pairs) -> discourse_focus(Pairs, Focus)
    ; memberchk(object-_, Pairs) -> discourse_focus(Pairs, Focus)
    ; memberchk(actor-_, Pairs) -> discourse_focus(Pairs, Focus)
    ; fail
    ),
    !,
    set_state(last_reference, Focus).
update_discourse(_).

discourse_focus(Pairs, Focus) :-
    ( memberchk(target-_, Pairs), memberchk(actor-Focus, Pairs) -> true
    ; memberchk(object-Focus, Pairs) -> true
    ; memberchk(actor-Focus, Pairs)
    ).

entity_in_pairs(Pairs, Entity) :-
    ( memberchk(actor-Entity, Pairs)
    ; memberchk(target-Entity, Pairs)
    ; memberchk(object-Entity, Pairs)
    ),
    atomic(Entity),
    \+ memberchk(Entity, [something, someone, unknown]).

