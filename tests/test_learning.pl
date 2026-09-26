:- begin_tests(learning).

:- use_module('/home/runner/work/minichatbot/minichatbot/src/chatbot.pl').
:- use_module('/home/runner/work/minichatbot/minichatbot/src/memory.pl').


test(stores_observations, [setup(bootstrap)]) :-
    learn_observation([actor-robot, action-finds, object-father], _),
    memory_snapshot(Snapshot),
    Snapshot.counts.observations =:= 1.

test(learns_associations, [setup(bootstrap)]) :-
    learn([action-create, domain-music], [], [object-song], Learned),
    Learned.associations \= [],
    memory_snapshot(Snapshot),
    Snapshot.counts.associations =:= 1.

:- end_tests(learning).
