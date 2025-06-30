# Stage 1: Build the React application
FROM node:23 AS build

# Set the working directory
WORKDIR /app

# Copy package.json and pnpm-lock.yaml
COPY package.json pnpm-lock.yaml ./

# Install pnpm
RUN npm install -g pnpm

# Install dependencies
RUN pnpm install

# Copy the rest of the application source code
COPY . .

ARG API_KEY
RUN echo "API_KEY is $API_KEY"
ENV VITE_API_KEY=$API_KEY

# Build the application
RUN pnpm run build

# Stage 2: Serve the application with Nginx
FROM nginx:alpine

# Set ownership and permissions for Nginx directories
RUN chown -R 1001:0 /var/cache/nginx \
    && chmod -R g+w /var/cache/nginx \
    && chown -R 1001:0 /var/run \
    && chmod -R g+w /var/run \
    && chown -R 1001:0 /usr/share/nginx/html \
    && chmod -R g+w /usr/share/nginx/html

# Copy the build output from the build stage
COPY --from=build /app/dist /usr/share/nginx/html

# Copy the Nginx configuration file
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the .htpasswd file for basic authentication
COPY .htpasswd /etc/nginx/.htpasswd

# Expose port 80
EXPOSE 8080

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
