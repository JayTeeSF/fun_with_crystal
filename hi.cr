require "http/server" # must be double-quotes

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

# person = Person.new("Jonathan", 28)
person = Person.new("Jonathan")
person.increase_age_by(27)

port = 8080
#response = {a: '1', b: '2'}
server = HTTP::Server.new(port) do |request|
  #HTTP::Response.ok "text/plain", "hello, World @ #{Time.now} for w/ #{response.inspect}; a => #{response[:a]}"
  HTTP::Response.ok "text/plain", "hello, World from #{person.name} who is #{person.age} @ #{Time.now}"
end

puts "Listening on http://0.0.0.0.:#{port}"
server.listen
