:- module(concepts,
    [ maybe_compress_observation/2,
      register_concept/4,
      expand_concept/2,
      concept_candidates/1
    ]).

:- use_module(library(lists)).
:- use_module(and).
:- use_module(dimensions).
:- use_module(memory).

maybe_compress_observation(Observation0, Name) :-
    observation_pairs(Observation0, Pairs),
    list_observations(Observations),
    findall(Id,
        member(observation(Id, Pairs, _), Observations),
        EvidenceIds),
    length(EvidenceIds, Count),
    Count >= 3,
    concept_candidates(Existing),
    (   member(concept(Name, and(Pairs), _, _), Existing)
    ->  true
    ;   next_id(concept, Name),
        remember_concept(Name, and(Pairs), EvidenceIds, auto)
    ).

register_concept(Name, Structure0, EvidenceIds, Meta) :-
    normalize_structure(Structure0, Structure),
    remember_concept(Name, Structure, EvidenceIds, Meta).

expand_concept(concept(Name), Expanded) :-
    !,
    list_concepts(Concepts),
    member(concept(Name, Structure, _, _), Concepts),
    expand_concept(Structure, Expanded).
expand_concept(and(Components0), and(Components)) :-
    !,
    maplist(expand_concept, Components0, Components).
expand_concept(and(Left, Right), Expanded) :-
    !,
    normalize_and(and(Left, Right), and(Components0)),
    maplist(expand_concept, Components0, Components),
    Expanded = and(Components).
expand_concept(Value, Value).

concept_candidates(Concepts) :-
    list_concepts(Concepts).

normalize_structure(Structure0, Structure) :-
    (   Structure0 = and(_)
    ;   Structure0 = and(_, _)
    ),
    !,
    normalize_and(Structure0, Structure).
normalize_structure(Structure, Structure).
