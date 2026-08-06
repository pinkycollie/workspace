---
title: Obsidian Knowledge Metadata Standard
aliases: []
tags: []
cssclass: []
icon:
status: draft
type: note

# Identity
id:
uid:
uuid:
slug:
namespace:
vault:
workspace:
collection:
category:
domain:
topic:

# File
file:
folder:
path:
filename:
basename:
extension:
size:
checksum:
encoding:

# Dates
created:
updated:
modified:
published:
reviewed:
expires:

# Navigation
parent:
children: []
related: []
aliases: []
links: []
backlinks: []
outlinks: []
embeds: []
attachments: []

# Structure
outline:
sections: []
headings: []
toc: true

# References
references: []
citations: []
bibliography: []
footnotes: []
glossary: []

# Ownership
author:
owner:
organization:
team:
reviewer:
approver:

# Classification
priority:
importance:
confidence:
trust_level:
visibility:
audience:
language:

# Content
summary:
description:
keywords: []
abstract:

# Project
project:
product:
service:
component:
module:
repository:
branch:
version:
release:

# Relationships
depends_on: []
required_by: []
uses: []
used_by: []
extends: []
implements: []
publishes: []
subscribes: []

# Workflow
state:
stage:
workflow:
pipeline:
agent:
automation:
tasks: []
events: []

# AI
ai:
model:
provider:
prompt:
context:
memory:
tools: []
rag: false
embeddings: false
vector_store:

# Registry
entity:
entity_type:
properties: {}
methods: []
events: []
policies: []
capabilities: []
constraints: []

# Search
searchable: true
indexed: true
favorite: false
pinned: false
archived: false

---

# {{title}}

## Summary

## Outline

- Overview
- Details
- References
- Related Notes

## Related

```dataview
LIST
FROM ""
WHERE contains(file.outlinks, this.file.link)
SORT file.name
```

## Backlinks

```dataview
LIST
FROM ""
WHERE contains(file.outlinks, this.file.link)
```

## Outlinks

```dataview
LIST file.outlinks
FROM this.file.path
```

## Footnotes

[^1]:

## References

- 

## Attachments

- 

## Tasks

- [ ] Review
- [ ] Validate
- [ ] Link related notes
- [ ] Add citations

## Metadata

| Property | Value |
|----------|-------|
| Vault | |
| Project | |
| Status | |
| Owner | |
| Updated | |
| Version | |

---