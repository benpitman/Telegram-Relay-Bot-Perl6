#!/usr/bin/perl6

use v6;

need Module::Request::RequestRepository;

class RequestService
{
    method insert (Str $requestText, Str $requestType, Cool $chatId, Cool $userId)
    {
        my $requestRepository = RequestRepository.new;

        return $requestRepository.insert(
            %(
                request_chat_id     => $chatId,
                request_user_id     => $userId,
                request_response_id => 'NULL',
                request_text        => $requestText,
                request_type        => $requestType,
                request_is_pending  => 1,
                request_date        => DateTime.now()
            )
        );
    }

    method getPendingByIds (Cool $chatId, Cool $userId)
    {
        my $requestRepository = RequestRepository.new;

        $requestRepository.select();

        $requestRepository.where(
            ['request_chat_id', 'request_user_id', 'request_is_pending'],
            [$chatId, $userId, 1]
        );

        return $requestRepository.getFirst();
    }
}
