:- module(similarity,
    [ similarity/3
    ]).

:- use_module(library(lists)).
:- use_module(dimensions).
:- use_module(and).

similarity(Left0, Right0, Score) :-
    to_components(Left0, Left),
    to_components(Right0, Right),
    intersection(Left, Right, Shared),
    union(Left, Right, Universe),
    length(Shared, SharedCount),
    length(Universe, UniverseCount),
    (   UniverseCount =:= 0
    ->  Score = 0.0
    ;   Score is SharedCount / UniverseCount
    ).

to_components(Term, Components) :-
    (   Term = and(_)
    ;   Term = and(_, _)
    ),
    !,
    and_components(Term, Components0),
    sort(Components0, Components).
to_components(Term, Components) :-
    catch(observation_pairs(Term, Pairs), _, fail),
    !,
    sort(Pairs, Components).
to_components(List, Components) :-
    is_list(List),
    !,
    sort(List, Components).
to_components(Value, [Value]).
