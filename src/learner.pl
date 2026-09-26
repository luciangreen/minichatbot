:- module(learner,
    [ learn/4,
      learn_observation/2,
      learn_correction/4
    ]).

:- use_module(library(lists)).
:- use_module(dimensions).
:- use_module(memory).
:- use_module(concepts).

learn(Input0, Context0, Output0, learned{observation:ObservationId, associations:AssociationIds}) :-
    observation_pairs(Input0, Input),
    observation_pairs(Context0, Context),
    observation_pairs(Output0, Output),
    append(Input, Context, Known0),
    sort(Known0, Known),
    append(Known, Output, FullObservation),
    remember_observation(FullObservation, interaction(Input, Context, Output), ObservationId),
    findall(AssociationId,
        ( member(Key-Value, Output),
          remember_association(Known, Key, Value, ObservationId, AssociationId)
        ),
        AssociationIds),
    (maybe_compress_observation(FullObservation, _) -> true ; true),
    !.

learn_observation(Observation0, ObservationId) :-
    observation_pairs(Observation0, Observation),
    remember_observation(Observation, observed, ObservationId),
    (maybe_compress_observation(Observation, _) -> true ; true),
    !.

learn_correction(Known0, Rejected, Corrected, CorrectionId) :-
    observation_pairs(Known0, Known),
    remember_correction(Known, Rejected, Corrected, corrected, CorrectionId),
    (   Rejected = Key-Value
    ->  revise_association(Known, Key, Value, -3)
    ;   true
    ),
    (   Corrected = Key-Value2
    ->  remember_association(Known, Key, Value2, CorrectionId, _)
    ;   true
    ).
