#!/usr/bin/perl6

use v6;
use DBIish;

need Service::Service;
need Entity::Entity;

role AbstractRepository
{
    has $.table is rw;
    has $!dbc;
    has $!dbs = '';
    has $!dbe;
    has $!entity = Entity.new;

    submethod BUILD (:$!table)
    {
        my %config = Service.getConfig();
        my Str $database = %config<database>.gist;

        $!dbc = DBIish.connect(
            'SQLite',
            database => $database
        ) // die "Database '$database' not found.";
    }

    submethod END ()
    {
        $!dbs.finish();
        $!dbc.dispose();
    }

    multi method insert (@rows where { @rows.first.WHAT === any(Pair, Hash) })
    {
        my Array @ids;
        my Array @id;

        for @rows -> %row {
            @id = self.insert(%row);

            last if $!entity.hasErrors();
            @ids.push: @id[0];
        }

        return @ids;
    }

    multi method insert (%row)
    {
        my Array @cols;
        my Array @vals;

        for %row.kv -> $col, $val {
            @cols.push: $col;

            given $val.^name {
                when Int {
                    @vals.push: "$val";
                }
                default {
                    @vals.push: "'$val'";
                }
            }
        }

        my Str $colString = @cols.join(', ');
        my Str $valString = @vals.join(', ');

        $!dbs = qq:to/STATEMENT/;
            INSERT INTO $!table ($colString)
            VALUES ($valString)
        STATEMENT

        try {
            $!dbe = $!dbc.prepare($!dbs);
            $!dbe.execute();

            CATCH {
                $!entity.addError("$_");
                return;
            }
        }

        # Get last ID
        my $dbs = $!dbc.prepare("SELECT last_insert_rowid()");
        $dbs.execute();
        my @lastId = $dbs.row();

        $dbs.finish();

        return @lastId;
    }

    multi method select (*@cols where { $_.all ~~ Str })
    {
        my Str $colString = @cols.join(', ');

        $!dbs = qq:to/STATEMENT/;
        	SELECT $colString
        	FROM $!table
        STATEMENT
    }

    multi method select (@cols)
    {
        self.select(|@cols);
    }

    multi method where (%matches)
    {
        my Str $whereString = '(';

        for %matches.kv -> $col, $match {
            $whereString ~= " AND " if $++;
            $whereString ~= "$col = ";

            given $match {
                when Int    { $whereString ~= "$match"; }
                default     { $whereString ~= "'$match'"; }
            }
        }
        $whereString ~= ')';

        $!dbs ~= qq:to/STATEMENT/;
        	WHERE $whereString
        STATEMENT
    }

    multi method where (@matches where { @matches.first.WHAT === any(Pair, Hash) })
    {
        my Str $whereString = '';

        for @matches -> %matches {
            $whereString ~= " OR " if $++;
            $whereString ~= '(';

            for %matches.kv -> $col, $match {
                $whereString ~= " AND " if $++;
                $whereString ~= "$col = ";

                given $match {
                    when Int    { $whereString ~= "$match"; }
                    default     { $whereString ~= "'$match'"; }
                }
            }
            $whereString ~= ')';
        }

        $!dbs ~= qq:to/STATEMENT/;
        	WHERE $whereString
        STATEMENT
    }

    multi method where (@whereCols, @operators, @matches where { @whereCols.elems === @matches.elems })
    {
        my Str $whereString = '(';
        my Int $index = 0;
        my Str $operator;

        for @whereCols Z @matches -> [$col, $match] {
            $whereString ~= " AND " if $index++;

            $operator = @operators[$index] // '=';
            $whereString ~= "$col $operator ";

            given $match {
                when Int    { $whereString ~= "$match"; }
                default     { $whereString ~= "'$match'"; }
            }
        }
        $whereString ~= ')';

        $!dbs ~= qq:to/STATEMENT/;
            WHERE $whereString
        STATEMENT
    }

    multi method where (@whereCols, @matches where { @whereCols.elems === @matches.elems })
    {
        self.where(@whereCols, [], @matches)
    }

    multi method where ($whereCol, $operator, $match)
    {
        self.where([$whereCol], [$operator], [$match])
    }

    method get ()
    {
        say $!dbs;
        exit;

        try {
            $!dbe = $!dbc.prepare($!dbs);
            $!dbe.execute();

            CATCH {
                $!entity.addError("$_");
                return;
            }
        }
    }

    method all ()
    {
        return $!dbe.allrows().Array;
    }

    method first ()
    {
        return $!dbe.row();
    }
}
