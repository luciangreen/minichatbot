:- initialization(main, main).

:- [ 'tests/test_and.pl',
      'tests/test_dimensions.pl',
      'tests/test_learning.pl',
      'tests/test_prediction.pl',
      'tests/test_generalisation.pl',
      'tests/test_memory.pl',
      'tests/test_corrections.pl',
      'tests/test_bootstrap.pl'
   ].

main :-
    run_tests,
    halt.
