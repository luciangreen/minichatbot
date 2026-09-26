:- begin_tests(memory).

:- use_module('../src/chatbot.pl').
:- use_module('../src/memory.pl').
:- use_module(library(filesex)).

test(persists_and_reloads_memory, [setup(bootstrap)]) :-
    tmp_file_stream(text, Path, Stream),
    close(Stream),
    call_cleanup(
        ( learn_observation([actor-robot, action-remembers, object-father], _),
          save_memory(Path),
          bootstrap,
          load_memory(Path),
          memory_snapshot(Snapshot),
          Snapshot.counts.observations =:= 1
        ),
        delete_file(Path)
    ).

:- end_tests(memory).
