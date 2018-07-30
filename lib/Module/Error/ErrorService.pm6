#!/usr/bin/perl6

use v6;

need Module::Error::ErrorRepository;

class ErrorService
{
    method insert (Array @errors)
    {
        my $errorRepository = ErrorRepository.new;
        my $now = DateTime.now;
        my @errorBatch;

        for @errors -> $error {
            @errorBatch.push: %(
                error_message   => $error,
                error_at        => $now
            );
        }

        return $errorRepository.insert(@errorBatch);
    }
}
