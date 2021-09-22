# frozen_string_literal: true

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'mechanize'
  gem 'kindle-highlights', '~> 2.0.1'
  gem 'dotenv'
  gem 'pry', require: false
end

require 'json'
require 'io/console'
require 'kindle_highlights'

Dotenv.load!

puts 'Type password:'
password = $stdin.noecho(&:gets).chomp

kindle.send(:mechanize_agent).log = Logger.new($stdout) if ENV['DEBUG'] == 'true'

kindle = KindleHighlights::Client.new(
  email_address: ENV['KINDLE_EMAIL'],
  password: password
)

books = kindle.books.map do
  {
    asin: _1.asin,
    author: _1.author,
    title: _1.title,
    highlights: _1.highlights_from_amazon.map { |h| { location: h.location, text: h.text } }
  }
end

File.write('kindle_books.json', JSON.dump(books))
