require "http/server" # must be double-quotes
require "json"
#require "mysql"
require "pg" # Heroku
require "crypto/md5"

#↪ curl -XPOST localhost:8080 -d '{"foo": "bar", "bar": "baz", "baz": "foo-bar"}'
#hello, World from Jonathan who is 27 @ 2015-08-23 20:25:53 -0800: after receiving: params: {}body: {"foo" => "bar", "bar" => "baz", "baz" => "foo-bar"}
#↪ curl -XGET 'localhost:8080/?foo=bar&bar=baz&baz=foo-bar'
#hello, World from Jonathan who is 27 @ 2015-08-23 20:25:55 -0800: after receiving: params: {"foo" => "bar", "bar" => "baz", "baz" => "foo-bar"}body: {}

class DbHandle
  getter connection
  def initialize(host, user, password, database, port, socket, flags = 0)
    # MySQL.connect(host, user, password, database, port, socket, flags = 0)
    #@connection = MySQL.connect(@host, @user, @password, @database, @port, @socket)
    # postgres://username:password@localhost/myrailsdb
    # DB = PG.connect("postgres://...")
    @connection = PG.connect("postgres://#{user}:#{password}@#{host}:#{port}/#{database}")
  end

  def rows_for(type_hash={Int32, String, String}, statement="select id, key, body from raw_bodies")
    result = @connection.exec(type_hash, statement)
    return result.rows    # => [{1, "will@example.com"}], …]
  end

  def ddml(statement)
    @connection.exec(statement)
  end

  def close
    #@connection.close
  end
end

class Person
  getter name, age

  def initialize(@name, @age = 0)
  end

  def increase_age_by(increase_amount=1)
    @age += increase_amount
  end

  def age=(@age)
  end
end

#class Document
#  json_mapping({
#    body: String,
#  })
#end

class ParsedRequest
  getter raw_params, raw_body

  def initialize(request)
    @raw_params = ""
    request_path = request.path || ""
    @raw_params = request_path.split('?').last if request_path.includes?('?')
    #pp @raw_params

    @raw_body = request.body || ({} of String => String).to_json
    #pp @raw_body
    @params = {} of String => String
  end

  def body
    body = {} of String => String
    parsed_body = JSON.parse(@raw_body).not_nil! as Hash(String, JSON::Type)
    if parsed_body
      #puts "parsed_body: #{parsed_body.inspect}"
      parsed_body.each do |key, value|
        if key.is_a?(String) && value.is_a?(String)
          #puts "k/v: #{key.inspect} => #{value.inspect}"
          body[key] = value
        end
      end
    end
    return body
    #Document.from_json(@raw_body).body
  end

  def params
    if {} of String => String == @params
      #puts "unsplit raw_params: #{@raw_params.inspect}"
      @raw_params.split('&').each do |key_and_value|
        #puts "splitting key_and_value: #{key_and_value.inspect}"
        key, value = key_and_value.split('=')
        #puts "key: #{key.inspect}, value: #{value.inspect}"
        if key && value
          @params[key] = value
        end
      end
    end
    return @params
  end
end


person = Person.new("Jonathan")
person.increase_age_by(27)


# create role pg_user with createdb login password 'secret_pwd';
# create database crystal_db;
DB_HOST = ENV.has_key?("DB_HOST") ? ENV["DB_HOST"] : "127.0.0.1"
DB_USER = ENV.has_key?("DB_USER") ?  ENV["DB_USER"] : "pg_user"
DB_PWD = ENV.has_key?("DB_PWD") ? ENV["DB_PWD"] : "secret_pwd"
DB = ENV.has_key?("DB") ? ENV["DB"] : "crystal_db"

#DB_HANDLE = DbHandle.new(DB_HOST, DB_USER, DB_PWD, DB, 3306_u16, nil)
DB_HANDLE = DbHandle.new(DB_HOST, DB_USER, DB_PWD, DB, 5432_u16, nil)
pp DB_HANDLE.ddml("create table IF NOT EXISTS raw_bodies ( id serial, key varchar(200), body json )")

HTTP_PORT = ENV.has_key?("HTTP_PORT") ? ENV["HTTP_PORT"].to_i : 8080

server = HTTP::Server.new(HTTP_PORT) do |request|
  #HTTP::Response.ok "text/plain", "hello, World from #{person.name} who is #{person.age} @ #{Time.now}"
  #@path="/?foo=bar&bar=baz&baz=foo-bar"
  #@body=nil
  #@path="/"
  #@body="{ \"foo\": \"bar\", \"bar\" => \"baz\", \"baz\" => \"foo-bar\"}"
  pr = ParsedRequest.new(request)
  response_message = "hello, World from #{person.name} who is #{person.age} @ #{Time.now}: after receiving: "
  #puts "1) r_m..."
  response_message += "params: #{pr.params.inspect}"
  #puts "2) pr.params..."
  #raise "fail" unless false

  # key should be checksum of body or something
  key = Crypto::MD5.hex_digest(pr.body.to_s)

  response_message += "key: #{key.inspect}, body: #{pr.body.inspect}"
  pp DB_HANDLE.connection.exec("insert into raw_bodies (key, body) values ('#{key}', '#{pr.body.to_json}')")
  #puts "3) pr.body..."
  # confirm w/: psql crystal_db -c "select * from raw_bodies"

  HTTP::Response.ok "text/plain", response_message
end

puts "Listening on http://0.0.0.0.:#{HTTP_PORT}"
server.listen
DB_HANDLE.close
