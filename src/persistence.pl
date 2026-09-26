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
    ->  setup_call_cleanup(
            open(Path, read, Stream),
            read_terms(Stream, Terms),
            close(Stream)
        ),
        maplist(memory:valid_memory_term, Terms),
        findall(Current, memory_term(Current), CurrentTerms),
        catch(
            ( reset_memory,
              maplist(import_memory_term, Terms)
            ),
            Error,
            ( reset_memory,
              maplist(import_memory_term, CurrentTerms),
              throw(Error)
            )
        )
    ;   throw(error(existence_error(source_sink, Path), load_memory/1))
    ).

read_terms(Stream, Terms) :-
    read_terms(Stream, [], Terms).

read_terms(Stream, Acc, Terms) :-
    read_term(Stream, Term, []),
    (   Term == end_of_file
    ->  reverse(Acc, Terms)
    ;   read_terms(Stream, [Term|Acc], Terms)
    ).
