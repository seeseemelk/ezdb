/**
EzDb is a framework that allows one to easily interact with SQLite databases.

Note that importing `ezdb` does not import all subpackages automatically.
It only exports symbols interesting to users of the library, not ones that are
only have used internally. These symbols can be imported separately using the
right packages.
*/
module ezdb;

public
{
    import ezdb.repository;
    import ezdb.entity : primaryKey;
    import ezdb.driver.common;
}
