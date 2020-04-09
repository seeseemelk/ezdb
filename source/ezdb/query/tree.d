/**
Describes a query tree.
*/
module ezdb.query.tree;

/// The parse tree of a query.
struct Query
{
    /// The action the query should take.
    QueryAction action;

    /// The filters that should be applied to each record, similar to a `WHERE`
    /// clause in SQL.
    QueryFilter[] filters;
}

/// The action the query should take.
enum QueryAction
{
    /// Retrieve records
    select,
    /// Remove records
    remove
}

/// A filter to apply before a query, similar to a `WHERE` clause.
struct QueryFilter
{
    /// The type of filter to apply.
    QueryFilterType type;

    /// The name of the column that should be filtered.
    string column;
}

/// All possible types of filters.
enum QueryFilterType
{
    /// Equal operation.
    equal
}
