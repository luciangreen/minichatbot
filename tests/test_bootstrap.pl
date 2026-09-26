:- begin_tests(bootstrap).

:- use_module('/home/runner/work/minichatbot/minichatbot/src/chatbot.pl').
:- use_module('/home/runner/work/minichatbot/minichatbot/src/memory.pl').
:- use_module('/home/runner/work/minichatbot/minichatbot/src/concepts.pl').


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

:- end_tests(bootstrap).
