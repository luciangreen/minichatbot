:- begin_tests(memory).

:- use_module('/home/runner/work/minichatbot/minichatbot/src/chatbot.pl').
:- use_module('/home/runner/work/minichatbot/minichatbot/src/memory.pl').


test(persists_and_reloads_memory, [setup(bootstrap), cleanup(delete_file('/tmp/minichatbot-memory.pl'))]) :-
    learn_observation([actor-robot, action-remembers, object-father], _),
    save_memory('/tmp/minichatbot-memory.pl'),
    bootstrap,
    load_memory('/tmp/minichatbot-memory.pl'),
    memory_snapshot(Snapshot),
    Snapshot.counts.observations =:= 1.

:- end_tests(memory).
