# frozen_string_literal: true

class Highlights
  DB_FILEPATH    = File.expand_path(ENV.fetch('DB_FILEPATH', 'books.json'))
  NOTES_FILEPATH = File.expand_path(ENV.fetch('NOTES_FILEPATH', 'notes.yml'))

  # A class to mimic KindleHighlight::Book
  BookWrapper = Class.new(OpenStruct) { def highlights_from_amazon = highlights }

  class << self
    def all
      File.read(DB_FILEPATH).yield_self(&JSON.method(:parse))
    end

    def search(keyword)
      keyword_regex = /#{keyword}/mi

      all.each_with_object([]) do |book, acc|
        book['highlights'].each do |highlight|
          acc << highlight.merge('author' => book['author'], 'book' => book['title']) if highlight['text'] =~ keyword_regex
        end
      end
    end
  end

  def initialize(email:, password:, debug: false)
    @client = KindleHighlights::Client.new(email_address: email, password: password).tap do |client|
      client.send(:mechanize_agent).log = Logger.new($stdout) if debug
    end
  end

  def sync(notes_only: false, **)
    save(books_to_sync(notes_only: notes_only).with_progress('syncing books').map(&method(:serialize_book)))
  end

  private

  attr_reader :client

  def books_to_sync(notes_only:)
    return notes if notes_only

    notes.concat(client.books)
  end

  def notes
    JSON.parse(YAML.load_file(NOTES_FILEPATH).to_json, object_class: BookWrapper)
  rescue Errno::ENOENT
    # TODO: Print a user-friendly error
    []
  end

  def save(highlights)
    File.write(DB_FILEPATH, JSON.pretty_generate(highlights))
  end

  def serialize_book(book)
    {
      asin: book.asin,
      author: book.author,
      title: book.title,
      # TODO: Only set the sync_date only when there are changes
      sync_date: Date.today.iso8601,
      highlights: book.highlights_from_amazon.map do |h|
        {
          id: Digest::SHA2.hexdigest(h.text),
          location: h.location,
          text: h.text
        }
      end
    }
  end
end
