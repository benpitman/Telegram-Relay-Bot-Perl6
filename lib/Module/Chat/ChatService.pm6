#!/usr/bin/perl6

use v6;

need Module::Chat::ChatRepository;

class ChatService
{
    method insert ($chatId, $chatTitle, $chatType)
    {
        my $chatRepository = ChatRepository.new;
        $chatRepository.insert(
            %(
                chat_id     => $chatId,
                chat_title  => $chatTitle,
                chat_type   => $chatType
            )
        );
    }
}
