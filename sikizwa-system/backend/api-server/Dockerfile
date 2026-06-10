FROM node:18-alpine
RUN addgroup -S sikizwa && adduser -S sikizwa -G sikizwa
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
RUN chown -R sikizwa:sikizwa /app
USER sikizwa
EXPOSE 4000
CMD ["node", "src/index.js"]
