/**
Module that can parse a query.
*/
module ezdb.query.parse;

import ezdb.query.tree;

import std.uni;
import std.range;
version(unittest) import fluent.asserts;

/**
Splits camelcased words
*/
private string[] splitCamelCasedWords(string sentence)
{
    string[] words;
    string word;
    foreach (chr; sentence)
    {
        if (chr.isUpper)
        {
            words ~= word.toLower();
            word = [chr];
        }
        else
            word ~= chr;
    }
    words ~= word.toLower();
    return words;
}

@("Can split camelcased words")
unittest
{
    const words = splitCamelCasedWords("helloWorldFooBar");
    words.should.equal(["hello", "world", "foo", "bar"]);
}

/**
Parses a query action.
*/
private QueryAction parseQueryAction(string action)
{
    switch (action)
    {
    case "find":
    case "select":
        return QueryAction.select;
    case "remove":
    case "delete":
        return QueryAction.remove;
    default:
        assert(0, "Unsupported query action: " ~ action);
    }
}

/**
Parses a query filter.
*/
private QueryFilter parseQueryFilter(string column)
{
    QueryFilter filter;
    filter.column = column;
    filter.type = QueryFilterType.equal;
    return filter;
}

/**
Parses a query.
*/
Query parseQuery(string sentences)
{
    Query query;
    const words = splitCamelCasedWords(sentences);
    assert(words.length >= 3, "Query needs to contain at least 3 words");
    query.action = parseQueryAction(words[0]);

    assert(words[1] == "by", "Second word of query should be 'by'");

    foreach (word; words[1..$].chunks(2))
        query.filters ~= parseQueryFilter(word[1]);

    return query;
}

@("Can parse a simple query")
unittest
{
    const query = parseQuery("findById");
    query.action.should.equal(QueryAction.select);
    query.filters.length.should.equal(1);
    query.filters[0].type.should.equal(QueryFilterType.equal);
    query.filters[0].column.should.equal("id");
}
