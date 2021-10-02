# Bookworm 🪱📚

A simple script for offline access of notes and Kindle highlights.

Read more about it [here][blogpost].

## Set Up

#### 1. Clone this repo.

```
git clone git@github.com:zorbash/bookworm.git
```

#### 2. Configure

```
cp .env.template .env
```

Update the `.env` file with your Kindle email, Notion access key and
notion database ID.

**Notion Import**

For the Notion import to work, you have to create an integration first,
and allow it to access the database to be updated. Read more about this
[here][notion-access]. The database has to be created beforehand with
the following fields:

<details>
  <summary>Notion Database Fields</summary>

  | Name       | Type |
  -------------|------
  | Book       | title
  | Author     | text
  | ASIN       | text
  | ID         | text
  | Location   | number
  | Highlight  | text
  | ImportedAt | date
  | Status     | select

  _The naming convention (CamelCase) follows the default Notion databases_.
</details>

### 3. Ensure Ruby (version >= 3.0) is installed

Install dependencies with:

```
bundle install
```

## Usage

Print all available commands and options with:

```
./notes --help
```

### sync_local

```
./notes sync_local
```

It asks for your Kindle password and downloads all your kindle notes in `books.json`.
You can change the location of the JSON file by setting the
`DB_FILEPATH` (can be set in the `.env` file).


**Notes**

It can also import into the `books.json` "database" file your hand-typed notes.
Such notes can be written in a `notes.yml` file (configurable via the
`NOTES_PATH` environment variable). The schema of the notes file is:

```yaml
-
  # The asin key may also hold an ISBN
  asin: 0-679-76288-4
  title: High Output Management
  author: Andy Grove
  highlights:
    -
      location: 17 # Page number
      text: >
        A genuinely effective indicator will cover the output of the work unit and not simply
        the activity involved.
```

Syncing all your Kindle highlights can take a couple of minutes. There's
an option to sync only your notes with the `--notes-only` flag.

:bulb: It is advisable to check the `books.json` file in Git.

Use `DEBUG=true` to print debugging output.

### search

```
./notes search <keyword>
```

Prints any highlights which match the given keyword.

Example:

```
./notes search work

Found 179 results for "work"

╔════════════════════════════════════════════════════════════════════╗
║  Book:   High Output Management                                    ║
║  Author: Andy Grove                                                ║
╚════════════════════════════════════════════════════════════════════╝

 A genuinely effective indicator will cover the output of the work unit
and not simply the activity involved.
```

Bookworm by default pipes to a pager like `less` when the number of
results might flood the screen. To disable this behaviour, use the
`--no-pager` flag.

### random

```
./notes random
```

Returns a random highlight.

Example:

```
╔════════════════════════════════════════════════════════════════════╗
║  Book:   The Genealogy of Morals                                   ║
║  Author: Friedrich Nietzsche                                       ║
╚════════════════════════════════════════════════════════════════════╝

 All sick and diseased people strive instinctively after a herd-organisation,
out of a desire to shake off their sense of oppressive discomfort and weakness;
the ascetic priest divines this instinct and promotes it;
```

### update_notion

Syncs the local "database" file into a Notion database.

It supports the `--since <date>` flag to only sync the database entries
which have been updated since the given date (ISO-8601 formatted). This
option is particularly useful since the Notion API is rate-limited and
for more than 1000 highlights syncing can take significant time (more
than 10 minutes).

## Is it any good?

Yes

## License

Copyright (c) 2021 Dimitris Zorbas, GPLv3 License.
See [LICENSE](https://github.com/zorbash/bookworm/blob/master/LICENSE) for further details.

[notion-access]: https://developers.notion.com/docs/getting-started#share-a-database-with-your-integration
[blogpost]:  https://zorbash.com/post/highlights-notes
