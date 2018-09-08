#!/usr/bin/perl6

use v6;

need Module::Request::RequestRepository;

class RequestService
{
    method insert (Str $requestText, Str $requestType, Cool $chatId, Cool $userId)
    {
        my $requestEntity = self.getByRequestType($chatId, $userId, $requestType);

        return $requestEntity if $requestEntity.hasErrors();

        if $requestEntity.hasData() {
            $requestEntity = self.fulfilPending($chatId, $userId, $requestType);

            return $requestEntity if $requestEntity.hasErrors();
        }

        my $requestRepository = RequestRepository.new;

        return $requestRepository.insert(
            %(
                request_chat_id     => $chatId,
                request_user_id     => $userId,
                request_response_id => Nil,
                request_text        => $requestText,
                request_type        => $requestType,
                request_is_pending  => 1,
                request_date        => DateTime.now()
            )
        );
    }

    method getByRequestType (Cool $chatId, Cool $userId, Str $requestType)
    {
        my $requestRepository = RequestRepository.new;

        $requestRepository.select();

        $requestRepository.where(
            ['request_chat_id', 'request_user_id', 'request_type', 'request_is_pending'],
            [$chatId, $userId, $requestType, 1]
        );

        return $requestRepository.getFirst();
    }

    method fulfilPending (Cool $chatId, Cool $userId, $requestType)
    {
        my $requestRepository = RequestRepository.new;

        $requestRepository.set('request_is_pending', 0);

        $requestRepository.where(
            ['request_chat_id', 'request_user_id', 'request_type', 'request_is_pending'],
            [$chatId, $userId, $requestType, 1]
        );

        return $requestRepository.save();
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
