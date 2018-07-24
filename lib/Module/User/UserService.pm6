#!/usr/bin/perl6

use v6;

need Entity::Entity;
need Module::User::UserRepository;

class UserService
{
    has $!entity = Entity.new;

    method insert ($userId, $isBot, $forename, $surname, $username)
    {
        my $userRepository = UserRepository.new;

        return $userRepository.insert(
            %(
                user_id         => $userId,
                user_bot        => +$isBot,
                user_forename   => $forename,
                user_surname    => $surname,
                user_username   => $username
            )
        );
    }

    method getOneByUserId ($userId)
    {
        my $userRepository = UserRepository.new;
        $userRepository.select();
        $userRepository.where('user_id', $userId);
        my Entity $userEntity = $userRepository.getFirst();

        if $userEntity.hasErrors() {
            $!entity.addError($userEntity.getErrors());
            return $!entity;
        }

        $!entity.setData($userEntity.getData());
        return $!entity;
    }
}
