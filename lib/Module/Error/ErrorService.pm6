#!/usr/bin/perl6

use v6;

need Module::Error::ErrorRepository;

class ErrorService
{
    method insert (@errors)
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

        #FIXME mutliple inserts broken
        return $errorRepository.insert(@errorBatch);
    }
}
