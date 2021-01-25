FROM node:alpine

# A directory within the virtualized Docker environment
# Becomes more relevant when using Docker Compose later
WORKDIR /
 
# Copies package.json and package-lock.json to Docker environment
COPY package*.json ./
 
# Installs all node packages
RUN npm install
 
# Copies everything over to Docker environment
COPY . .
 
# Uses port which is used by the actual application
EXPOSE 3000

ENTRYPOINT [ "npm", "start" ]

# # Finally runs the application
# ENTRYPOINT [ "/bin/sh", "./entrypoint.sh" ]
# # ENTRYPOINT ["/bin/sh", "-ec", "npm start; while :; do echo '.'; sleep 5 ; done"]

#######
# FROM nginx

# # Copies everything over to Docker environment
# COPY . .
 
# # Uses port which is used by the actual application
# EXPOSE 80


# # Finally runs the application
# ENTRYPOINT [ "/bin/sh", "./entrypoint.sh" ]