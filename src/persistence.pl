:- module(persistence,
    [ save_memory/1,
      load_memory/1
    ]).

:- use_module(memory).

save_memory(Path) :-
    open(Path, write, Stream),
    forall(memory_term(Term),
        write_term(Stream, Term, [fullstop(true), nl(true)])),
    close(Stream).

load_memory(Path) :-
    reset_memory,
    (   exists_file(Path)
    ->  open(Path, read, Stream),
        repeat,
            read_term(Stream, Term, []),
            (   Term == end_of_file
            ->  close(Stream), !
            ;   import_memory_term(Term),
                fail
            )
    ;   true
    ).
