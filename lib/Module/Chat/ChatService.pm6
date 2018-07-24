#!/usr/bin/perl6

use v6;

need Entity::Entity;
need Module::Chat::ChatRepository;

class ChatService
{
    has $!entity = Entity.new;

    method insert ($chatId, $chatTitle, $chatType)
    {
        my $chatRepository = ChatRepository.new;

        return $chatRepository.insert(
            %(
                chat_id     => $chatId,
                chat_title  => $chatTitle,
                chat_type   => $chatType
            )
        );
    }

    method getOneByChatId ($chatId)
    {
        my $chatRepository = ChatRepository.new;
        $chatRepository.select();
        $chatRepository.where('chat_id', $chatId);
        my Entity $chatEntity = $chatRepository.getFirst();

        if $chatEntity.hasErrors() {
            $!entity.addError($chatEntity.getErrors());
            return $!entity;
        }

        $!entity.setData($chatEntity.getData());
        return $!entity;
    }
}
