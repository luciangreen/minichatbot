:- module(persistence,
    [ save_memory/1,
      load_memory/1
    ]).

:- use_module(memory).

save_memory(Path) :-
    setup_call_cleanup(
        open(Path, write, Stream),
        forall(memory_term(Term),
            write_term(Stream, Term, [fullstop(true), nl(true)])),
        close(Stream)
    ).

load_memory(Path) :-
    (   exists_file(Path)
    ->  reset_memory,
        setup_call_cleanup(
            open(Path, read, Stream),
            load_terms(Stream),
            close(Stream)
        )
    ;   throw(error(existence_error(source_sink, Path), load_memory/1))
    ).

load_terms(Stream) :-
    repeat,
        read_term(Stream, Term, []),
        (   Term == end_of_file
        ->  !
        ;   import_memory_term(Term),
            fail
        ).
