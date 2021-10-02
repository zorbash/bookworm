# frozen_string_literal: true

class NotionUpdater
  def initialize(token:, db_id:)
    @client = Notion::Client.new(token: token)
    @db_id = db_id
  end

  def import(books, since:, **)
    books_updated(books, since: since).with_progress('updating book in Notion').each do |book|
      book['highlights'].with_progress("updating highlights for book: \"#{book['title'][0..10]}..\"") do |highlight|
        next if already_imported?(highlight)

        client.create_page(
          parent: { database_id: db_id },
          properties: properties(book: book, highlight: highlight),
          children: []
        )
      end
    end
  end

  private

  attr_reader :client, :db_id

  def books_updated(books, since: Date.parse('1970-01-01'))
    books.find_all { |book| Date.parse(book['sync_date']) >= since }
  end

  def already_imported?(highlight)
    !client.database_query(id: db_id, filter: {
                             property: 'ID',
                             text: {
                               equals: highlight['id']
                             }
                           })['results'].empty?
  end

  def properties(book:, highlight:) # rubocop:disable Metrics/MethodLength
    {
      Location: {
        number: highlight['location'].to_i
      },
      ImportedAt: {
        date: {
          start: DateTime.now.iso8601
        }
      },
      ID: {
        rich_text: [
          {
            text: {
              content: highlight['id']
            }
          }
        ]
      },
      Author: {
        rich_text: [
          {
            text: {
              content: book['author']
            }
          }
        ]
      },
      ASIN: {
        rich_text: [
          {
            text: {
              content: book['asin']
            }
          }
        ]
      },
      Book: {
        title: [
          text: {
            content: book['title']
          }
        ]
      },
      Highlight: {
        rich_text: [
          {
            text: {
              content: highlight['text']
            }
          }
        ]
      }
    }
  end
end
