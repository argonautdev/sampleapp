FROM node:alpine

ENTRYPOINT [ "/bin/sh", "-c", "sleep 10800" ]

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