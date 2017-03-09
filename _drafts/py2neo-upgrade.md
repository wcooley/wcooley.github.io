---
tags: ['py2neo', 'python', 'neo4j']
category: 'python'
title: Py2neo Upgrade Notes
description: Changes between different major versions of py2eo
---
# Py2neo Upgrade Notes

## Py2neo v3

Upgrading from 1.6 or 2.

### Relationship
* `Relationship.start_node` is now method instead of property (1.6, 2)
* `Relationship.end_node` is now method instead of property (1.6, 2)
* `Relationship.type` is now method instead of property (1.6, 2)
* No longer a `rel` constructor; just use `Relationship` directly? (1.6, 2)

### Node
* `Node.labels` is now method instead of property (2)
* `Node.get_labels` method is removed (1.6, 2)
* `Node.get_properties` method is removed (1.6, 2)

### Graph
* `Graph.create` no longer returns list of created entities (1.6, 2)
* `Graph.create` no longer creates nodes from dicts or relationships from tuples.
* `Graph.run` replaces `Graph.cypher.stream` (2) and `CypherQuery.stream` (1.6);
there is no direct replacement for `execute`, but `list(<graph>.run(...))` is
sufficient.
* `Graph.uri` is no longer as readily accessible; use `py2neo.database.remote(<graph>).uri.string` instead.

## Py2neo v2

Upgrading from 1.6.

### Relationship
* `Relationship` can be used as a constructor directly without `rel`.

### Node
* `Node` can be used as a constructor directly without `node`.

### Graph

## Py2neo v1.6

Back-porting from v2 or v3.

### Node
* Abstract `Node` instances (i.e., those not bound to an entity in the actual database) cannot have labels. Labels must be added after construction using
`<Node>.add_labels`.
*

### Graph
* There is no `Graph.uri` (2); use `Graph.__uri__` instead.
