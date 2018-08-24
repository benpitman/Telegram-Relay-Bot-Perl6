#!/usr/bin/perl6

use v6;

need Entity::Entity;
need Module::MessageLink::MessageLinkRepository;

class MessageLinkService
{
    method insert ()
    {
        return;
    }

    method getTarget (Cool $messageId)
    {
        my $messageLinkRepository = MessageLinkRepository.new;

        $messageLinkRepository.select();

        $messageLinkRepository.where('message_link_origin_message_id', $messageId);

        return $messageLinkRepository.getFirst();
    }
}
