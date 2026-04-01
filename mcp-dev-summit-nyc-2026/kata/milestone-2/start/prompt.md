I have a comprehensive design specification here at
- /Users/Manuel.Naujoks/Projects/pulsemcp_content/mcp-dev-summit-nyc-2026/kata/milestone-1/start/linear-clone-figma-spec.md


And an empty GitHub repo at https://github.com/halllo/linear-clone.git.

Build a working Linear clone app based on the Figma design. The app should have:
- A React frontend
- A TypeScript backend
- A Postgres database
- Full CRUD for tickets (create, read, update, delete)

You can leave off bells and whistles visible in the mocks for now - just focus on core functionality.

To accomplish this:
- Read the Figma design to understand every page and component
- Initialize a git repo in this working directory, start a branch to work on the initial implementation here
- Implement all component pieces of this app. Make it containerizable -- there should be a simple docker-compose file that puts together all the pieces in a de facto dev server that runs on configurable ports
- Start the dev server and use Chrome DevTools to screenshot your running app
- Compare your screenshots against the Figma design
- Iterate until the UI is a close match and all CRUD operations work without issues
- Open a PR with the working implementation and a detailed explanation of all the flows you tested with Chrome DevTools

Make you test for visual parity at least 5 times:
- Take screenshots and grab DOM elements to understand what you have implemented vs. the Figma mocks
- Take a pass at implementing it in code using CSS best practices and responsive web design
- Then, take screenshots of what you have in Figma vs. what you have running in the browser
- Compare the screenshots
- Have a subagent critique how they are still different
- Make yourself a TODO list of fixes and iterate to get closer
- Do this at least 5 times; I want to be as close to pixel perfect (but not hacky -- e.g. no hardcoded pixel layouts) as possible

And make sure you test core functionality end to end to ensure the frontend, backend, and database work nicely together.

Include thorough documentation on system architecture and how to run the dev container, including instructions for how I would run multiple dev containers at once without trampling each other (e.g. set different ports exposed by each one).