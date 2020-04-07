/**
Contains definitions and helper functions for foreign keys.
*/
module ezdb.foreign;

import ezdb.entity;
import std.traits;
import std.stdio;
version(unittest) import fluent.asserts;

/**
A UDA that will cause the property it is added to, to become a foreign key
contraint to said

 that can be embedded in an entity which refers to another entity.
This type will automatically add a Foreign key constraint.
*/
struct foreign(Entity) // @suppress(dscanner.style.phobos_naming_convention)
{
    /// The target entity.
    Entity target_entity;
}

/**
`true` if the symbol is a foreign key, `false` if it isn't.
*/
template IsForeign(alias symbol)
{
    alias IsForeign = hasUDA!(symbol, foreign);
}

@("IsForeign is true for foreign UDA")
unittest
{
    static struct Entity
    {
        @primaryKey int id;

        @foreign!Entity
        int entity;
    }
    IsForeign!(Entity.entity).should.equal(true)
        .because("Foreign is annotated with foreign");
}

@("IsForeign is false for something without foreign UDA")
unittest
{
    static struct Entity
    {
        @primaryKey int id;

        @foreign!Entity
        int entity;
    }
    IsForeign!(Entity.id).should.equal(false)
        .because("Foreign is annotated with foreign");
}

/**
Gets the type of entity the foreign key points to.
*/
template GetForeignEntity(alias symbol)
{
    alias GetForeignEntity = GetForeignEntityOfUDA!(getUDAs!(symbol, foreign));
}

private template GetForeignEntityOfUDA(alias foreignAttribute)
{
    alias GetForeignEntityOfUDA = typeof(foreignAttribute.target_entity);
}

@("GetForeignEntity gets the foreign entity")
unittest
{
    static struct Parent {}

    static struct Entity
    {
        @primaryKey int id;

        @foreign!Parent
        int entity;
    }
    assert(is(GetForeignEntity!(Entity.entity) == Parent));
}
