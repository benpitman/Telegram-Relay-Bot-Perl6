#!/usr/bin/perl6

use v6;

need Entity::Entity;
need Module::Message::MessageEntity;
need Module::Message::MessageRepository;

class MessageService
{
    has $!entity = MessageEntity.new;

    method insert ()
    {
        my $messageRepository = MessageRepository.new;
        my Entity $messageEntity = $messageRepository.insertNew();

        if $messageEntity.hasErrors() {
            $!entity.addError($messageEntity.getErrors());
            return $!entity;
        }
    }
}
