:- module(generalise,
    [ generalise_observations/2
    ]).

:- use_module(library(lists)).
:- use_module(dimensions).

generalise_observations(Observations, observation(Generalised)) :-
    maplist(observation_pairs, Observations, PairLists),
    PairLists = [First|Rest],
    findall(Key-Value,
        ( member(Key-Value, First), forall(member(Pairs, Rest), memberchk(Key-Value, Pairs)) ),
        CommonPairs0),
    sort(CommonPairs0, CommonPairs),
    findall(Key-one_of(Values),
        varying_dimension(Key, PairLists, CommonPairs, Values),
        VariablePairs0),
    sort(VariablePairs0, VariablePairs),
    append(CommonPairs, VariablePairs, Generalised0),
    observation_from_pairs(Generalised0, observation(Generalised)).

varying_dimension(Key, PairLists, CommonPairs, Values) :-
    findall(Key0, (member(Pairs, PairLists), member(Key0-_, Pairs)), Keys0),
    sort(Keys0, Keys),
    member(Key, Keys),
    \+ memberchk(Key-_, CommonPairs),
    findall(Value,
        ( member(Pairs, PairLists), memberchk(Key-Value, Pairs) ),
        Values0),
    length(Values0, Count),
    length(PairLists, Count),
    sort(Values0, Values),
    Values = [_ , _ | _].
