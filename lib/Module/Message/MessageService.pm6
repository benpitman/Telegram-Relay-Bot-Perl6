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
        =begin testing
            my $messageRepository = MessageRepository.new;
            # $messageRepository.insert(['name', 'date'], ['hello', DateTime.now]);
            $messageRepository.select(['id', 'date']);
            # $messageRepository.where([a => 1]);
            # $messageRepository.where([%(id => 19, name => 'newtest'),%(id => 21)]);
            # $messageRepository.where([['id', '=', 19], ['name', '=', 'newtest']]);
            # $messageRepository.orWhere([a => 1]);
            # $messageRepository.orWhere(['a', 'b'], ['>'], [1, 2]);
            # $messageRepository.orWhere(['a', 'b'], [1, 2]);
            # $messageRepository.orWhere(['a'], [1]);
            # $messageRepository.orWhere([{columnA => 1, columnB => 2}, {columnC => 3}]);
            # $messageRepository.where([['id', '=', 21]]);
            # $messageRepository.where({id => 19, name => 'newtest'});
            # $messageRepository.where({id => 19});
            my Entity $messageEntity = $messageRepository.get();
            say $messageRepository.all();
            exit;
            $messageEntity.dispatch();
        =end testing
    }
}
