#!/usr/bin/perl6

use v6;

need Entity::Entity;
need Module::ChatLink::ChatLinkRepository;

class ChatLinkService
{
    method insert (Cool $originChatId, Cool $targetChatId)
    {
        my $chatLinkRepository = ChatLinkRepository.new;

        return $chatLinkRepository.insert(
            %(
                'chat_link_origin_chat_id'    => $originChatId,
                'chat_link_target_chat_id'    => $targetChatId
            )
        );
    }

    method getOneByOrigin (Cool $chatId)
    {
        my $chatLinkRepository = ChatLinkRepository.new;

        $chatLinkRepository.select();

        $chatLinkRepository.where('chat_link_origin_chat_id', $chatId);

        return $chatLinkRepository.getFirst();
    }
}
