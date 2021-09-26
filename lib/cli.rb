# frozen_string_literal: true

class Cli
  COMMANDS = %w(
    sync_local
    update_notion
    search
    random
  )

  BANNER = <<~TXT
  Usage: notes <command> [<args>]

  COMMANDS

    sync_local
      Updates the local database by importing notes and Kindle highlights

      --notes-only  Whether to import notes only. Default: false

    update_notion
      Imports the local database to Notion

      --since  Import only database entries which have been updated since this date (ISO-8601)

    search
      Searches the local database

      --no-pager Don't use a pager.

    random
      Returns a random highlight

  GLOBAL FLAGS
  TXT

  def run
    @global_opts = Optimist::options do
      banner BANNER
      stop_on COMMANDS
    end

    case ARGV.shift
    when 'sync_local'
      sync_opts = Optimist::options do
        opt :notes_only, 'Only sync notes', default: false
      end

      sync_local(sync_opts)
    when 'update_notion'
      update_opts = Optimist::options do
        opt :since,
            'Only sync books with changes after the given date (iso8601)',
            type: Date,
            default: Date.parse('1970-01-01')
      end

      update_notion(opts: update_opts)
    when 'search'
      search_opts = Optimist::options do
        opt :no_pager, 'Whether to use a pager', default: false
      end

      search(ARGV.shift, opts: search_opts)
    when 'random'
      random
    else
      Optimist::die "Unknown subcommand, expected one of {#{COMMANDS * ', '}}"
    end
  end

  private

  attr_reader :global_opts

  def sync_local(opts)
    unless opts[:notes_only]
      puts 'Type password:'
      password = IO::console.getpass
    end

    highlights = Highlights.new(email: ENV.fetch('KINDLE_EMAIL'),
                                password: password,
                                debug: ENV['DEBUG'] == 'true')
    highlights.sync(**opts)
  end

  def update_notion(opts:)
    updater = NotionUpdater.new(token: ENV.fetch('NOTION_KEY'),
                                db_id: ENV.fetch('NOTION_DATABASE'))

    updater.import(Highlights.all, **opts)
  end

  def search(keyword, opts:)
    return if keyword.blank?

    results = Highlights.search(keyword)

    output = <<~TXT
    Found #{results.size} results for "#{keyword}"

    #{results.map { format(_1, keyword) }.join}
    TXT

    if results.size < 3 || opts[:no_pager]
      puts output

      return
    end

    IO.popen(ENV.fetch('PAGER', 'less'), mode = 'w') do |io|
      io.write output
      io.close
    end
  end

  def random
    Highlights.all.flat_map do |book|
      book['highlights'].map do |highlight|
        highlight.merge('author' => book['author'], 'book' => book['title'])
      end
    end.sample.yield_self(&method(:format)).tap(&method(:print))
  end

  def format(highlight, keyword = nil)
    <<~TEXT
    ╔════════════════════════════════════════════════════════════════════╗
    ║  Book:   #{truncate(highlight['book']).ljust(58)}║
    ║  Author: #{highlight['author'].ljust(58)}║
    ╚════════════════════════════════════════════════════════════════════╝

     #{colorize(highlight['text'], keyword).wrap 80}

    TEXT
  end

  def truncate(text, length: 55)
    return text if text.size <= length

    "#{text[0..length]}…"
  end

  def colorize(text, keyword)
    return text if keyword.nil?

    text.gsub(/#{keyword}/mi, "\e[32m#{keyword}\e[0m")
  end
end
