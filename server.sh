#!/bin/bash
PORT=8080

### Create the response FIFO
rm -f response
mkfifo response

function handle_request() {
    request=""
    while read line; do
      request="$line"
      break
    done

    method=$(echo "$request" | awk '{print $1}')
    path=$(echo "$request" | awk '{print $2}')

    echo "Received $method request for $path"

    if [ "$method" = "GET" ] && [[ $path =~ ^/process/[^/]+$ ]]; then

        process_name=$(echo "$path" | awk -F '/' '{print $3}')


        memory=$(ps -C "$process_name" -o rss=)
        cpu=$(ps -C "$process_name" -o %cpu=)

        response="{\"memory\": \"$memory\", \"cpu\": \"$cpu\"}"

        http_response="HTTP/1.1 200 OK\r\nContent-Length: ${#response}\r\n\r\n$response"
    else
        http_response="HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\n\r\n"
    fi

    echo -e "$http_response" > response
}


echo "Server running on port $PORT"

while true; do
  cat response | nc -lN $PORT | handle_request
done
