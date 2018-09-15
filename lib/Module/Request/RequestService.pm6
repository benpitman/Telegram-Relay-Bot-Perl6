#!/usr/bin/perl6

use v6;

need Module::Request::RequestRepository;

class RequestService
{
    method insert (Cool $chatId, Cool $userId, Str $requestText, Str $requestType)
    {
        my $requestEntity = self.getByRequestType($userId, $requestType);

        return $requestEntity if $requestEntity.hasErrors();

        if $requestEntity.hasData() {
            $requestEntity = self.fulfilPending($userId, $requestType);

            return $requestEntity if $requestEntity.hasErrors();
        }

        my $requestRepository = RequestRepository.new;

        return $requestRepository.insert(
            %(
                request_chat_id     => $chatId,
                request_user_id     => $userId,
                request_text        => $requestText.trim,
                request_type        => $requestType,
                request_is_pending  => 1,
                request_date        => DateTime.now()
            )
        );
    }

    method getByRequestType (Cool $userId, Str $requestType)
    {
        my $requestRepository = RequestRepository.new;

        $requestRepository.select();

        $requestRepository.where(
            ['request_user_id', 'request_type', 'request_is_pending'],
            [$userId, $requestType, 1]
        );

        return $requestRepository.getFirst();
    }

    #TODO cancel latest pending

    method fulfilPending (Cool $userId, $requestType)
    {
        my $requestRepository = RequestRepository.new;

        $requestRepository.set('request_is_pending', 0);

        $requestRepository.where(
            ['request_user_id', 'request_type', 'request_is_pending'],
            [$userId, $requestType, 1]
        );

        return $requestRepository.save();
    }

    method getPendingByUserId (Cool $userId)
    {
        my $requestRepository = RequestRepository.new;

        $requestRepository.select();

        $requestRepository.where(
            ['request_user_id', 'request_is_pending'],
            [$userId, 1]
        );

        return $requestRepository.getFirst();
    }
}
