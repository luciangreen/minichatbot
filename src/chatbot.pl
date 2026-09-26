:- module(chatbot,
    [ bootstrap/0,
      chat/3,
      chat/4,
      learn/4,
      learn_observation/2,
      learn_correction/4,
      predict_known_dimensions/2,
      explain_prediction/3,
      save_memory/1,
      load_memory/1,
      start_server/1,
      stop_server/0,
      reset_memory/0,
      reset_dialogue/0,
      kernel_measurement/1
    ]).

:- use_module(and).
:- use_module(dimensions).
:- use_module(memory).
:- use_module(learner).
:- use_module(prediction).
:- use_module(explanation).
:- use_module(persistence).
:- use_module(dialogue).
:- use_module(web).

bootstrap :-
    reset_memory,
    reset_dialogue.

kernel_measurement(measurement{
    kernel_predicates:PredicateCount,
    kernel_clauses:ClauseCount,
    prolog_lines:LineCount,
    initial_facts:0,
    initial_domain_rules:0,
    learned_facts:ObservationCount,
    learned_concepts:ConceptCount
}) :-
    kernel_modules(Modules),
    kernel_predicate_count(Modules, PredicateCount),
    kernel_clause_count(Modules, ClauseCount),
    source_line_count(LineCount),
    memory_snapshot(Snapshot),
    ObservationCount = Snapshot.counts.observations,
    ConceptCount = Snapshot.counts.concepts.

kernel_modules([and, dimensions, memory, learner, prediction, concepts, generalise, similarity, explanation, dialogue, persistence, web, chatbot]).

kernel_predicate_count(Modules, Count) :-
    findall(Module:Name/Arity,
        ( member(Module, Modules),
          current_predicate(Module:Head),
          predicate_property(Module:Head, file(_)),
          \+ predicate_property(Module:Head, imported_from(_)),
          functor(Head, Name, Arity)
        ),
        Predicates0),
    sort(Predicates0, Predicates),
    length(Predicates, Count).

kernel_clause_count(Modules, Count) :-
    findall(1,
        ( member(Module, Modules),
          current_predicate(Module:Head),
          predicate_property(Module:Head, file(_)),
          \+ predicate_property(Module:Head, imported_from(_)),
          clause(Module:Head, _)
        ),
        Clauses),
    length(Clauses, Count).

source_line_count(LineCount) :-
    source_files(Files),
    maplist(file_line_count, Files, Counts),
    sum_list(Counts, LineCount).

source_files(Files) :-
    source_file(chatbot:bootstrap, ThisFile),
    file_directory_name(ThisFile, Dir),
    directory_files(Dir, Entries),
    include(prolog_file, Entries, PrologEntries),
    findall(Path,
        ( member(Entry, PrologEntries),
          directory_file_path(Dir, Entry, Path)
        ),
        Files).

prolog_file(Name) :-
    file_name_extension(_, pl, Name).

file_line_count(Path, Count) :-
    setup_call_cleanup(
        open(Path, read, Stream),
        count_lines(Stream, 0, Count),
        close(Stream)
    ).

count_lines(Stream, Acc, Count) :-
    read_line_to_string(Stream, Line),
    (   Line == end_of_file
    ->  Count = Acc
    ;   Acc1 is Acc + 1,
        count_lines(Stream, Acc1, Count)
    ).
