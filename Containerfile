FROM ghcr.io/gohugoio/hugo:v0.155.1 AS hugo-builder

# Set the working directory inside the container
WORKDIR /app

# Copy the contents of your Hugo site (including the Hermit theme) into the container
COPY --chown=1000:1000 . .

# Build the Hugo site
#RUN apk --no-cache add git
RUN hugo --baseURL "https://cloudwithdan.com/posts/"

# Use a lightweight HTTP server to serve the site
FROM docker.io/nginxinc/nginx-unprivileged:stable-alpine

# Copy the built site from the builder stage to the nginx web root
COPY --from=hugo-builder /app/public /usr/share/nginx/html

# Expose port 8080 for the web server
#EXPOSE 8080

# Copy custom nginx configuration
COPY nginx/nginx.conf /etc/nginx/conf.d/default.conf

# Command to start the web server
CMD ["nginx", "-g", "daemon off;"]
