#!/usr/bin/perl6

use v6;

need Entity::Entity;
need Module::ChatLink::ChatLinkRepository;

class ChatLinkService
{
    method insert ()
    {
        return;
    }

    method getTarget (Cool $chatId)
    {
        my $chatLinkRepository = ChatLinkRepository.new;

        $chatLinkRepository.select();

        $chatLinkRepository.where('chat_link_origin_chat_id', $chatId);

        return $chatLinkRepository.getFirst();
    }
}
