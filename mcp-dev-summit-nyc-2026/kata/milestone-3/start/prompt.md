I have a working Linear clone app in this directory (React frontend, Node.js backend, Postgres DB, all containerized via Docker Compose).

Deploy it to a DigitalOcean droplet:
- Provision a minimum droplet
- Create a script that can deploy a docker image from my local code's state
- Use the script to deploy

The app should be fully functional on the public internet — I should be able to create, read, update, and delete tickets from my browser.

To accomplish this:
- Use the DigitalOcean MCP to provision the droplet
- Use Chrome DevTools to navigate the deployed app and verify CRUD works
- If anything fails, check the container logs and fix it
- Don't stop until the app is live and working end-to-end

Open a PR with your script and a writeup of reference documentation on our final architecture, deployment instructions.