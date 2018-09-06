#!/usr/bin/perl6

use v6;

need Entity::Entity;
need Module::Chat::ChatRepository;

class ChatService
{
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

    method getOneById ($Id)
    {
        my $chatRepository = ChatRepository.new;

        $chatRepository.select();

        $chatRepository.where('ID', $Id);

        return $chatRepository.getFirst();
    }

    method getOneByChatId ($chatId)
    {
        my $chatRepository = ChatRepository.new;

        $chatRepository.select();

        $chatRepository.where('chat_id', $chatId);

        return $chatRepository.getFirst();
    }

    method getTitle ($Id)
    {
        my Entity $entity = self.getOneById($Id);

        return $entity if $entity.hasErrors();

        my %chat = $entity.getData();
        my $title = %chat<chat_title> // '';

        $entity.setData($title);
        return $entity;
    }
}
