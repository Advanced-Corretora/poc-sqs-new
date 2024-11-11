###################
# PRE-BUILD
###################
FROM node:18-alpine As pre-build
WORKDIR /usr/src/app
COPY --chown=node:node package*.json ./
RUN npm install
RUN ls

###################
# BUILD FOR LOCAL DEVELOPMENT
###################
FROM node:18-alpine As development
WORKDIR /usr/src/app
COPY --chown=node:node --from=pre-build /usr/src/app/package*.json ./
RUN npm ci
COPY --chown=node:node . .
USER node

###################
# BUILD FOR PRODUCTION
###################
FROM node:18-alpine As build
WORKDIR /usr/src/app
COPY --chown=node:node --from=development /usr/src/app/package*.json ./
# In order to run `npm run build` we need access to the Nest CLI which is a dev dependency. In the previous development stage we ran `npm ci` which installed all dependencies, so we can copy over the node_modules directory from the development image
COPY --chown=node:node --from=development /usr/src/app/node_modules ./node_modules
COPY --chown=node:node . .
# Run the build command which creates the production bundle
RUN npm run build
ENV NODE_ENV production
# Running `npm ci` removes the existing node_modules directory and passing in --only=production ensures that only the production dependencies are installed. This ensures that the node_modules directory is as optimized as possible
RUN npm ci --only=production && npm cache clean --force
USER node

###################
# PRODUCTION
###################
FROM node:18-alpine As production

COPY --chown=node:node --from=build /usr/src/app/node_modules ./node_modules
COPY --chown=node:node --from=build /usr/src/app/dist ./dist
COPY --chown=node:node --from=build /usr/src/app/.env ./

CMD [ "node", "dist/main.js" ]
