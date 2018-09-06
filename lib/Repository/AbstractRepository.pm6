#!/usr/bin/perl6

use v6;
use DBIish;

need Service::Service;
need Entity::Entity;

role AbstractRepository
{
    has $.table is rw;
    has $!dbc;
    has Str $!dbs;
    has $!dbe;
    has $!entity = Entity.new;
    has Str $!whereString;

    submethod BUILD (:$!table)
    {
        my %config = Service.new.getConfig();
        my Str $database = %config<database>.gist;

        $!dbc = DBIish.connect(
            'SQLite',
            database => $database
        ) // die "Database '$database' not found.";
    }

    multi method insert (@rows where { @rows.first.WHAT === any(Pair, Hash) })
    {
        my @ids;

        for @rows -> %row {
            self.insert(%row);

            last if $!entity.hasErrors();

            @ids.push: $!entity.getData()[0];
        }

        $!entity.setData(@ids);
        $!dbc.dispose();
        return $!entity;
    }

    multi method insert (%row)
    {
        my @cols;
        my @vals;

        for %row.kv -> $col, $val {
            next if !$val.defined;
            @cols.push: "'$col'";

            given $val {
                when Int {
                    @vals.push: $val;
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
            $!dbe.finish();

            CATCH {
                $!entity.addError("$_");
                $!dbc.dispose();
                return $!entity;
            }
        }

        # Get last ID
        my $dbs = $!dbc.prepare("SELECT last_insert_rowid()");
        $dbs.execute();
        $!entity.setData($dbs.row());

        $dbs.finish();
        $!dbc.dispose();

        return $!entity;
    }

    multi method insert (@columns, @values where { @columns.elems === @values.elems })
    {
        my %row = @columns Z=> @values;
        return self.insert(%row);
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

    multi method select ()
    {
        self.select(['*']);
    }

    multi method where (@whereCols, @operators, @matches where { @whereCols.elems === @matches.elems })
    {
        my Int $index = 0;
        my Str $operator;
        $!whereString ~= '(';

        for @whereCols Z @matches -> [$col, $match] {
            $!whereString ~= " AND " if $index = $++;

            $operator = @operators[$index] // '=';
            $!whereString ~= "$col $operator ";

            given $match {
                when Int    { $!whereString ~= "$match"; }
                default     { $!whereString ~= "'$match'"; }
            }
        }
        $!whereString ~= ')';
    }

    multi method where (%matches)
    {
        my @keys = %matches.keys;
        my @vals = %matches.values;
        self.where(@keys, [], @vals);
    }

    multi method where (@matches where { @matches.first.WHAT === any(Pair, Hash) })
    {
        for @matches -> %matches {
            $!whereString ~= " OR " if $++;
            self.where(%matches);
        }
    }

    multi method where (@whereCols, @matches where { @whereCols.elems === @matches.elems })
    {
        self.where(@whereCols, [], @matches);
    }

    multi method where ($whereCol, $operator, $match)
    {
        self.where([$whereCol], [$operator], [$match]);
    }

    multi method where ($whereCol, $match)
    {
        self.where([$whereCol], [], [$match]);
    }

    multi method orWhere (|sig)
    {
        $!whereString ~= ' OR ';
        self.where(|sig);
    }

    method get ()
    {
        $!dbs ~= qq:to/STATEMENT/ if ?$!whereString;
            WHERE $!whereString
        STATEMENT

        try {
            $!dbe = $!dbc.prepare($!dbs);
            $!dbe.execute();

            CATCH {
                $!entity.addError("$_");
            }
        }
    }

    method getAll ()
    {
        self.get();

        if $!entity.hasErrors() {
            $!dbc.dispose();
            return $!entity;
        }

        $!entity.setData($!dbe.allrows(:array-of-hash));
        $!dbe.finish();
        $!dbc.dispose();

        return $!entity;
    }

    method getFirst ()
    {
        self.get();

        if $!entity.hasErrors() {
            $!dbc.dispose();
            return $!entity;
        }

        $!entity.setData($!dbe.row(:hash));
        $!dbe.finish();
        $!dbc.dispose();

        return $!entity;
    }
}
