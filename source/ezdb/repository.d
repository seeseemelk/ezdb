module ezdb.repository;

import ezdb.entity;

/**
A base interface describing the basic operations that can be performed on a
database.
*/
interface Repository(Entity)
{
    /**
    Closes the database.
    */
    void close();

    /**
    Saves the entity in the repository.
    This should be called to add a new entity or to update a modified entity.

    After saving it will return a new entity.
    This new instance should be used in place of the original one as certain
    properties (such as the id) could have been changed.

    Params:
        entity = the entity to save.
    Returns: A saved instance of the entity.
    */
    Entity save(Entity entity);

    /**
    Finds an entity by its primary key.
    */
    Entity find(PrimaryKeyType!Entity id);

    /**
    Returns a list of all entities in the repository.
    */
    Entity[] findAll();

    /**
    Removes an entity by its primary key.
    */
    void remove(PrimaryKeyType!Entity id);

    /**
    Removes an entity.
    */
    final void remove(Entity entity)
    {
        remove(entity.getPrimaryKey);
    }
}
