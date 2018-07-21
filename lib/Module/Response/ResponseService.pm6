#!/usr/bin/perl6

use v6;

need Entity::Entity;
need Module::Response::ResponseRepository;

class ResponseService
{
    method insert (Str $response)
    {
        my $responseRepository = ResponseRepository.new;
        my Entity $responseEntity = $responseRepository.insert(
            %(
                response_raw    => $response,
                response_date   => DateTime.now
            )
        );

        return $responseEntity;
    }
}
