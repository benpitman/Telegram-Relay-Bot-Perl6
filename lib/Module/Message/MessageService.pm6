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

    method get ()
    {
        #TODO Perl seems to automatically flatten multidimensional arrays.
        
        my $messageRepository = MessageRepository.new;
        $messageRepository.select(['id', 'date']);
        # $messageRepository.where([%(id => 19, name => 'newtest'),%(id => 21)]);
        $messageRepository.where([['id', '=', 19], ['name', '=', 'newtest']], [['id', '=', 21]]);
        # $messageRepository.where({id => 19, name => 'newtest'});
        $messageRepository.get();
        say $messageRepository.all();
        exit;
        my Entity $messageEntity = $messageRepository.all();
        $messageEntity.dispatch();
    }
}
