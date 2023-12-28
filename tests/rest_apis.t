http_base_url "http://localhost:3000"

puts http_get "/"

http_response_type "json" do
  resp = http_post "/", form: {"name" => "AAA", "value" => "Sumne"}, status: 201
  puts resp
end

resp = http_post "/data", multipart: {"name" => "AAA", "file" => "@tests/rest_apis.t"}, status: 201
puts resp

# put "/"
# del "/"
