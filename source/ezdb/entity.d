/**
Contains several attributes used in SQL databases.
*/
module ezdb.entity;

import std.traits;
import std.typecons;

/**
Defines the primary key of an entity.
*/
enum primaryKey; // @suppress(dscanner.style.phobos_naming_convention)

/**
Aliases to the type of the primary key of an entity.
*/
template PrimaryKeyType(Type)
{
    alias PrimaryKeyType = typeof(PrimaryKeySymbol!Type);
}

/**
The `PrimaryKeyType` template returns the type of the primary key.
*/
@("PrimaryKeyType returns correct primary key type")
@safe @nogc pure unittest
{
    static struct MyEntity
    {
        @primaryKey
        int a;

        int b;
    }

    assert(is(PrimaryKeyType!MyEntity == int));
}

/**
Aliases to the symbol that is the primary key of an entity.
*/
template PrimaryKeySymbol(Type)
{
    static if (getSymbolsByUDA!(Type, primaryKey).length == 1)
    {
        alias PrimaryKeySymbol = getSymbolsByUDA!(Type, primaryKey)[0];
    }
    else
    {
        static assert(false, "An entity should have exactly one @primaryKey");
    }
}

@("Cannot compile PrimaryKey with two primary keys")
@safe @nogc pure unittest
{
    static struct MyEntity
    {
        @primaryKey
        int id;

        @primaryKey
        int secondId;
    }

    assert(!__traits(compiles, PrimaryKeySymbol!MyEntity));
}

@("Cannot compile PrimaryKey with no primary keys")
@safe @nogc pure unittest
{
    static struct MyEntity
    {
    }

    assert(!__traits(compiles, PrimaryKeySymbol!MyEntity));
}

/**
Gets a reference to the primary key of an entity.
*/
ref auto getPrimaryKey(Entity)(Entity entity) // @suppress(dscanner.suspicious.unused_parameter)
{
    return __traits(getMember, entity, getSymbolsByUDA!(typeof(entity), primaryKey)[0].stringof);
}
