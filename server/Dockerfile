FROM node:21-alpine

# Install build dependencies for bcrypt and other native modules
RUN apk add --no-cache python3 make g++

WORKDIR /usr/src/app

# Install dependencies first for better caching
COPY package*.json ./
RUN npm install

# Copy the rest of the server code
COPY . .

# Expose the port the app runs on
EXPOSE 5000

# Use the dev script which uses nodemon for hot-reloading
CMD ["npm", "run", "dev"]
